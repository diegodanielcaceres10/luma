#!/bin/sh
# Replaces the Firebase placeholders of the web push service worker with the
# values from an .env file. Run it on the build output (build/web), never on
# the source file in web/.
#
# Usage: ./configure_web_push.sh <env-file> <service-worker-file>
set -e

ENV_FILE="$1"
TARGET="$2"

if [ -z "$ENV_FILE" ] || [ -z "$TARGET" ]; then
  echo "❌ Uso: configure_web_push.sh <archivo .env> <firebase-messaging-sw.js>"
  exit 1
fi
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ No existe el archivo de variables: $ENV_FILE"
  exit 1
fi
if [ ! -f "$TARGET" ]; then
  echo "❌ No existe el service worker: $TARGET"
  exit 1
fi

# Value of a variable in the .env file (last one wins). The file is read as
# text, never executed. A trailing carriage return (CRLF files) is dropped.
read_var() {
  grep "^$1=" "$ENV_FILE" | tail -n 1 | cut -d= -f2- | tr -d '\r'
}

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\\/&]/\\&/g'
}

missing=""
for name in FIREBASE_WEB_API_KEY FIREBASE_WEB_APP_ID FIREBASE_MESSAGING_SENDER_ID FIREBASE_PROJECT_ID; do
  if [ -z "$(read_var "$name")" ]; then
    missing="$missing $name"
  fi
done
if [ -n "$missing" ]; then
  echo "❌ Faltan variables para las notificaciones web:$missing (ver README)."
  exit 1
fi

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT

sed \
  -e "s/__FIREBASE_WEB_API_KEY__/$(escape_sed "$(read_var FIREBASE_WEB_API_KEY)")/g" \
  -e "s/__FIREBASE_WEB_APP_ID__/$(escape_sed "$(read_var FIREBASE_WEB_APP_ID)")/g" \
  -e "s/__FIREBASE_MESSAGING_SENDER_ID__/$(escape_sed "$(read_var FIREBASE_MESSAGING_SENDER_ID)")/g" \
  -e "s/__FIREBASE_PROJECT_ID__/$(escape_sed "$(read_var FIREBASE_PROJECT_ID)")/g" \
  "$TARGET" > "$TMP"

if grep -q '__FIREBASE_[A-Z_]*__' "$TMP"; then
  echo "❌ Quedaron marcadores sin reemplazar en $TARGET."
  exit 1
fi

cat "$TMP" > "$TARGET"
echo "✅ Service worker de notificaciones web configurado."
