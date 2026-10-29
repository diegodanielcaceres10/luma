// Envía las notificaciones push diarias (facturas que vencen hoy, facturas
// sin cargar y cuentas sin actualizar) a los dispositivos registrados en
// `device_tokens`, usando FCM HTTP v1.
//
// La invoca un job de pg_cron cada hora. La función calcula la hora local en
// NOTIFY_TIMEZONE y solo envía cuando coincide con NOTIFY_HOUR, así el envío
// se mantiene a la misma hora local durante los cambios de horario.
//
// Request (POST), header `x-cron-secret` obligatorio. Cuerpo opcional:
//   { "force": true }    -> envía aunque no sea NOTIFY_HOUR
//   { "dry_run": true }  -> lista lo que se enviaría, sin llamar a FCM
//
// Response (200):
//   { "skipped": "not_notify_hour", "local_date": "...", "local_hour": 8 }
//   { "ok": true, "local_date", "local_hour", "candidates", "sent", "failed",
//     "removed_tokens" }
//   { "ok": true, "dry_run": true, "local_date", "local_hour",
//     "notifications": [{ "kind", "title", "body", "devices" }] }
// Errores: 401 (secret incorrecto), 500 (configuración, base o OAuth).
//
// Variables de entorno (configurar con `supabase secrets set`, nunca
// committear valores):
//   FCM_SERVICE_ACCOUNT → JSON completo de la cuenta de servicio de Firebase
//   CRON_SECRET         → secreto compartido con el job de pg_cron
//   NOTIFY_TIMEZONE     → zona horaria IANA (por defecto "Europe/Madrid")
//   NOTIFY_HOUR         → hora local de envío, 0-23 (por defecto 9)
// SUPABASE_URL y SUPABASE_SERVICE_ROLE_KEY las inyecta Supabase.
//
// Deploy (sin verificación de JWT: la autenticación es x-cron-secret):
//   supabase secrets set FCM_SERVICE_ACCOUNT="$(cat service-account.json)" \
//     CRON_SECRET=<secreto> NOTIFY_TIMEZONE=Europe/Madrid NOTIFY_HOUR=9
//   supabase functions deploy send-daily-notifications --no-verify-jwt
//
// Prueba manual:
//   curl -X POST https://<PROJECT_REF>.supabase.co/functions/v1/send-daily-notifications \
//     -H "x-cron-secret: <secreto>" -d '{"dry_run": true, "force": true}'
//   curl -X POST ... -H "x-cron-secret: <secreto>" -d '{"force": true}'
//
// Programación (SQL Editor; requiere las extensiones pg_cron y pg_net):
//   select vault.create_secret('<CRON_SECRET>', 'cron_secret');
//   select cron.schedule(
//     'send-daily-notifications',
//     '0 * * * *',
//     $$ select net.http_post(
//       url := 'https://<PROJECT_REF>.supabase.co/functions/v1/send-daily-notifications',
//       headers := jsonb_build_object(
//         'Content-Type', 'application/json',
//         'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'cron_secret')
//       ),
//       body := '{}'::jsonb,
//       timeout_milliseconds := 60000
//     ); $$
//   );

import {
  buildFcmMessage,
  chunk,
  type DueNotification,
  isDeadToken,
  localDateTime,
  parseNotifyHour,
  type ServiceAccount,
  shouldRun,
  signServiceAccountJwt,
  timingSafeEqual,
} from "./lib.ts";

const SEND_CONCURRENCY = 10;
const DELETE_BATCH_SIZE = 20;
const PROBABLE_ROW_LIMIT = 1000;

class ConfigError extends Error {}

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function readServiceAccount(raw: string | undefined): ServiceAccount {
  if (!raw) throw new ConfigError("FCM_SERVICE_ACCOUNT is not set");
  let parsed: Partial<ServiceAccount>;
  try {
    parsed = JSON.parse(raw);
  } catch {
    throw new ConfigError("FCM_SERVICE_ACCOUNT is not valid JSON");
  }
  const { client_email, private_key, token_uri, project_id } = parsed;
  if (!client_email || !private_key || !token_uri || !project_id) {
    throw new ConfigError("FCM_SERVICE_ACCOUNT is missing required fields");
  }
  return { client_email, private_key, token_uri, project_id };
}

async function readOptions(
  req: Request,
): Promise<{ force: boolean; dryRun: boolean }> {
  try {
    const body = await req.json();
    return { force: body?.force === true, dryRun: body?.dry_run === true };
  } catch {
    // Empty or malformed body: behave like the scheduled call.
    return { force: false, dryRun: false };
  }
}

async function fetchAccessToken(
  sa: ServiceAccount,
  nowSeconds: number,
): Promise<string> {
  const assertion = await signServiceAccountJwt(sa, nowSeconds);
  const res = await fetch(sa.token_uri, {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: new URLSearchParams({
      grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
      assertion,
    }),
  });
  const data = await res.json().catch(() => null);
  if (!res.ok || typeof data?.access_token !== "string") {
    throw new Error(`OAuth token exchange failed (HTTP ${res.status})`);
  }
  return data.access_token;
}

type SendResult = { ok: boolean; dead: boolean };

async function sendOne(
  projectId: string,
  accessToken: string,
  n: DueNotification,
): Promise<SendResult> {
  try {
    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          Authorization: `Bearer ${accessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(buildFcmMessage(n)),
      },
    );
    if (res.ok) {
      await res.body?.cancel();
      return { ok: true, dead: false };
    }
    const body = await res.json().catch(() => null);
    return { ok: false, dead: isDeadToken(res.status, body) };
  } catch {
    return { ok: false, dead: false };
  }
}

// PostgREST list values are double-quoted so tokens never break the filter.
function inFilter(tokens: string[]): string {
  const quoted = tokens.map((t) => `"${t.replace(/\\/g, "\\\\").replace(/"/g, '\\"')}"`);
  return encodeURIComponent(`in.(${quoted.join(",")})`);
}

async function removeTokens(
  supabaseUrl: string,
  serviceKey: string,
  tokens: string[],
): Promise<number> {
  let removed = 0;
  for (const batch of chunk(tokens, DELETE_BATCH_SIZE)) {
    try {
      const res = await fetch(
        `${supabaseUrl}/rest/v1/device_tokens?token=${inFilter(batch)}`,
        {
          method: "DELETE",
          headers: { apikey: serviceKey, Authorization: `Bearer ${serviceKey}` },
        },
      );
      await res.body?.cancel();
      if (res.ok) removed += batch.length;
    } catch {
      // A token that could not be removed is retried on the next run.
    }
  }
  return removed;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed" }, 405);

  const cronSecret = Deno.env.get("CRON_SECRET");
  const provided = req.headers.get("x-cron-secret") ?? "";
  if (!cronSecret || !timingSafeEqual(provided, cronSecret)) {
    return json({ error: "Unauthorized" }, 401);
  }

  const { force, dryRun } = await readOptions(req);

  try {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceKey) {
      throw new ConfigError("Supabase environment is not available");
    }
    const serviceAccount = readServiceAccount(Deno.env.get("FCM_SERVICE_ACCOUNT"));
    const notifyHour = parseNotifyHour(Deno.env.get("NOTIFY_HOUR") || undefined);
    const timeZone = Deno.env.get("NOTIFY_TIMEZONE") || "Europe/Madrid";

    const now = new Date();
    let local: { date: string; hour: number };
    try {
      local = localDateTime(now, timeZone);
    } catch {
      throw new ConfigError(`NOTIFY_TIMEZONE is not valid: "${timeZone}"`);
    }

    if (!shouldRun(local.hour, notifyHour, force)) {
      return json({
        skipped: "not_notify_hour",
        local_date: local.date,
        local_hour: local.hour,
      });
    }

    const rpc = await fetch(`${supabaseUrl}/rest/v1/rpc/notifications_due`, {
      method: "POST",
      headers: {
        apikey: serviceKey,
        Authorization: `Bearer ${serviceKey}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({ p_today: local.date, p_timezone: timeZone }),
    });
    if (!rpc.ok) {
      await rpc.body?.cancel();
      throw new Error(`notifications_due failed (HTTP ${rpc.status})`);
    }
    const rows: DueNotification[] = await rpc.json();

    if (dryRun) {
      const groups = new Map<
        string,
        { kind: string; title: string; body: string; devices: number }
      >();
      for (const r of rows) {
        const key = `${r.kind}|${r.tag}`;
        const group = groups.get(key) ??
          { kind: r.kind, title: r.title, body: r.body, devices: 0 };
        group.devices += 1;
        groups.set(key, group);
      }
      return json({
        ok: true,
        dry_run: true,
        local_date: local.date,
        local_hour: local.hour,
        notifications: [...groups.values()],
      });
    }

    let sent = 0;
    let failed = 0;
    const deadTokens = new Set<string>();

    if (rows.length > 0) {
      const accessToken = await fetchAccessToken(
        serviceAccount,
        Math.floor(now.getTime() / 1000),
      );
      for (const group of chunk(rows, SEND_CONCURRENCY)) {
        const results = await Promise.all(
          group.map((n) => sendOne(serviceAccount.project_id, accessToken, n)),
        );
        results.forEach((result, i) => {
          if (result.ok) sent += 1;
          else failed += 1;
          if (result.dead) deadTokens.add(group[i].token);
        });
      }
    }

    const removedTokens = deadTokens.size > 0
      ? await removeTokens(supabaseUrl, serviceKey, [...deadTokens])
      : 0;

    const summary = {
      ok: true,
      local_date: local.date,
      local_hour: local.hour,
      candidates: rows.length,
      sent,
      failed,
      removed_tokens: removedTokens,
      // PostgREST returns at most `max-rows` (1000 by default) rows.
      ...(rows.length >= PROBABLE_ROW_LIMIT ? { possibly_truncated: true } : {}),
    };
    // Counts only: never log tokens or notification text.
    console.log(JSON.stringify({ event: "send-daily-notifications", ...summary }));
    return json(summary);
  } catch (error) {
    const message = error instanceof Error ? error.message : "Unexpected error";
    console.error(JSON.stringify({ event: "send-daily-notifications", error: message }));
    return json({ error: message }, 500);
  }
});
