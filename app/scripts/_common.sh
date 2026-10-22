#!/bin/sh
# Shared helpers for the shell scripts in this folder. Source it after setting
# SCRIPT_DIR:
#
#   SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
#   . "$SCRIPT_DIR/_common.sh"
#
# It gives every script the same console output:
#
#   [luma] ==> Running tests              step
#   [luma]     Working dir: ...           detail
#   [luma] OK  Finished in 1m 15s         success
#   [luma] ERR Failed after 3s: ...       error
#
# Colors are used only on a terminal, and never when NO_COLOR is set.

APP_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE_NAME=".env"
LOG_TAG="[luma]"

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
  COLOR_STEP='\033[36m'
  COLOR_INFO='\033[90m'
  COLOR_OK='\033[32m'
  COLOR_ERR='\033[31m'
  COLOR_OFF='\033[0m'
else
  COLOR_STEP=''
  COLOR_INFO=''
  COLOR_OK=''
  COLOR_ERR=''
  COLOR_OFF=''
fi

log_step() { printf '%b%s ==> %s%b\n' "$COLOR_STEP" "$LOG_TAG" "$1" "$COLOR_OFF"; }
log_info() { printf '%b%s     %s%b\n' "$COLOR_INFO" "$LOG_TAG" "$1" "$COLOR_OFF"; }
log_ok() { printf '%b%s OK  %s%b\n' "$COLOR_OK" "$LOG_TAG" "$1" "$COLOR_OFF"; }
log_fail() { printf '%b%s ERR %s%b\n' "$COLOR_ERR" "$LOG_TAG" "$1" "$COLOR_OFF" >&2; }

format_elapsed() {
  if [ "$1" -ge 60 ]; then
    printf '%sm %ss' "$(($1 / 60))" "$(($1 % 60))"
  else
    printf '%ss' "$1"
  fi
}

TASK_STARTED_AT=""
TASK_FAILURE_MESSAGE=""

# Starts a task: logs its title and, when the script ends, how long it took.
# Any failure (see fail) is reported once, with the elapsed time.
task_start() {
  TASK_STARTED_AT="$(date +%s)"
  trap task_finish EXIT
  log_step "$1"
}

task_finish() {
  status=$?
  trap - EXIT
  elapsed="$(format_elapsed "$(($(date +%s) - TASK_STARTED_AT))")"
  if [ "$status" -eq 0 ]; then
    log_ok "Finished in $elapsed"
  else
    log_fail "Failed after $elapsed${TASK_FAILURE_MESSAGE:+: $TASK_FAILURE_MESSAGE}"
  fi
  exit "$status"
}

# Ends the script with an error; the message goes in the final failure line.
fail() {
  TASK_FAILURE_MESSAGE="$1"
  exit 1
}

# Moves to app/ so the scripts work from any folder.
enter_app_dir() {
  cd "$APP_DIR"
  log_info "Working dir: $APP_DIR"
}

assert_env_file() {
  if [ ! -f "$ENV_FILE_NAME" ]; then
    fail "Missing env file app/$ENV_FILE_NAME. Copy app/.env.example to app/$ENV_FILE_NAME and fill in the values."
  fi
  log_info "Env file: $ENV_FILE_NAME"
}

# Runs flutter with the given arguments, logging the exact command first.
run_flutter() {
  if ! command -v flutter >/dev/null 2>&1; then
    fail "Flutter was not found in PATH. Install it (https://docs.flutter.dev/get-started/install) and reopen the terminal."
  fi
  log_info "Command: flutter $*"
  flutter "$@" || fail "flutter $1 failed (exit code $?)"
}
