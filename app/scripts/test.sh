#!/bin/sh
# Runs the Flutter tests. Extra arguments go to `flutter test`.
#
# Usage:
#   ./scripts/test.sh                            # whole suite
#   ./scripts/test.sh test/core/ai               # one folder or file
#   ./scripts/test.sh --name "keeps each stage"  # tests matching a name
#
# Can be run from anywhere; the script locates app/ by itself. Paths are
# relative to app/.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
. "$SCRIPT_DIR/_common.sh"

task_start "Running tests"
enter_app_dir
run_flutter test "$@"
