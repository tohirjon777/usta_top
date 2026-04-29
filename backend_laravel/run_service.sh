#!/bin/bash

set -euo pipefail

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$BACKEND_DIR/.env.local"
SECRETS_ENV_FILE="$BACKEND_DIR/secrets/local.env"
LOG_DIR="$BACKEND_DIR/storage/logs"

export PATH="$HOME/.local/bin:/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Apple/usr/bin:$PATH"

find_binary() {
  local name="$1"
  shift

  if command -v "$name" >/dev/null 2>&1; then
    command -v "$name"
    return 0
  fi

  local candidate=""
  for candidate in "$@"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

PHP_BIN="$(find_binary php /opt/homebrew/bin/php /usr/local/bin/php || true)"
COMPOSER_BIN="$(find_binary composer "$HOME/.local/bin/composer" /opt/homebrew/bin/composer /usr/local/bin/composer || true)"

mkdir -p "$LOG_DIR" "$BACKEND_DIR/storage/app/ustatop"

cd "$BACKEND_DIR"

if [[ -z "$PHP_BIN" ]]; then
  echo "PHP topilmadi. Avval PHP ni o'rnating." >&2
  exit 1
fi

if [[ -z "$COMPOSER_BIN" ]]; then
  echo "Composer topilmadi. Avval Composer ni o'rnating." >&2
  exit 1
fi

if [[ ! -f ".env" ]]; then
  cp .env.example .env
fi

set -a
# shellcheck disable=SC1091
source ".env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi
if [[ -f "$SECRETS_ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$SECRETS_ENV_FILE"
fi
set +a

if [[ ! -d "vendor" || "composer.json" -nt "vendor" || "composer.lock" -nt "vendor" ]]; then
  "$COMPOSER_BIN" install --no-interaction --prefer-dist
fi

if ! grep -Eq '^APP_KEY=.+$' ".env" 2>/dev/null; then
  "$PHP_BIN" artisan key:generate --force >/dev/null 2>&1 || true
fi
"$PHP_BIN" artisan ustatop:bootstrap-storage >/dev/null 2>&1 || true
"$PHP_BIN" artisan migrate --force >/dev/null 2>&1 || true

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
  "$PHP_BIN" artisan ustatop:telegram-poll >> "$LOG_DIR/telegram-poll.out.log" 2>> "$LOG_DIR/telegram-poll.err.log" &
  POLL_PID="$!"
fi

"$PHP_BIN" artisan serve --host="${HOST:-127.0.0.1}" --port="${PORT:-8080}" &
SERVER_PID="$!"

wait "$SERVER_PID"
