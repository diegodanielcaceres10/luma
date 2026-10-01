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

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const apiKey = Deno.env.get("GEMINI_API_KEY");
    if (!apiKey) {
      return jsonResponse({ error: "Falta configurar GEMINI_API_KEY." }, 500);
    }

    const { image_base64, mime_type } = await req.json();
    if (!image_base64 || typeof image_base64 !== "string") {
      return jsonResponse({ error: "Falta image_base64." }, 400);
    }
    if (image_base64.length > MAX_BASE64_LENGTH) {
      return jsonResponse({ error: "La imagen es demasiado grande." }, 413);
    }
    const mimeType = typeof mime_type === "string" ? mime_type : "image/jpeg";
    if (!ALLOWED_MIME_TYPES.has(mimeType)) {
      return jsonResponse({ error: "Solo se aceptan imágenes JPG, PNG o WEBP." }, 415);
    }

    const today = new Date().toISOString().slice(0, 10);

    const geminiRes = await fetch(`${GEMINI_URL}?key=${apiKey}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
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
      return jsonResponse({ error: `Gemini respondió ${geminiRes.status}: ${errText}` }, 502);
    }

    const geminiData = await geminiRes.json();
    const rawText = geminiData?.candidates?.[0]?.content?.parts?.[0]?.text ?? null;
    if (!rawText) {
      return jsonResponse({ error: "Gemini no devolvió contenido." }, 502);
    }

    let parsed: unknown;
    try {
      parsed = JSON.parse(rawText);
    } catch {
      return jsonResponse({ error: "No se pudo interpretar la respuesta del modelo." }, 502);
    }

    // image_base64 leaves this scope without being written anywhere.
    return jsonResponse({ movements: sanitizeMovements(parsed) }, 200);
  } catch (err) {
    return jsonResponse({ error: `Error inesperado: ${(err as Error).message}` }, 500);
  }
});
