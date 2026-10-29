// Pure helpers for send-daily-notifications. No Deno APIs, so they can be
// unit-tested with `node --test`.

export type DueNotification = {
  user_id: string;
  token: string;
  kind: string;
  tag: string;
  title: string;
  body: string;
};

export type ServiceAccount = {
  client_email: string;
  private_key: string;
  token_uri: string;
  project_id: string;
};

const FCM_SCOPE = "https://www.googleapis.com/auth/firebase.messaging";

/** Current date (YYYY-MM-DD) and hour (0-23) in the given IANA time zone. */
export function localDateTime(
  now: Date,
  timeZone: string,
): { date: string; hour: number } {
  const parts = new Intl.DateTimeFormat("en-CA", {
    timeZone,
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    hourCycle: "h23",
  }).formatToParts(now);
  const get = (type: string) => parts.find((p) => p.type === type)!.value;
  return {
    date: `${get("year")}-${get("month")}-${get("day")}`,
    hour: Number(get("hour")),
  };
}

export function parseNotifyHour(value: string | undefined): number {
  if (value === undefined) return 9;
  if (!/^\d{1,2}$/.test(value.trim())) {
    throw new Error(`NOTIFY_HOUR must be an integer between 0 and 23: "${value}"`);
  }
  const hour = Number(value);
  if (hour > 23) {
    throw new Error(`NOTIFY_HOUR must be an integer between 0 and 23: "${value}"`);
  }
  return hour;
}

export function shouldRun(
  hour: number,
  notifyHour: number,
  force: boolean,
): boolean {
  return force || hour === notifyHour;
}

export function buildFcmMessage(
  n: DueNotification,
): { message: Record<string, unknown> } {
  return {
    message: {
      token: n.token,
      notification: { title: n.title, body: n.body },
      data: { kind: n.kind, tag: n.tag },
      android: {
        priority: "HIGH",
        ttl: "21600s",
        notification: {
          channel_id: "invoices_due",
          icon: "ic_notification",
          color: "#1F7A4C",
          tag: n.tag,
        },
      },
      // Browsers (PWA). FCM ignores the block that does not match the token.
      webpush: {
        headers: { TTL: "21600", Urgency: "high" },
        notification: { icon: "/icons/Icon-192.png", tag: n.tag },
      },
    },
  };
}

type FcmError = {
  error?: {
    status?: string;
    details?: Array<{
      errorCode?: string;
      fieldViolations?: Array<{ field?: string }>;
    }>;
  };
};

/**
 * True only when FCM says the registration token itself is no longer valid.
 * Any other failure (quota, server errors, a bad payload) must keep the token.
 */
export function isDeadToken(status: number, body: unknown): boolean {
  if (status === 404) return true;
  if (body === null || typeof body !== "object") return false;
  const error = (body as FcmError).error;
  const details = Array.isArray(error?.details) ? error.details : [];
  if (details.some((d) => d?.errorCode === "UNREGISTERED")) return true;
  return status === 400 &&
    error?.status === "INVALID_ARGUMENT" &&
    details.some((d) =>
      Array.isArray(d?.fieldViolations) &&
      d.fieldViolations.some((v) => v?.field === "message.token")
    );
}

function base64url(input: Uint8Array | string): string {
  const bytes = typeof input === "string"
    ? new TextEncoder().encode(input)
    : input;
  let binary = "";
  for (const b of bytes) binary += String.fromCharCode(b);
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

function pemToDer(pem: string): Uint8Array {
  // Secrets stored from a JSON file often keep the "\n" sequences escaped.
  const b64 = pem
    .replace(/\\n/g, "\n")
    .replace(/-----(BEGIN|END) PRIVATE KEY-----/g, "")
    .replace(/\s+/g, "");
  const binary = atob(b64);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

/** Signed JWT (RS256) used to request an OAuth access token for FCM. */
export async function signServiceAccountJwt(
  sa: ServiceAccount,
  nowSeconds: number,
): Promise<string> {
  const header = base64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claims = base64url(JSON.stringify({
    iss: sa.client_email,
    scope: FCM_SCOPE,
    aud: sa.token_uri,
    iat: nowSeconds,
    exp: nowSeconds + 3600,
  }));
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToDer(sa.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    new TextEncoder().encode(`${header}.${claims}`),
  );
  return `${header}.${claims}.${base64url(new Uint8Array(signature))}`;
}

/** Constant-time comparison over the longer length; length mismatch fails. */
export function timingSafeEqual(a: string, b: string): boolean {
  const ea = new TextEncoder().encode(a);
  const eb = new TextEncoder().encode(b);
  let diff = ea.length ^ eb.length;
  const length = Math.max(ea.length, eb.length);
  for (let i = 0; i < length; i++) diff |= (ea[i] ?? 0) ^ (eb[i] ?? 0);
  return diff === 0;
}

export function chunk<T>(items: T[], size: number): T[][] {
  const result: T[][] = [];
  for (let i = 0; i < items.length; i += size) result.push(items.slice(i, i + size));
  return result;
}
