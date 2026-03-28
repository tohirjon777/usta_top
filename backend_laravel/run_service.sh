#!/bin/bash

set -euo pipefail

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$BACKEND_DIR/.env.local"
LOG_DIR="$BACKEND_DIR/storage/logs"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

mkdir -p "$LOG_DIR" "$BACKEND_DIR/storage/app/ustatop"

cd "$BACKEND_DIR"

if ! command -v php >/dev/null 2>&1; then
  echo "PHP topilmadi. Avval PHP ni o'rnating." >&2
  exit 1
fi

if ! command -v composer >/dev/null 2>&1; then
  echo "Composer topilmadi. Avval Composer ni o'rnating." >&2
  exit 1
fi

if [[ ! -f ".env" ]]; then
  cp .env.example .env
fi

if [[ ! -d "vendor" || "composer.json" -nt "vendor" || "composer.lock" -nt "vendor" ]]; then
  composer install --no-interaction --prefer-dist
fi

php artisan key:generate --force >/dev/null 2>&1 || true

set -a
# shellcheck disable=SC1091
source ".env"
set +a

export PHP_CLI_SERVER_WORKERS="${PHP_CLI_SERVER_WORKERS:-4}"

exec php artisan serve --host="${HOST:-127.0.0.1}" --port="${PORT:-8080}"
