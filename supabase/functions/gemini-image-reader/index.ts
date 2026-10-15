// FEAT: recibe la foto de un ticket/factura en base64 y le pide a la
// Gemini API (tier gratuito) que devuelva los datos ya estructurados,
// para precompletar el formulario de "Añadir ingreso/gasto" en la app.
//
// Privacidad: la imagen viaja en memoria nada más. Esta función no la
// sube a Supabase Storage ni la guarda en ninguna tabla — se la reenvía
// a Gemini, se lee la respuesta, y se descarta junto con el resto del
// request al terminar. El cliente (Flutter) tampoco la persiste.
//
// Variables de entorno necesarias (configurar con `supabase secrets set`,
// nunca committear la key):
//   GEMINI_API_KEY → API key gratuita de https://aistudio.google.com/apikey
//
// Deploy:
//   supabase functions deploy gemini-image-reader
//   supabase secrets set GEMINI_API_KEY=tu_api_key

const GEMINI_MODEL = "gemini-3.6-flash";
const GEMINI_URL = `https://generativelanguage.googleapis.com/v1beta/models/${GEMINI_MODEL}:generateContent`;

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const PROMPT = `Sos un asistente que lee fotos de tickets, recibos o
facturas y devuelve ÚNICAMENTE un JSON (sin texto
adicional, sin markdown, sin \`\`\`) con esta forma exacta:

{
  "type": "income" | "expense",
  "amount": number | null,
  "date": "YYYY-MM-DD" | null,
  "description": string | null
}

Reglas:
- "type": "expense" si es un ticket de compra/consumo (lo más común);
  "income" solo si es claramente un comprobante de cobro/ingreso.
- "amount": el monto TOTAL final pagado, como número (sin símbolo de
  moneda, con punto decimal). Si no se puede leer con confianza, null.
- "date": la fecha del ticket en formato ISO (YYYY-MM-DD). Si no
  aparece o no se puede leer, null.
- "description": nombre del comercio/emisor, corto. Si no se lee,
  null.

Si la imagen no parece un ticket/factura, devolvé todos los campos en
null salvo "type", que va como "expense".`;

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

const FUNCTION_NAME = "gemini-image-reader";
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
    context.image_bytes = Math.floor((image_base64.length * 3) / 4);
    context.mime_type =
      typeof mime_type === "string" ? mime_type.slice(0, 50) : "image/jpeg";

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
              { text: PROMPT },
              {
                inlineData: {
                  mimeType: mime_type || "image/jpeg",
                  data: image_base64,
                },
              },
            ],
          },
        ],
        generationConfig: {
          // La familia Gemini 3 ignora "temperature": el control de
          // determinismo pasa por responseMimeType (salida JSON forzada) y
          // por bajar el "thinking" para esta tarea simple de extracción.
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

    // image_base64 sale de este scope sin haberse escrito a ningún lado:
    // no hay llamada a Storage ni insert a ninguna tabla en esta función.
    return jsonResponse(parsed, 200);
  } catch (err) {
    const e = err as Error;
    return fail("unexpected", 500, "Error inesperado.", {
      error_name: e?.name ?? null,
      error_message: redact(String(e?.message ?? err).slice(0, MAX_LOGGED_DETAIL), apiKey),
    });
  }
});
