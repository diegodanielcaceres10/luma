// POC: recibe la foto de un ticket/factura en base64 y le pide a la
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
facturas de Argentina y devuelve ÚNICAMENTE un JSON (sin texto
adicional, sin markdown, sin \`\`\`) con esta forma exacta:

{
  "type": "income" | "expense",
  "amount": number | null,
  "date": "YYYY-MM-DD" | null,
  "description": string | null,
  "category": string | null
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
- "category": una palabra que describa el rubro (ej: "Supermercado",
  "Restaurante", "Transporte", "Servicios", "Salud", "Ropa"). Si no
  hay forma de inferirlo, null.

Si la imagen no parece un ticket/factura, devolvé todos los campos en
null salvo "type", que va como "expense".`;

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
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

    const geminiRes = await fetch(`${GEMINI_URL}?key=${apiKey}`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
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

    // image_base64 sale de este scope sin haberse escrito a ningún lado:
    // no hay llamada a Storage ni insert a ninguna tabla en esta función.
    return jsonResponse(parsed, 200);
  } catch (err) {
    return jsonResponse({ error: `Error inesperado: ${(err as Error).message}` }, 500);
  }
});
