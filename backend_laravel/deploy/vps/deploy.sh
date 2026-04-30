#!/bin/bash

set -euo pipefail

APP_DIR="/var/www/ustatop"
REPO_URL=""
BRANCH="main"
PHP_VERSION="8.3"
APP_OWNER=""
WEB_GROUP="www-data"
SKIP_REPO_PULL=0

usage() {
  cat <<'EOF'
Usage:
  ./deploy.sh [options]

Options:
  --app-dir DIR        Repo root on server (default: /var/www/ustatop)
  --repo-url URL       Clone URL if repo is not present yet
  --branch NAME        Git branch to deploy (default: main)
  --php-version VER    PHP version for FPM reload (default: 8.3)
  --app-owner USER     Owner of app files (default: current sudo user)
  --web-group GROUP    Web group (default: www-data)
  --skip-repo-pull     Skip git fetch/pull step
  --help               Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --app-dir)
      APP_DIR="${2:-}"
      shift 2
      ;;
    --repo-url)
      REPO_URL="${2:-}"
      shift 2
      ;;
    --branch)
      BRANCH="${2:-}"
      shift 2
      ;;
    --php-version)
      PHP_VERSION="${2:-}"
      shift 2
      ;;
    --app-owner)
      APP_OWNER="${2:-}"
      shift 2
      ;;
    --web-group)
      WEB_GROUP="${2:-}"
      shift 2
      ;;
    --skip-repo-pull)
      SKIP_REPO_PULL=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$APP_OWNER" ]]; then
  APP_OWNER="${SUDO_USER:-$(id -un)}"
fi

BACKEND_DIR="$APP_DIR/backend_laravel"
PHP_BIN="$(command -v php || true)"
COMPOSER_BIN="$(command -v composer || true)"

as_root() {
  if [[ "${EUID:-$(id -u)}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

if [[ -z "$PHP_BIN" ]]; then
  echo "PHP topilmadi." >&2
  exit 1
fi

if [[ -z "$COMPOSER_BIN" ]]; then
  echo "Composer topilmadi." >&2
  exit 1
fi

mkdir -p "$APP_DIR"

if [[ ! -d "$APP_DIR/.git" ]]; then
  if [[ -z "$REPO_URL" ]]; then
    echo "Repo hali klon qilinmagan. --repo-url bering." >&2
    exit 1
  fi
  git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
fi

if [[ "$SKIP_REPO_PULL" -eq 0 ]]; then
  git -C "$APP_DIR" fetch origin "$BRANCH" --prune
  git -C "$APP_DIR" checkout "$BRANCH"
  git -C "$APP_DIR" pull --ff-only origin "$BRANCH"
fi

if [[ ! -d "$BACKEND_DIR" ]]; then
  echo "Backend papkasi topilmadi: $BACKEND_DIR" >&2
  exit 1
fi

cd "$BACKEND_DIR"

if [[ ! -f ".env" ]]; then
  echo ".env topilmadi: $BACKEND_DIR/.env" >&2
  exit 1
fi

"$COMPOSER_BIN" install --no-interaction --prefer-dist --optimize-autoloader --no-dev

if ! grep -Eq '^APP_KEY=.+$' ".env" 2>/dev/null; then
  "$PHP_BIN" artisan key:generate --force
fi

"$PHP_BIN" artisan migrate --force
"$PHP_BIN" artisan ustatop:bootstrap-storage
"$PHP_BIN" artisan optimize:clear
"$PHP_BIN" artisan config:cache
"$PHP_BIN" artisan route:cache
"$PHP_BIN" artisan view:cache
"$PHP_BIN" artisan ustatop:doctor

as_root chown -R "$APP_OWNER:$WEB_GROUP" "$APP_DIR"
as_root chown -R "$WEB_GROUP:$WEB_GROUP" "$BACKEND_DIR/storage" "$BACKEND_DIR/bootstrap/cache"
as_root chmod -R ug+rw "$BACKEND_DIR/storage" "$BACKEND_DIR/bootstrap/cache"

if [[ -d "/var/lib/ustatop" ]]; then
  as_root chown -R "$WEB_GROUP:$WEB_GROUP" /var/lib/ustatop
fi

as_root systemctl reload "php${PHP_VERSION}-fpm" || true
as_root systemctl reload nginx || true
if as_root test -f /etc/systemd/system/ustatop-telegram-poll.service; then
  as_root systemctl restart ustatop-telegram-poll.service || true
fi

echo "Deploy muvaffaqiyatli yakunlandi."
