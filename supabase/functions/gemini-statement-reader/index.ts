// Recibe una captura de las líneas de un extracto bancario (imagen en
// base64) y le pide a la Gemini API que devuelva los movimientos ya
// estructurados, para precargarlos en la lista de movimientos pendientes
// de las pantallas de justificación de saldo.
//
// Privacidad: igual que gemini-image-reader, la imagen viaja solo en
// memoria. No se sube a Storage ni se guarda en ninguna tabla. Solo se
// aceptan imágenes (no PDFs completos) para que el usuario recorte las
// líneas de movimientos y deje afuera datos personales.
//
// Variables de entorno (configurar con `supabase secrets set`):
//   GEMINI_API_KEY → API key de https://aistudio.google.com/apikey
//
// Deploy:
//   supabase functions deploy gemini-statement-reader

const GEMINI_MODEL = "gemini-3.6-flash";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

// Gemini limits the whole inline request to ~20 MB; stay well below it.
const MAX_BASE64_LENGTH = 8 * 1024 * 1024;
const MAX_MOVEMENTS = 100;
const ALLOWED_MIME_TYPES = new Set(["image/jpeg", "image/png", "image/webp"]);

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function buildPrompt(today: string): string {
  return `Sos un asistente que lee capturas de extractos bancarios y
devuelve ÚNICAMENTE un JSON (sin texto adicional, sin markdown, sin
\`\`\`) con esta forma exacta:

{
  "movements": [
    {
      "type": "income" | "expense",
      "amount": number,
      "date": "YYYY-MM-DD" | null,
      "description": string | null
    }
  ]
}

Reglas:
- Una entrada por cada línea de movimiento visible. No inventes líneas.
- "type": "expense" para débitos, pagos, compras y retiros;
  "income" para créditos, cobros y depósitos.
- "amount": monto del movimiento como número POSITIVO, con punto
  decimal y sin símbolo de moneda. Si no se lee con confianza, omití
  la línea.
- "date": fecha de la operación en formato ISO. Hoy es ${today}: si la
  línea no trae año, usá el año más reciente que no quede en el futuro.
  Si no se puede leer, null.
- "description": comercio o concepto, corto. Nunca incluyas datos
  sensibles: nombres de titulares, números de cuenta o de tarjeta,
  documentos de identidad ni otros identificadores personales.
  Si no se lee, null.
- Ignorá saldos, totales, encabezados y cualquier línea que no sea un
  movimiento.

Si la imagen no contiene movimientos, devolvé {"movements": []}.`;
}

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

type Movement = {
  type: "income" | "expense";
  amount: number;
  date: string | null;
  description: string | null;
};

// Keeps only well-formed movements: the model output is untrusted input.
function sanitizeMovements(parsed: unknown): Movement[] {
  const raw = (parsed as { movements?: unknown })?.movements;
  if (!Array.isArray(raw)) return [];

  const result: Movement[] = [];
  for (const item of raw) {
    if (result.length >= MAX_MOVEMENTS) break;
    if (typeof item !== "object" || item === null) continue;
    const { type, amount, date, description } = item as Record<string, unknown>;

    if (type !== "income" && type !== "expense") continue;
    if (typeof amount !== "number" || !Number.isFinite(amount) || amount <= 0) continue;

    const isoDate =
      typeof date === "string" && /^\d{4}-\d{2}-\d{2}$/.test(date) ? date : null;
    const text = typeof description === "string" ? description.trim() : "";

    result.push({
      type,
      amount: Math.round(amount * 100) / 100,
      date: isoDate,
      description: text.length > 0 ? text.slice(0, 120) : null,
    });
  }
  return result;
}

const FUNCTION_NAME = "gemini-statement-reader";
const MAX_LOGGED_DETAIL = 500;

// Removes the API key from text that is about to be logged, in case an
// upstream error echoes the request URL or headers.
function redact(text: string, apiKey?: string): string {
  let out = text.replace(/([?&]key=)[^&\s"')]+/gi, "$1[redacted]");
  if (apiKey) out = out.split(apiKey).join("[redacted]");
  return out;
}

// One JSON line per failure, readable in the Edge Functions logs. It only
// carries metadata: never the image, the API key or the model output.
function logScanError(stage: string, details: Record<string, unknown>): void {
  console.error(
    JSON.stringify({ event: "scan_error", function: FUNCTION_NAME, stage, ...details }),
  );
}

// Why Gemini returned nothing usable. The model output itself is left out
// because it may contain data read from the image.
function describeGeminiResponse(
  data: unknown,
  rawText?: string | null,
): Record<string, unknown> {
  const d = data as {
    promptFeedback?: { blockReason?: string };
    candidates?: Array<{ finishReason?: string }>;
  } | null;
  return {
    block_reason: d?.promptFeedback?.blockReason ?? null,
    finish_reason: d?.candidates?.[0]?.finishReason ?? null,
    output_chars: rawText ? rawText.length : 0,
  };
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  const startedAt = Date.now();
  const context: Record<string, unknown> = {};
  let apiKey: string | undefined;

  // Logs the failure with what is known about the request so far. The client
  // only gets `error`; the detail stays in the logs.
  const fail = (
    stage: string,
    status: number,
    error: string,
    details: Record<string, unknown> = {},
  ): Response => {
    logScanError(stage, {
      status,
      ...context,
      ...details,
      duration_ms: Date.now() - startedAt,
    });
    return jsonResponse({ error }, status);
  };

  try {
    apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return fail("config_missing", 500, "Falta configurar GEMINI_API_KEY.");
    }

    const { image_base64, mime_type } = await req.json();
    if (!image_base64 || typeof image_base64 !== "string") {
      return fail("missing_image", 400, "Falta image_base64.");
    }
    const mimeType = typeof mime_type === "string" ? mime_type : "image/jpeg";
    context.image_bytes = Math.floor((image_base64.length * 3) / 4);
    context.mime_type = mimeType.slice(0, 50);

    if (image_base64.length > MAX_BASE64_LENGTH) {
      return fail("image_too_large", 413, "La imagen es demasiado grande.");
    }
    if (!ALLOWED_MIME_TYPES.has(mimeType)) {
      return fail("unsupported_mime", 415, "Solo se aceptan imágenes JPG, PNG o WEBP.");
    }

    const today = new Date().toISOString().slice(0, 10);

    const geminiRes = await fetch(GEMINI_URL, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        // Sent as a header so it never shows up in a URL (and in any error
        // message that repeats it).
        "x-goog-api-key": apiKey,
      },
      body: JSON.stringify({
        contents: [
          {
            parts: [
              { text: buildPrompt(today) },
              { inlineData: { mimeType, data: image_base64 } },
            ],
          },
        ],
        generationConfig: {
          thinkingConfig: { thinkingLevel: "minimal" },
          responseMimeType: "application/json",
        },
      }),
    });

    if (!geminiRes.ok) {
      const errText = await geminiRes.text();
      return fail("gemini_http_error", 502, `Gemini respondió ${geminiRes.status}.`, {
        gemini_status: geminiRes.status,
        gemini_body: redact(errText.slice(0, MAX_LOGGED_DETAIL), apiKey),
      });
    }

    const geminiData = await geminiRes.json();
    const rawText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? null;
    if (!rawText) {
      return fail(
        "gemini_empty",
        502,
        "Gemini no devolvió contenido.",
        describeGeminiResponse(geminiData),
      );
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(rawText);
    } catch {
      return fail(
        "gemini_parse_error",
        502,
        "No se pudo interpretar la respuesta del modelo.",
        describeGeminiResponse(geminiData, rawText),
      );
    }

    // image_base64 leaves this scope without being written anywhere.
    return jsonResponse({ movements: sanitizeMovements(parsed) }, 200);
  } catch (err) {
    const e = err as Error;
    return fail("unexpected", 500, "Error inesperado.", {
      error_name: e?.name ?? null,
      error_message: redact(String(e?.message ?? err).slice(0, MAX_LOGGED_DETAIL), apiKey),
    });
  }
});
