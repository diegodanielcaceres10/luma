import test from "node:test";
import assert from "node:assert/strict";
import { webcrypto } from "node:crypto";
import {
  buildFcmMessage,
  chunk,
  isDeadToken,
  localDateTime,
  parseNotifyHour,
  shouldRun,
  signServiceAccountJwt,
  timingSafeEqual,
  type DueNotification,
} from "./lib.ts";

const TZ = "Europe/Madrid";

test("localDateTime: hour 9 at the right UTC instant on the spring DST change", () => {
  assert.deepEqual(localDateTime(new Date("2026-03-29T07:00:00Z"), TZ), {
    date: "2026-03-29",
    hour: 9,
  });
  assert.equal(localDateTime(new Date("2026-03-29T06:00:00Z"), TZ).hour, 8);
});

test("localDateTime: hour 9 at the right UTC instant on the autumn DST change", () => {
  assert.equal(localDateTime(new Date("2026-10-25T07:59:00Z"), TZ).hour, 8);
  assert.equal(localDateTime(new Date("2026-10-25T08:00:00Z"), TZ).hour, 9);
});

test("localDateTime: midnight is hour 0 and the date rolls over", () => {
  assert.deepEqual(localDateTime(new Date("2026-11-30T23:30:00Z"), TZ), {
    date: "2026-12-01",
    hour: 0,
  });
});

test("parseNotifyHour", () => {
  assert.equal(parseNotifyHour(undefined), 9);
  assert.equal(parseNotifyHour("7"), 7);
  for (const bad of ["24", "-1", "abc", "9.5", ""]) {
    assert.throws(() => parseNotifyHour(bad), bad);
  }
});

test("shouldRun", () => {
  assert.equal(shouldRun(9, 9, false), true);
  assert.equal(shouldRun(10, 9, false), false);
  assert.equal(shouldRun(10, 9, true), true);
});

test("buildFcmMessage", () => {
  const n: DueNotification = {
    user_id: "u1",
    token: "tok",
    kind: "invoice_due",
    tag: "invoice_due:i1:2026-11-30",
    title: "Vence hoy: Luz",
    body: "La factura de Luz vence hoy.",
  };
  assert.deepEqual(buildFcmMessage(n), {
    message: {
      token: "tok",
      notification: { title: n.title, body: n.body },
      data: { kind: "invoice_due", tag: n.tag },
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
      webpush: {
        headers: { TTL: "21600", Urgency: "high" },
        notification: { icon: "/icons/Icon-192.png", tag: n.tag },
      },
    },
  });
});

test("isDeadToken", () => {
  const badArg = (field: string) => ({
    error: {
      status: "INVALID_ARGUMENT",
      details: [
        {
          "@type": "type.googleapis.com/google.rpc.BadRequest",
          fieldViolations: [{ field }],
        },
      ],
    },
  });
  assert.equal(isDeadToken(404, null), true);
  assert.equal(isDeadToken(200, null), false);
  assert.equal(isDeadToken(400, badArg("message.token")), true);
  assert.equal(isDeadToken(400, badArg("message.notification.title")), false);
  assert.equal(isDeadToken(400, { error: { status: "INVALID_ARGUMENT" } }), false);
  assert.equal(
    isDeadToken(403, {
      error: { details: [{ errorCode: "UNREGISTERED" }] },
    }),
    true,
  );
  assert.equal(isDeadToken(500, { error: { status: "INTERNAL" } }), false);
  assert.equal(isDeadToken(500, null), false);
  assert.equal(isDeadToken(400, "oops"), false);
});

const b64urlToBytes = (s: string) =>
  Uint8Array.from(Buffer.from(s, "base64url"));

test("signServiceAccountJwt signs RS256 with the expected claims", async () => {
  const pair = await webcrypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const pkcs8 = Buffer.from(
    await webcrypto.subtle.exportKey("pkcs8", pair.privateKey),
  ).toString("base64");
  const pem = `-----BEGIN PRIVATE KEY-----\n${
    pkcs8.match(/.{1,64}/g)!.join("\n")
  }\n-----END PRIVATE KEY-----\n`;

  const jwt = await signServiceAccountJwt(
    {
      client_email: "sa@proj.iam.gserviceaccount.com",
      private_key: pem,
      token_uri: "https://oauth2.googleapis.com/token",
      project_id: "proj",
    },
    1_800_000_000,
  );

  const [h, c, s] = jwt.split(".");
  assert.ok(!jwt.includes("=") && !jwt.includes("+") && !jwt.includes("/"));
  assert.deepEqual(JSON.parse(Buffer.from(h, "base64url").toString()), {
    alg: "RS256",
    typ: "JWT",
  });
  assert.deepEqual(JSON.parse(Buffer.from(c, "base64url").toString()), {
    iss: "sa@proj.iam.gserviceaccount.com",
    scope: "https://www.googleapis.com/auth/firebase.messaging",
    aud: "https://oauth2.googleapis.com/token",
    iat: 1_800_000_000,
    exp: 1_800_003_600,
  });
  const ok = await webcrypto.subtle.verify(
    "RSASSA-PKCS1-v1_5",
    pair.publicKey,
    b64urlToBytes(s),
    new TextEncoder().encode(`${h}.${c}`),
  );
  assert.equal(ok, true);
});

test("signServiceAccountJwt accepts a key with escaped newlines", async () => {
  const pair = await webcrypto.subtle.generateKey(
    {
      name: "RSASSA-PKCS1-v1_5",
      modulusLength: 2048,
      publicExponent: new Uint8Array([1, 0, 1]),
      hash: "SHA-256",
    },
    true,
    ["sign", "verify"],
  );
  const b64 = Buffer.from(
    await webcrypto.subtle.exportKey("pkcs8", pair.privateKey),
  ).toString("base64");
  const escaped = `-----BEGIN PRIVATE KEY-----\\n${b64}\\n-----END PRIVATE KEY-----\\n`;
  const jwt = await signServiceAccountJwt(
    { client_email: "a", private_key: escaped, token_uri: "u", project_id: "p" },
    1,
  );
  assert.equal(jwt.split(".").length, 3);
});

test("timingSafeEqual", () => {
  assert.equal(timingSafeEqual("secret", "secret"), true);
  assert.equal(timingSafeEqual("secret", "secreT"), false);
  assert.equal(timingSafeEqual("secret", "secret2"), false);
  assert.equal(timingSafeEqual("", "x"), false);
  assert.equal(timingSafeEqual("", ""), true);
});

test("chunk", () => {
  assert.deepEqual(chunk([1, 2, 3, 4, 5], 2), [[1, 2], [3, 4], [5]]);
  assert.deepEqual(chunk([], 3), []);
});
