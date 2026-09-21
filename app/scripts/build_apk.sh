#!/bin/sh
# Compila el APK en modo debug (release lo genera GitHub) y lo deja en
# app/dist/ (fuera de git) con nombre luma-app-debug-<timestamp>.apk.
#
# Uso:
#   ./scripts/build_apk.sh           # compila y lo deja en dist/
#   INSTALL=1 ./scripts/build_apk.sh # además instala en el dispositivo conectado (adb)
set -e

# scripts/build_apk.sh -> app/
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_DIR"

# Las variables (Supabase, Google) se compilan dentro del APK desde app/.env;
# ya no viajan como asset. Ver README.
ENV_FILE=".env"
if [ ! -f "$ENV_FILE" ]; then
  echo "❌ No encontré app/$ENV_FILE (copiá .env.example y completalo)"
  exit 1
fi

echo "⚙️  Compilando APK (debug)..."
flutter build apk --debug --dart-define-from-file="$ENV_FILE"

SRC_APK="build/app/outputs/flutter-apk/app-debug.apk"
if [ ! -f "$SRC_APK" ]; then
  echo "❌ No encontré el APK generado en $SRC_APK"
  exit 1
fi

DIST_DIR="dist"
mkdir -p "$DIST_DIR"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
DEST_APK="$DIST_DIR/luma-app-debug-$TIMESTAMP.apk"

mv "$SRC_APK" "$DEST_APK"

echo "✅ APK listo: $DEST_APK"

if [ "$INSTALL" = "1" ]; then
  echo "📲 Instalando en el dispositivo conectado..."
  adb install -r "$DEST_APK"
fi
