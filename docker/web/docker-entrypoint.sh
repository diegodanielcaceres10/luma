#!/bin/sh
# Chooses what the web container runs from APP_ENV: the dev server locally, or a build with the matching Angular configuration.
set -eu

APP_ENV="${APP_ENV:-local}"

case "$APP_ENV" in
  local)
    exec npm start
    ;;
  dev)
    exec npm run build -- --configuration=development
    ;;
  prod)
    exec npm run build -- --configuration=production
    ;;
  *)
    echo "docker-entrypoint: unsupported APP_ENV '$APP_ENV' (expected local, dev or prod)" >&2
    exit 1
    ;;
esac
