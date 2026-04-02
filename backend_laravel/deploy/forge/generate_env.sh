#!/bin/bash

set -euo pipefail

DOMAIN=""
APP_KEY=""
DB_HOST="127.0.0.1"
DB_PORT="5432"
DB_NAME="ustatop"
DB_USER="ustatop"
DB_PASSWORD=""
ADMIN_USER="admin"
ADMIN_PASSWORD=""
TELEGRAM_BOT_TOKEN=""
SMS_DRIVER="devsms"
SMS_BASE_URL="https://devsms.uz/api"
SMS_BEARER_TOKEN=""
SMS_SERVICE_NAME="Usta Top"
QUEUE_CONNECTION="sync"

usage() {
  cat <<'EOF'
Usage:
  ./generate_env.sh --domain api.example.com --db-password secret [options]

Required:
  --domain           Production domain, e.g. api.example.com
  --db-password      PostgreSQL password

Optional:
  --app-key          Laravel APP_KEY (auto-generated if omitted)
  --db-host          PostgreSQL host (default: 127.0.0.1)
  --db-port          PostgreSQL port (default: 5432)
  --db-name          PostgreSQL database name (default: ustatop)
  --db-user          PostgreSQL username (default: ustatop)
  --admin-user       Admin username (default: admin)
  --admin-password   Admin password (auto-generated if omitted)
  --telegram-token   Telegram bot token
  --sms-driver       SMS driver (default: devsms)
  --sms-base-url     SMS base URL (default: https://devsms.uz/api)
  --sms-token        SMS bearer token
  --sms-service      SMS sender/service name (default: Usta Top)
  --queue            Queue connection (default: sync)
  --help             Show this help
EOF
}

generate_app_key() {
  php -r 'echo "base64:".base64_encode(random_bytes(32));'
}

generate_password() {
  php -r 'echo bin2hex(random_bytes(12));'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --domain)
      DOMAIN="${2:-}"
      shift 2
      ;;
    --app-key)
      APP_KEY="${2:-}"
      shift 2
      ;;
    --db-host)
      DB_HOST="${2:-}"
      shift 2
      ;;
    --db-port)
      DB_PORT="${2:-}"
      shift 2
      ;;
    --db-name)
      DB_NAME="${2:-}"
      shift 2
      ;;
    --db-user)
      DB_USER="${2:-}"
      shift 2
      ;;
    --db-password)
      DB_PASSWORD="${2:-}"
      shift 2
      ;;
    --admin-user)
      ADMIN_USER="${2:-}"
      shift 2
      ;;
    --admin-password)
      ADMIN_PASSWORD="${2:-}"
      shift 2
      ;;
    --telegram-token)
      TELEGRAM_BOT_TOKEN="${2:-}"
      shift 2
      ;;
    --sms-driver)
      SMS_DRIVER="${2:-}"
      shift 2
      ;;
    --sms-base-url)
      SMS_BASE_URL="${2:-}"
      shift 2
      ;;
    --sms-token)
      SMS_BEARER_TOKEN="${2:-}"
      shift 2
      ;;
    --sms-service)
      SMS_SERVICE_NAME="${2:-}"
      shift 2
      ;;
    --queue)
      QUEUE_CONNECTION="${2:-}"
      shift 2
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

if [[ -z "$DOMAIN" || -z "$DB_PASSWORD" ]]; then
  echo "Error: --domain and --db-password are required." >&2
  usage >&2
  exit 1
fi

if [[ -z "$APP_KEY" ]]; then
  APP_KEY="$(generate_app_key)"
fi

if [[ -z "$ADMIN_PASSWORD" ]]; then
  ADMIN_PASSWORD="$(generate_password)"
fi

cat <<EOF
APP_NAME="Usta Top"
APP_ENV=production
APP_KEY=$APP_KEY
APP_DEBUG=false
APP_URL=https://$DOMAIN

APP_LOCALE=en
APP_FALLBACK_LOCALE=en
APP_FAKER_LOCALE=en_US

LOG_CHANNEL=stack
LOG_STACK=single
LOG_LEVEL=warning

APP_MAINTENANCE_DRIVER=file

DB_CONNECTION=pgsql
DB_HOST=$DB_HOST
DB_PORT=$DB_PORT
DB_DATABASE=$DB_NAME
DB_USERNAME=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_SSLMODE=prefer

SESSION_DRIVER=file
SESSION_LIFETIME=120
SESSION_ENCRYPT=false
SESSION_PATH=/
SESSION_DOMAIN=null

CACHE_STORE=file
QUEUE_CONNECTION=$QUEUE_CONNECTION
FILESYSTEM_DISK=local

ADMIN_USERNAME=$ADMIN_USER
ADMIN_PASSWORD=$ADMIN_PASSWORD
TELEGRAM_BOT_TOKEN=$TELEGRAM_BOT_TOKEN

USTATOP_STORAGE_DRIVER=database
USTATOP_STORAGE_DB_CONNECTION=pgsql
USTATOP_STORAGE_DB_TABLE=ustatop_json_documents

USTATOP_DATA_DIR=/var/lib/ustatop/data
USTATOP_USERS_FILE=/var/lib/ustatop/data/users.json
USTATOP_WORKSHOPS_FILE=/var/lib/ustatop/data/workshops.json
USTATOP_BOOKINGS_FILE=/var/lib/ustatop/data/bookings.json
USTATOP_REVIEWS_FILE=/var/lib/ustatop/data/reviews.json
USTATOP_BOOKING_MESSAGES_FILE=/var/lib/ustatop/data/booking_messages.json
USTATOP_WORKSHOP_LOCATIONS_FILE=/var/lib/ustatop/data/workshop_locations.json
USTATOP_AUTH_SESSIONS_FILE=/var/lib/ustatop/storage/auth_sessions.json
USTATOP_SMS_VERIFICATIONS_FILE=/var/lib/ustatop/storage/sms_verifications.json
USTATOP_TELEGRAM_SYNC_STATE_FILE=/var/lib/ustatop/storage/telegram_sync_state.json
USTATOP_WORKSHOP_IMAGES_DIR=/var/lib/ustatop/workshop-images

SMS_DRIVER=$SMS_DRIVER
SMS_BASE_URL=$SMS_BASE_URL
SMS_BEARER_TOKEN=$SMS_BEARER_TOKEN
SMS_SERVICE_NAME="$SMS_SERVICE_NAME"
EOF
