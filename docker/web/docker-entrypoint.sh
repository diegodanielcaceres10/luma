#!/bin/sh
# Chooses what the web container runs from APP_ENV: the dev server locally, a build in every other environment.
set -eu

APP_ENV="${APP_ENV:-local}"

case "$APP_ENV" in
  local)
    exec npm start
    ;;
  dev | staging | prod)
    exec npm run build
    ;;
  *)
    echo "docker-entrypoint: unsupported APP_ENV '$APP_ENV' (expected local, dev, staging or prod)" >&2
    exit 1
    ;;
esac
