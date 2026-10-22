#!/bin/sh
# Runs the app in the browser with the variables from app/.env.
#
# Usage:
#   ./scripts/run.sh                    # Chrome on port 5005
#   PORT=5010 ./scripts/run.sh          # another web port
#   DEVICE=linux ./scripts/run.sh       # another device (the port is ignored)
#
# Can be run from anywhere; the script locates app/ by itself. Press q in the
# terminal to quit.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_common.sh"

DEVICE="${DEVICE:-chrome}"
PORT="${PORT:-5005}"

task_start "Running the app on $DEVICE"
enter_app_dir
assert_env_file

# Only web devices take a port.
case "$DEVICE" in
  chrome | edge | web-server)
    run_flutter run -d "$DEVICE" "--web-port=$PORT" "--dart-define-from-file=$ENV_FILE_NAME"
    ;;
  *)
    run_flutter run -d "$DEVICE" "--dart-define-from-file=$ENV_FILE_NAME"
    ;;
esac
