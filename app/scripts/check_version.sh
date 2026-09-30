#!/bin/sh
# Compares two semver versions (X.Y.Z, ignoring +build) and fails unless the
# new one is strictly greater than the previous one.
#
# Usage: ./check_version.sh <previous_version> <new_version>
set -e

PREVIOUS="${1%%+*}"
CURRENT="${2%%+*}"

if [ -z "$PREVIOUS" ] || [ -z "$CURRENT" ]; then
  echo "❌ Falta alguna versión para comparar (anterior='$1' nueva='$2')"
  exit 1
fi

HIGHER=$(printf '%s\n%s\n' "$PREVIOUS" "$CURRENT" | sort -V | tail -n1)

if [ "$CURRENT" = "$PREVIOUS" ] || [ "$HIGHER" = "$PREVIOUS" ]; then
  echo "❌ La versión no aumentó: $PREVIOUS -> $CURRENT."
  echo "   Actualizá el campo 'version' (X.Y.Z) en app/pubspec.yaml antes de deployar."
  exit 1
fi

echo "✅ Versión OK: $PREVIOUS -> $CURRENT"