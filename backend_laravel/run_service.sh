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

SERVER_PID=""
POLL_PID=""

cleanup() {
  if [[ -n "$SERVER_PID" ]] && kill -0 "$SERVER_PID" >/dev/null 2>&1; then
    kill "$SERVER_PID" >/dev/null 2>&1 || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
  if [[ -n "$POLL_PID" ]] && kill -0 "$POLL_PID" >/dev/null 2>&1; then
    kill "$POLL_PID" >/dev/null 2>&1 || true
    wait "$POLL_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

if [[ -n "${TELEGRAM_BOT_TOKEN:-}" ]]; then
  php artisan ustatop:telegram-poll >> "$LOG_DIR/telegram-poll.out.log" 2>> "$LOG_DIR/telegram-poll.err.log" &
  POLL_PID="$!"
fi

php artisan serve --host="${HOST:-127.0.0.1}" --port="${PORT:-8080}" &
SERVER_PID="$!"

wait "$SERVER_PID"
