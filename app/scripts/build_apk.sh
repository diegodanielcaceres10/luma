#!/bin/sh
# Builds a debug APK (release is built by GitHub) into app/dist/ (git-ignored)
# as luma-app-debug-<timestamp>.apk.
#
# Usage:
#   ./scripts/build_apk.sh            # build into dist/
#   INSTALL=1 ./scripts/build_apk.sh  # also install on the connected device (adb)
set -e

APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_DIR"

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
