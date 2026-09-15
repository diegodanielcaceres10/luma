#!/bin/sh
# Compila el APK, lo renombra con nombre + versión + timestamp y lo deja
# en app/dist/ (fuera de git) junto con un alias "latest" fijo.
#
# Uso:
#   ./scripts/build_apk.sh              # release (default)
#   ./scripts/build_apk.sh debug
#   INSTALL=1 ./scripts/build_apk.sh     # además instala en el dispositivo conectado (adb)
set -e

MODE="${1:-release}"
APP_NAME="luma"

# scripts/build_apk.sh -> app/
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$APP_DIR"

VERSION_LINE=$(grep '^version:' pubspec.yaml | head -1)
VERSION_NAME=$(echo "$VERSION_LINE" | sed -E 's/version:\s*([0-9.]+)\+([0-9]+)/\1/')
BUILD_NUMBER=$(echo "$VERSION_LINE" | sed -E 's/version:\s*([0-9.]+)\+([0-9]+)/\2/')

echo "⚙️  Compilando APK ($MODE)..."
flutter build apk "--$MODE"

SRC_APK="build/app/outputs/flutter-apk/app-$MODE.apk"
if [ ! -f "$SRC_APK" ]; then
  echo "❌ No encontré el APK generado en $SRC_APK"
  exit 1
fi

DIST_DIR="dist"
mkdir -p "$DIST_DIR"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
DEST_APK="$DIST_DIR/$APP_NAME-v$VERSION_NAME+$BUILD_NUMBER-$MODE-$TIMESTAMP.apk"
LATEST_APK="$DIST_DIR/$APP_NAME-latest-$MODE.apk"

mv "$SRC_APK" "$DEST_APK"
cp "$DEST_APK" "$LATEST_APK"

echo "✅ APK listo:"
echo "   $DEST_APK"
echo "   $LATEST_APK  (alias fijo, para instalar sin acordarte el nombre exacto)"

if [ "$INSTALL" = "1" ]; then
  echo "📲 Instalando en el dispositivo conectado..."
  adb install -r "$DEST_APK"
fi
