#!/bin/bash

set -euo pipefail

APP_URL=""
REPO_URL=""
BRANCH="main"
APP_DIR="/var/www/ustatop"
DATA_DIR="/var/lib/ustatop"
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
PHP_VERSION="8.3"
APP_OWNER=""
WEB_GROUP="www-data"
CERTBOT_EMAIL=""
SKIP_SSL=0

usage() {
  cat <<'EOF'
Usage:
  ./bootstrap_ubuntu.sh --repo-url <REPO_URL> --app-url <APP_URL> --db-password <PASSWORD> [options]

Required:
  --repo-url URL       Git clone URL of the project
  --app-url URL        Public app URL, e.g. https://api.example.com or http://1.2.3.4
  --db-password PASS   PostgreSQL password for the app user

Optional:
  --branch NAME        Git branch to deploy (default: main)
  --app-dir DIR        Repo root on VPS (default: /var/www/ustatop)
  --data-dir DIR       Persistent data root (default: /var/lib/ustatop)
  --db-host HOST       PostgreSQL host (default: 127.0.0.1)
  --db-port PORT       PostgreSQL port (default: 5432)
  --db-name NAME       PostgreSQL database name (default: ustatop)
  --db-user USER       PostgreSQL username (default: ustatop)
  --admin-user USER    Admin username (default: admin)
  --admin-password PW  Admin password (auto-generated if omitted)
  --telegram-token T   Telegram bot token
  --sms-driver DRIVER  SMS driver (default: devsms)
  --sms-base-url URL   SMS API base URL
  --sms-token TOKEN    SMS bearer token
  --sms-service NAME   SMS service name
  --queue NAME         Laravel queue connection (default: sync)
  --php-version VER    PHP version to install/use (default: 8.3)
  --app-owner USER     File owner for deployed app (default: sudo user)
  --certbot-email EM   Email for certbot SSL
  --skip-ssl           Skip certbot SSL setup
  --help               Show this help
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-url)
      REPO_URL="${2:-}"
      shift 2
      ;;
    --app-url)
      APP_URL="${2:-}"
      shift 2
      ;;
    --branch)
      BRANCH="${2:-}"
      shift 2
      ;;
    --app-dir)
      APP_DIR="${2:-}"
      shift 2
      ;;
    --data-dir)
      DATA_DIR="${2:-}"
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
    --php-version)
      PHP_VERSION="${2:-}"
      shift 2
      ;;
    --app-owner)
      APP_OWNER="${2:-}"
      shift 2
      ;;
    --certbot-email)
      CERTBOT_EMAIL="${2:-}"
      shift 2
      ;;
    --skip-ssl)
      SKIP_SSL=1
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

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  echo "Bu script sudo/root bilan ishga tushirilishi kerak." >&2
  exit 1
fi

if [[ -z "$REPO_URL" || -z "$APP_URL" || -z "$DB_PASSWORD" ]]; then
  echo "--repo-url, --app-url va --db-password majburiy." >&2
  usage >&2
  exit 1
fi

if [[ -z "$APP_OWNER" ]]; then
  APP_OWNER="${SUDO_USER:-$(logname 2>/dev/null || echo root)}"
fi

if [[ ! "$APP_URL" =~ ^https?:// ]]; then
  APP_URL="https://$APP_URL"
fi

SERVER_NAME="${APP_URL#*://}"
SERVER_NAME="${SERVER_NAME%%/*}"
SERVER_NAME="${SERVER_NAME%%:*}"
BACKEND_DIR="$APP_DIR/backend_laravel"
PHP_FPM_SERVICE="php${PHP_VERSION}-fpm"
PHP_FPM_SOCKET="/run/php/php${PHP_VERSION}-fpm.sock"

if [[ -z "$SERVER_NAME" ]]; then
  echo "APP_URL hostini aniqlab bo'lmadi: $APP_URL" >&2
  exit 1
fi

apt-get update
apt-get install -y \
  nginx \
  git \
  unzip \
  curl \
  postgresql \
  postgresql-contrib \
  "php${PHP_VERSION}" \
  "php${PHP_VERSION}-fpm" \
  "php${PHP_VERSION}-cli" \
  "php${PHP_VERSION}-mbstring" \
  "php${PHP_VERSION}-xml" \
  "php${PHP_VERSION}-curl" \
  "php${PHP_VERSION}-zip" \
  "php${PHP_VERSION}-bcmath" \
  "php${PHP_VERSION}-intl" \
  "php${PHP_VERSION}-pgsql" \
  composer

mkdir -p "$APP_DIR" "$DATA_DIR/data" "$DATA_DIR/storage" "$DATA_DIR/workshop-images"
chown -R "$APP_OWNER:$WEB_GROUP" "$APP_DIR" "$DATA_DIR"
chmod -R 775 "$DATA_DIR"

systemctl enable --now postgresql
systemctl enable --now "$PHP_FPM_SERVICE"
systemctl enable --now nginx

sudo -u postgres psql \
  --set=db_name="$DB_NAME" \
  --set=db_user="$DB_USER" \
  --set=db_password="$DB_PASSWORD" <<'SQL'
DO $do$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = :'db_user') THEN
    EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', :'db_user', :'db_password');
  ELSE
    EXECUTE format('ALTER ROLE %I LOGIN PASSWORD %L', :'db_user', :'db_password');
  END IF;
END
$do$;

DO $do$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = :'db_name') THEN
    EXECUTE format('CREATE DATABASE %I OWNER %I', :'db_name', :'db_user');
  END IF;
END
$do$;
SQL

sudo -u postgres psql \
  --set=db_name="$DB_NAME" \
  --set=db_user="$DB_USER" <<'SQL'
SELECT format('GRANT ALL PRIVILEGES ON DATABASE %I TO %I', :'db_name', :'db_user') \gexec
SQL

if [[ ! -d "$APP_DIR/.git" ]]; then
  rm -rf "$APP_DIR"
  git clone --branch "$BRANCH" "$REPO_URL" "$APP_DIR"
else
  git -C "$APP_DIR" fetch origin "$BRANCH" --prune
  git -C "$APP_DIR" checkout "$BRANCH"
  git -C "$APP_DIR" pull --ff-only origin "$BRANCH"
fi

cd "$BACKEND_DIR"

env_args=(
  --app-url "$APP_URL"
  --db-host "$DB_HOST"
  --db-port "$DB_PORT"
  --db-name "$DB_NAME"
  --db-user "$DB_USER"
  --db-password "$DB_PASSWORD"
  --admin-user "$ADMIN_USER"
  --sms-driver "$SMS_DRIVER"
  --sms-base-url "$SMS_BASE_URL"
  --sms-service "$SMS_SERVICE_NAME"
  --queue "$QUEUE_CONNECTION"
)

if [[ -n "$ADMIN_PASSWORD" ]]; then
  env_args+=(--admin-password "$ADMIN_PASSWORD")
fi

if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
  env_args+=(--telegram-token "$TELEGRAM_BOT_TOKEN")
fi

if [[ -n "$SMS_BEARER_TOKEN" ]]; then
  env_args+=(--sms-token "$SMS_BEARER_TOKEN")
fi

./deploy/forge/generate_env.sh "${env_args[@]}" > .env

cat > /etc/nginx/sites-available/ustatop <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name $SERVER_NAME;

    root $BACKEND_DIR/public;
    index index.php index.html;

    client_max_body_size 20m;

    access_log /var/log/nginx/ustatop.access.log;
    error_log /var/log/nginx/ustatop.error.log warn;

    add_header X-Frame-Options SAMEORIGIN;
    add_header X-Content-Type-Options nosniff;

    location / {
        try_files \$uri \$uri/ /index.php?\$query_string;
    }

    location = /favicon.ico {
        access_log off;
        log_not_found off;
    }

    location = /robots.txt {
        access_log off;
        log_not_found off;
    }

    location ~ \.php$ {
        include snippets/fastcgi-php.conf;
        fastcgi_pass unix:$PHP_FPM_SOCKET;
        fastcgi_param SCRIPT_FILENAME \$realpath_root\$fastcgi_script_name;
        fastcgi_param DOCUMENT_ROOT \$realpath_root;
        fastcgi_read_timeout 120s;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

ln -sfn /etc/nginx/sites-available/ustatop /etc/nginx/sites-enabled/ustatop
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl reload nginx

cat > /etc/systemd/system/ustatop-telegram-poll.service <<EOF
[Unit]
Description=Usta Top Telegram Poller
After=network.target
Wants=network.target

[Service]
Type=simple
User=$WEB_GROUP
Group=$WEB_GROUP
WorkingDirectory=$BACKEND_DIR
Environment=APP_ENV=production
ExecStart=/usr/bin/php artisan ustatop:telegram-poll
Restart=always
RestartSec=5
TimeoutStopSec=20
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
if [[ -n "$TELEGRAM_BOT_TOKEN" ]]; then
  systemctl enable --now ustatop-telegram-poll.service
else
  systemctl disable --now ustatop-telegram-poll.service || true
fi

./deploy/vps/deploy.sh \
  --app-dir "$APP_DIR" \
  --repo-url "$REPO_URL" \
  --branch "$BRANCH" \
  --php-version "$PHP_VERSION" \
  --app-owner "$APP_OWNER" \
  --web-group "$WEB_GROUP" \
  --skip-repo-pull

if [[ "$SKIP_SSL" -eq 0 && "$APP_URL" =~ ^https:// && ! "$SERVER_NAME" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  if [[ -n "$CERTBOT_EMAIL" ]]; then
    apt-get install -y certbot python3-certbot-nginx
    certbot --nginx --non-interactive --agree-tos -m "$CERTBOT_EMAIL" -d "$SERVER_NAME" || true
  else
    echo "Certbot o'tkazib yuborildi: --certbot-email berilmagan."
  fi
fi

echo
echo "VPS tayyor."
echo "App URL: $APP_URL"
echo "Repo: $APP_DIR"
echo "Backend: $BACKEND_DIR"
