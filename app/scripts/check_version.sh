#!/bin/sh
# Compara dos versiones con formato X.Y.Z+B (versionName+versionCode) y falla si:
#   - la parte semver (X.Y.Z) retrocede, o
#   - el build number (+B / versionCode) no aumenta estrictamente
#
# El build number debe subir siempre, incluso si X.Y.Z no cambia, porque
# es el que usan Android/Firebase para identificar cada build como único.
#
# Uso: ./check_version.sh <version_anterior> <version_nueva>
set -e

PREVIOUS_SEMVER="${1%%+*}"
CURRENT_SEMVER="${2%%+*}"

PREVIOUS_BUILD="${1#*+}"
CURRENT_BUILD="${2#*+}"

# Si no había "+", ${var#*+} devuelve el string sin cambios: no hay build number.
[ "$PREVIOUS_BUILD" = "$1" ] && PREVIOUS_BUILD=""
[ "$CURRENT_BUILD" = "$2" ] && CURRENT_BUILD=""

if [ -z "$PREVIOUS_SEMVER" ] || [ -z "$CURRENT_SEMVER" ]; then
  echo "❌ Falta alguna versión para comparar (anterior='$1' nueva='$2')"
  exit 1
fi

if [ -z "$CURRENT_BUILD" ]; then
  echo "❌ Falta el build number (+B) en la nueva versión ('$2')."
  echo "   Usá el formato X.Y.Z+B, ej: 1.0.1+2."
  exit 1
fi

case "$CURRENT_BUILD" in
  ''|*[!0-9]*)
    echo "❌ El build number ('+$CURRENT_BUILD') debe ser un número entero."
    exit 1
    ;;
esac

HIGHER_SEMVER=$(printf '%s\n%s\n' "$PREVIOUS_SEMVER" "$CURRENT_SEMVER" | sort -V | tail -n1)

if [ "$HIGHER_SEMVER" = "$PREVIOUS_SEMVER" ] && [ "$CURRENT_SEMVER" != "$PREVIOUS_SEMVER" ]; then
  echo "❌ La versión retrocedió: $PREVIOUS_SEMVER -> $CURRENT_SEMVER."
  echo "   Actualizá el campo 'version' en app/pubspec.yaml antes de deployar."
  exit 1
fi

if [ -n "$PREVIOUS_BUILD" ] && [ "$CURRENT_BUILD" -le "$PREVIOUS_BUILD" ]; then
  echo "❌ El build number no aumentó: +$PREVIOUS_BUILD -> +$CURRENT_BUILD."
  echo "   El build number (+B) debe subir siempre, aunque X.Y.Z no cambie."
  exit 1
fi

echo "✅ Versión OK: $1 -> $2"