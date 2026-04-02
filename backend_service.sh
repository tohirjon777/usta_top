#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend_laravel"
SOURCE_DATA_DIR="$BACKEND_DIR/data"
PROJECT_ENV_FILE="$BACKEND_DIR/.env.local"
SERVICE_ROOT="$HOME/Library/Application Support/UstaTopBackend"
RUNTIME_DIR="$SERVICE_ROOT/runtime"
DATA_DIR="$RUNTIME_DIR/data"
DATA_SEED_MARKER="$DATA_DIR/.seeded_from_project"
ENV_FILE="$RUNTIME_DIR/.env.local"
LOG_DIR="$SERVICE_ROOT/logs"
BACKUP_DIR="$SERVICE_ROOT/backups"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/com.ustatop.backend.plist"
LABEL="com.ustatop.backend"
LAUNCH_DOMAIN="gui/$(id -u)"
OUT_LOG="$LOG_DIR/backend.out.log"
ERR_LOG="$LOG_DIR/backend.err.log"
SERVICE_HOST="${SERVICE_HOST:-0.0.0.0}"
SERVICE_PORT="${SERVICE_PORT:-8080}"
HEALTH_URL="http://127.0.0.1:${SERVICE_PORT}/health"

usage() {
  cat <<'EOF'
Usage:
  ./backend_service.sh install
  ./backend_service.sh start
  ./backend_service.sh stop
  ./backend_service.sh restart
  ./backend_service.sh backup [backup_path]
  ./backend_service.sh backups
  ./backend_service.sh restore <backup_path>
  ./backend_service.sh status
  ./backend_service.sh logs
  ./backend_service.sh uninstall

Commands:
  install    LaunchAgent yaratadi va Laravel backendni avtomatik ishga tushiradi
  start      O'rnatilgan service'ni ishga tushiradi
  stop       Service'ni to'xtatadi
  restart    Service'ni qayta ishga tushiradi
  backup     Runtime SQLite bazaning backup nusxasini oladi
  backups    Olingan backup ro'yxatini ko'rsatadi
  restore    Backup fayldan SQLite bazani tiklaydi
  status     Service holatini ko'rsatadi
  logs       Backend loglarini ko'rsatadi
  uninstall  Service'ni o'chiradi
EOF
}

detect_lan_ip() {
  local default_interface=""
  default_interface="$(route -n get default 2>/dev/null | awk '/interface:/{print $2; exit}')"
  if [[ -n "$default_interface" ]]; then
    local iface_ip=""
    iface_ip="$(ipconfig getifaddr "$default_interface" 2>/dev/null || true)"
    if [[ -n "$iface_ip" ]]; then
      printf '%s\n' "$iface_ip"
      return 0
    fi
  fi

  ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2; exit}'
}

ensure_env_file() {
  if [[ -f "$PROJECT_ENV_FILE" ]]; then
    return
  fi

  touch "$PROJECT_ENV_FILE"
  printf 'Created %s\n' "$PROJECT_ENV_FILE"
}

sync_runtime() {
  mkdir -p "$RUNTIME_DIR" "$LOG_DIR" "$BACKUP_DIR" "$RUNTIME_DIR/storage/app/ustatop" "$RUNTIME_DIR/storage/logs" "$DATA_DIR"

  rsync -a --delete \
    --exclude 'vendor/' \
    --exclude 'node_modules/' \
    --exclude 'data/' \
    --exclude '.env' \
    --exclude '.env.local' \
    --exclude 'storage/logs/' \
    --exclude 'storage/app/ustatop/' \
    "$BACKEND_DIR/" "$RUNTIME_DIR/"

  rsync -a --ignore-existing "$SOURCE_DATA_DIR/" "$DATA_DIR/"
  touch "$DATA_SEED_MARKER"

  if [[ -f "$BACKEND_DIR/.env" ]]; then
    cp "$BACKEND_DIR/.env" "$RUNTIME_DIR/.env"
  fi

  if [[ -f "$PROJECT_ENV_FILE" ]]; then
    cp "$PROJECT_ENV_FILE" "$ENV_FILE"
  fi
}

resolve_backup_path() {
  local raw_path="${1:-}"
  if [[ -z "$raw_path" ]]; then
    printf '\n'
    return
  fi

  if [[ "$raw_path" == /* ]]; then
    printf '%s\n' "$raw_path"
    return
  fi

  if [[ -f "$BACKUP_DIR/$raw_path" ]]; then
    printf '%s\n' "$BACKUP_DIR/$raw_path"
    return
  fi

  printf '%s\n' "$ROOT_DIR/$raw_path"
}

runtime_env_value() {
  local key="$1"
  local source_file=""

  if [[ -f "$ENV_FILE" ]]; then
    source_file="$ENV_FILE"
  elif [[ -f "$RUNTIME_DIR/.env" ]]; then
    source_file="$RUNTIME_DIR/.env"
  fi

  if [[ -z "$source_file" ]]; then
    return 0
  fi

  awk -F= -v lookup_key="$key" '
    $1 == lookup_key {
      sub(/^[^=]+=*/, "", $0)
      gsub(/^"|"$/, "", $0)
      print $0
      exit
    }
  ' "$source_file"
}

write_plist() {
  mkdir -p "$PLIST_DIR" "$LOG_DIR"

  cat > "$PLIST_PATH" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$RUNTIME_DIR/run_service.sh</string>
  </array>
  <key>WorkingDirectory</key>
  <string>$RUNTIME_DIR</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>PATH</key>
    <string>$PATH</string>
    <key>HOME</key>
    <string>$HOME</string>
    <key>HOST</key>
    <string>$SERVICE_HOST</string>
    <key>PORT</key>
    <string>$SERVICE_PORT</string>
    <key>PHP_CLI_SERVER_WORKERS</key>
    <string>4</string>
    <key>USTATOP_USERS_FILE</key>
    <string>$DATA_DIR/users.json</string>
    <key>USTATOP_WORKSHOPS_FILE</key>
    <string>$DATA_DIR/workshops.json</string>
    <key>USTATOP_BOOKINGS_FILE</key>
    <string>$DATA_DIR/bookings.json</string>
    <key>USTATOP_REVIEWS_FILE</key>
    <string>$DATA_DIR/reviews.json</string>
    <key>USTATOP_BOOKING_MESSAGES_FILE</key>
    <string>$DATA_DIR/booking_messages.json</string>
    <key>USTATOP_WORKSHOP_LOCATIONS_FILE</key>
    <string>$DATA_DIR/workshop_locations.json</string>
    <key>USTATOP_AUTH_SESSIONS_FILE</key>
    <string>$RUNTIME_DIR/storage/app/ustatop/auth_sessions.json</string>
  </dict>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>StandardOutPath</key>
  <string>$OUT_LOG</string>
  <key>StandardErrorPath</key>
  <string>$ERR_LOG</string>
</dict>
</plist>
EOF
}

is_loaded() {
  launchctl print "$LAUNCH_DOMAIN/$LABEL" >/dev/null 2>&1
}

health_ready() {
  curl -fsS --max-time 2 "$HEALTH_URL" >/dev/null 2>&1
}

wait_for_health() {
  local attempts="${1:-12}"
  local delay_seconds="${2:-1}"
  local try=1

  while (( try <= attempts )); do
    if health_ready; then
      return 0
    fi
    sleep "$delay_seconds"
    ((try++))
  done

  return 1
}

print_failure_diagnostics() {
  printf 'Backend health tekshiruvdan o‘tmadi: %s\n' "$HEALTH_URL" >&2
  if [[ -f "$OUT_LOG" ]]; then
    printf '\nLast stdout lines:\n' >&2
    tail -n 20 "$OUT_LOG" >&2 || true
  fi
  if [[ -f "$ERR_LOG" ]]; then
    printf '\nLast stderr lines:\n' >&2
    tail -n 20 "$ERR_LOG" >&2 || true
  fi
}

install_service() {
  ensure_env_file
  sync_runtime
  write_plist

  launchctl bootout "$LAUNCH_DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
  launchctl bootstrap "$LAUNCH_DOMAIN" "$PLIST_PATH"
  launchctl enable "$LAUNCH_DOMAIN/$LABEL" >/dev/null 2>&1 || true
  launchctl kickstart -k "$LAUNCH_DOMAIN/$LABEL"
  if ! wait_for_health 20 1; then
    print_failure_diagnostics
    return 1
  fi

  printf 'Laravel backend service installed: %s\n' "$PLIST_PATH"
}

start_service() {
  if [[ ! -f "$PLIST_PATH" ]]; then
    install_service
    return
  fi

  ensure_env_file
  sync_runtime
  if ! is_loaded; then
    launchctl bootstrap "$LAUNCH_DOMAIN" "$PLIST_PATH"
  fi
  launchctl enable "$LAUNCH_DOMAIN/$LABEL" >/dev/null 2>&1 || true
  launchctl kickstart -k "$LAUNCH_DOMAIN/$LABEL"
  if ! wait_for_health 20 1; then
    print_failure_diagnostics
    return 1
  fi
}

stop_service() {
  launchctl bootout "$LAUNCH_DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
}

restart_service() {
  ensure_env_file
  sync_runtime
  if [[ -f "$PLIST_PATH" ]]; then
    write_plist
  fi
  stop_service
  start_service
}

backup_service() {
  ensure_env_file
  sync_runtime

  local requested_path="${1:-}"
  local backup_path
  if [[ -n "$requested_path" ]]; then
    backup_path="$(resolve_backup_path "$requested_path")"
  else
    backup_path="$BACKUP_DIR/ustatop-backup-$(date +%Y%m%d-%H%M%S).sqlite"
  fi

  (
    cd "$RUNTIME_DIR"
    php artisan ustatop:backup-storage --path="$backup_path"
  )
}

list_backups() {
  mkdir -p "$BACKUP_DIR"
  printf 'Backup dir: %s\n' "$BACKUP_DIR"
  find "$BACKUP_DIR" -maxdepth 1 -type f -name '*.sqlite' -print | sort
}

restore_service() {
  local requested_path="${1:-}"
  if [[ -z "$requested_path" ]]; then
    printf 'Backup fayl yo‘lini kiriting.\n' >&2
    exit 1
  fi

  local backup_path
  backup_path="$(resolve_backup_path "$requested_path")"
  if [[ ! -f "$backup_path" ]]; then
    printf 'Backup fayli topilmadi: %s\n' "$backup_path" >&2
    exit 1
  fi

  ensure_env_file
  sync_runtime
  stop_service
  (
    cd "$RUNTIME_DIR"
    php artisan ustatop:restore-storage "$backup_path" --force
  )
  start_service
}

show_status() {
  if is_loaded; then
    printf 'Service loaded: %s\n' "$LABEL"
    launchctl print "$LAUNCH_DOMAIN/$LABEL" | sed -n '1,40p'
    printf 'Runtime dir: %s\n' "$RUNTIME_DIR"
  else
    printf 'Service not loaded: %s\n' "$LABEL"
  fi

  if wait_for_health 6 1; then
    printf 'Health: %s OK\n' "$HEALTH_URL"
    local storage_driver=""
    storage_driver="$(runtime_env_value "USTATOP_STORAGE_DRIVER")"
    if [[ "$storage_driver" == "database" ]]; then
      local db_connection=""
      local db_table=""
      db_connection="$(runtime_env_value "USTATOP_STORAGE_DB_CONNECTION")"
      db_table="$(runtime_env_value "USTATOP_STORAGE_DB_TABLE")"
      [[ -z "$db_connection" ]] && db_connection="$(runtime_env_value "DB_CONNECTION")"
      [[ -z "$db_table" ]] && db_table="ustatop_json_documents"
      printf 'Storage: Database (%s:%s)\n' "${db_connection:-unknown}" "$db_table"
    else
      printf 'Storage: SQLite (%s)\n' "$RUNTIME_DIR/storage/app/ustatop/ustatop.sqlite"
    fi
    local lan_ip=""
    lan_ip="$(detect_lan_ip || true)"
    if [[ -n "$lan_ip" ]]; then
      printf 'LAN: http://%s:%s/health\n' "$lan_ip" "$SERVICE_PORT"
      printf 'Website: http://%s:%s/\n' "$lan_ip" "$SERVICE_PORT"
    fi
  else
    printf 'Health: backend javob bermayapti\n'
  fi
}

show_logs() {
  mkdir -p "$LOG_DIR"
  touch "$OUT_LOG" "$ERR_LOG"
  printf '==> %s <==\n' "$OUT_LOG"
  tail -n 40 "$OUT_LOG"
  printf '\n==> %s <==\n' "$ERR_LOG"
  tail -n 40 "$ERR_LOG"
}

uninstall_service() {
  stop_service
  rm -f "$PLIST_PATH"
  printf 'Laravel backend service removed: %s\n' "$PLIST_PATH"
}

case "${1:-}" in
  install)
    install_service
    ;;
  start)
    start_service
    ;;
  stop)
    stop_service
    ;;
  restart)
    restart_service
    ;;
  backup)
    backup_service "${2:-}"
    ;;
  backups)
    list_backups
    ;;
  restore)
    restore_service "${2:-}"
    ;;
  status)
    show_status
    ;;
  logs)
    show_logs
    ;;
  uninstall)
    uninstall_service
    ;;
  *)
    usage
    exit 1
    ;;
esac
