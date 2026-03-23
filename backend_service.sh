#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
PROJECT_ENV_FILE="$BACKEND_DIR/.env.local"
ENV_EXAMPLE_FILE="$BACKEND_DIR/.env.example"
SERVICE_ROOT="$HOME/Library/Application Support/UstaTopBackend"
RUNTIME_DIR="$SERVICE_ROOT/runtime"
ENV_FILE="$RUNTIME_DIR/.env.local"
LOG_DIR="$SERVICE_ROOT/logs"
PLIST_DIR="$HOME/Library/LaunchAgents"
PLIST_PATH="$PLIST_DIR/com.ustatop.backend.plist"
LABEL="com.ustatop.backend"
LAUNCH_DOMAIN="gui/$(id -u)"
OUT_LOG="$LOG_DIR/backend.out.log"
ERR_LOG="$LOG_DIR/backend.err.log"
HEALTH_URL="http://127.0.0.1:8080/health"

usage() {
  cat <<'EOF'
Usage:
  ./backend_service.sh install
  ./backend_service.sh start
  ./backend_service.sh stop
  ./backend_service.sh restart
  ./backend_service.sh status
  ./backend_service.sh logs
  ./backend_service.sh uninstall

Commands:
  install    LaunchAgent yaratadi va backendni avtomatik ishga tushiradi
  start      O'rnatilgan service'ni ishga tushiradi
  stop       Service'ni to'xtatadi
  restart    Service'ni qayta ishga tushiradi
  status     Service holatini ko'rsatadi
  logs       Backend loglarini ko'rsatadi
  uninstall  Service'ni o'chiradi
EOF
}

ensure_env_file() {
  if [[ -f "$PROJECT_ENV_FILE" ]]; then
    return
  fi

  cp "$ENV_EXAMPLE_FILE" "$PROJECT_ENV_FILE"
  printf 'Created %s\n' "$PROJECT_ENV_FILE"
}

sync_runtime() {
  mkdir -p "$RUNTIME_DIR" "$LOG_DIR"

  rsync -a --delete \
    --exclude '.dart_tool/' \
    --exclude 'build/' \
    --exclude 'logs/' \
    --exclude '.env.local' \
    --exclude 'data/' \
    "$BACKEND_DIR/" "$RUNTIME_DIR/"

  if [[ ! -d "$RUNTIME_DIR/data" ]]; then
    mkdir -p "$RUNTIME_DIR/data"
    rsync -a "$BACKEND_DIR/data/" "$RUNTIME_DIR/data/"
  fi

  if [[ -f "$PROJECT_ENV_FILE" ]]; then
    cp "$PROJECT_ENV_FILE" "$ENV_FILE"
  fi
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
  local attempts="${1:-8}"
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

install_service() {
  ensure_env_file
  sync_runtime
  write_plist

  launchctl bootout "$LAUNCH_DOMAIN" "$PLIST_PATH" >/dev/null 2>&1 || true
  launchctl bootstrap "$LAUNCH_DOMAIN" "$PLIST_PATH"
  launchctl enable "$LAUNCH_DOMAIN/$LABEL" >/dev/null 2>&1 || true
  launchctl kickstart -k "$LAUNCH_DOMAIN/$LABEL"
  wait_for_health 10 1 || true

  printf 'Backend service installed: %s\n' "$PLIST_PATH"
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
  wait_for_health 10 1 || true
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

show_status() {
  if is_loaded; then
    printf 'Service loaded: %s\n' "$LABEL"
    launchctl print "$LAUNCH_DOMAIN/$LABEL" | sed -n '1,40p'
    printf 'Runtime dir: %s\n' "$RUNTIME_DIR"
  else
    printf 'Service not loaded: %s\n' "$LABEL"
  fi

  if wait_for_health 5 1; then
    printf 'Health: %s OK\n' "$HEALTH_URL"
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
  printf 'Backend service removed: %s\n' "$PLIST_PATH"
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
