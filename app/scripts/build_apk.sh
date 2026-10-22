#!/bin/sh
# Builds a debug APK (release is built by GitHub) into app/dist/ (git-ignored)
# as luma-app-debug-<timestamp>.apk.
#
# Usage:
#   ./scripts/build_apk.sh            # build into dist/
#   INSTALL=1 ./scripts/build_apk.sh  # also install on the connected device (adb)
#
# Can be run from anywhere; the script locates app/ by itself.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_common.sh"

task_start "Building debug APK"
enter_app_dir
assert_env_file

run_flutter build apk --debug "--dart-define-from-file=$ENV_FILE_NAME"

SRC_APK="build/app/outputs/flutter-apk/app-debug.apk"
if [ ! -f "$SRC_APK" ]; then
  fail "Generated APK not found at $SRC_APK"
fi

DIST_DIR="dist"
mkdir -p "$DIST_DIR"

TIMESTAMP=$(date +"%Y%m%d-%H%M%S")
DEST_APK="$DIST_DIR/luma-app-debug-$TIMESTAMP.apk"
mv "$SRC_APK" "$DEST_APK"
log_ok "APK ready: $DEST_APK"

if [ "$INSTALL" = "1" ]; then
  log_step "Installing on the connected device"
  if ! command -v adb >/dev/null 2>&1; then
    fail "adb was not found in PATH. Install the Android platform tools to use INSTALL=1."
  fi
  log_info "Command: adb install -r $DEST_APK"
  adb install -r "$DEST_APK" || fail "adb install failed (exit code $?)"
  log_ok "APK installed"
fi
