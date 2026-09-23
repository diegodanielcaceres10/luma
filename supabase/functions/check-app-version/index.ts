// Recibe la versión instalada de la app (X.Y.Z, el build "+N" se ignora,
// igual que en app/scripts/check_version.sh) y la compara contra dos
// valores configurados como secrets de esta función, para decidir si la
// app puede seguir usándose tal cual, debería actualizarse, o tiene que
// bloquearse.
//
// Request (POST):
//   { "version": "1.0.1" }
//
// Response (200):
//   {
//     "status": "updated" | "outdated_but_usable" | "blocked",
//     "installed_version": "1.0.1",
//     "current_version": "1.1.0",
//     "min_version": "1.0.0",
//     "message": "..."
//   }
//
// Reglas (installed = versión recibida):
//   1. installed >= current_version        -> "updated"             (Actualizado)
//   2. min_version <= installed < current  -> "outdated_but_usable" (Usar pero actualizar)
//   3. installed < min_version             -> "blocked"             (No usar y actualizar)
//
// Variables de entorno necesarias (configurar con `supabase secrets set`,
// nunca committear valores):
//   CURRENT_APP_VERSION → última versión publicada (ej. en Firebase App
//                          Distribution), ej. "1.1.0"
//   MIN_APP_VERSION     → versión mínima con la que todavía se puede usar
//                          la app, ej. "1.0.0"
//
// Deploy:
//   supabase functions deploy check-app-version
//   supabase secrets set CURRENT_APP_VERSION=1.1.0 MIN_APP_VERSION=1.0.0
//
// Para publicar una nueva versión: actualizar CURRENT_APP_VERSION (y,
// si corresponde, MIN_APP_VERSION) con `supabase secrets set` — no hace
// falta re-deployar la función.

const CORS_HEADERS: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

type Status = "updated" | "outdated_but_usable" | "blocked";

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...CORS_HEADERS, "Content-Type": "application/json" },
  });
}

// Compara dos versiones "X.Y.Z" (ignora todo lo que venga después de un
// "+"). Devuelve -1, 0 o 1, como Array.prototype.sort.
function compareVersions(a: string, b: string): number {
  const partsOf = (v: string) =>
    v
      .split("+")[0]
      .split(".")
      .map((p) => parseInt(p, 10) || 0);

  const aParts = partsOf(a);
  const bParts = partsOf(b);

  for (let i = 0; i < 3; i++) {
    const diff = (aParts[i] ?? 0) - (bParts[i] ?? 0);
    if (diff !== 0) return diff > 0 ? 1 : -1;
  }
  return 0;
}

function isValidVersion(v: unknown): v is string {
  return typeof v === "string" && /^\d+\.\d+\.\d+(\+\d+)?$/.test(v);
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  try {
    const currentVersion = Deno.env.get("CURRENT_APP_VERSION");
    const minVersion = Deno.env.get("MIN_APP_VERSION");
    if (!currentVersion || !minVersion) {
      return jsonResponse({ error: "Falta configurar CURRENT_APP_VERSION y/o MIN_APP_VERSION." }, 500);
    }

    const { version } = await req.json();
    if (!isValidVersion(version)) {
      return jsonResponse({ error: "Falta 'version' o no tiene formato X.Y.Z (ej. '1.0.1')." }, 400);
    }

    let status: Status;
    let message: string;

    if (compareVersions(version, currentVersion) >= 0) {
      status = "updated";
      message = "La app está en su última versión.";
    } else if (compareVersions(version, minVersion) >= 0) {
      status = "outdated_but_usable";
      message = "Hay una versión nueva disponible. Se recomienda actualizar.";
    } else {
      status = "blocked";
      message = "Esta versión ya no es compatible. Es necesario actualizar para continuar.";
    }

    return jsonResponse(
      {
        status,
        installed_version: version,
        current_version: currentVersion,
        min_version: minVersion,
        message,
      },
      200,
    );
  } catch (err) {
    return jsonResponse({ error: `Error inesperado: ${(err as Error).message}` }, 500);
  }
});
