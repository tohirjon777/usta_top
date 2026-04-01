#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DAEMON_SCRIPT="$ROOT_DIR/tools/localhost_run_tunnel.py"
SERVICE_ROOT="$HOME/Library/Application Support/UstaTopBackend"
TUNNEL_DIR="$SERVICE_ROOT/tunnel"
PID_FILE="$TUNNEL_DIR/localhost-run.pid"
LOG_FILE="$TUNNEL_DIR/localhost-run.log"
URL_FILE="$TUNNEL_DIR/localhost-run.url"
LOCAL_URL="${LOCAL_URL:-http://127.0.0.1:8080}"
TUNNEL_PROCESS_PATTERN="ssh -tt -o StrictHostKeyChecking=no -o ExitOnForwardFailure=yes -o ServerAliveInterval=30 -R 80:127.0.0.1:8080 nokey@localhost.run"

usage() {
  cat <<'EOF'
Usage:
  ./backend_tunnel.sh start
  ./backend_tunnel.sh stop
  ./backend_tunnel.sh restart
  ./backend_tunnel.sh status
  ./backend_tunnel.sh url
  ./backend_tunnel.sh logs

Commands:
  start    Public tunnel yaratadi
  stop     Tunnelni to'xtatadi
  restart  Tunnelni qayta ishga tushiradi
  status   Tunnel holati va URL ni ko'rsatadi
  url      Faqat public URL ni ko'rsatadi
  logs     Tunnel loglarini ko'rsatadi
EOF
}

ensure_backend() {
  if curl -fsS "$LOCAL_URL/health" >/dev/null 2>&1; then
    return 0
  fi

  "$ROOT_DIR/backend_service.sh" start >/dev/null

  for _ in $(seq 1 20); do
    if curl -fsS "$LOCAL_URL/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  printf "Backend health tekshiruvdan o'tmadi: %s/health\n" "$LOCAL_URL" >&2
  exit 1
}

is_running() {
  local tunnel_pid=""
  tunnel_pid="$(resolve_tunnel_pid || true)"
  if [[ -n "$tunnel_pid" ]]; then
    printf '%s\n' "$tunnel_pid" > "$PID_FILE"
    return 0
  fi

  if [[ ! -f "$PID_FILE" ]]; then
    return 1
  fi

  local pid=""
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1
}

extract_url() {
  awk '/tunneled with tls termination/ {for (i = 1; i <= NF; i++) if ($i ~ /^https:\/\//) print $i}' "$LOG_FILE" 2>/dev/null | tail -n 1
}

resolve_tunnel_pid() {
  pgrep -f "$TUNNEL_PROCESS_PATTERN" | tail -n 1
}

write_url_file() {
  local url=""
  url="$(extract_url || true)"
  if [[ -n "$url" ]]; then
    printf '%s\n' "$url" > "$URL_FILE"
  fi
}

start_tunnel() {
  mkdir -p "$TUNNEL_DIR"
  ensure_backend

  if ! command -v python3 >/dev/null 2>&1; then
    printf 'python3 topilmadi.\n' >&2
    exit 1
  fi

  if is_running; then
    status_tunnel
    return 0
  fi

  rm -f "$LOG_FILE" "$URL_FILE"
  nohup python3 "$DAEMON_SCRIPT" \
    --local-url "$LOCAL_URL" \
    --log-file "$LOG_FILE" \
    --url-file "$URL_FILE" >/dev/null 2>&1 &
  local pid=$!
  printf '%s\n' "$pid" > "$PID_FILE"

  for _ in $(seq 1 30); do
    if ! kill -0 "$pid" >/dev/null 2>&1; then
      printf 'Tunnel process to‘xtab qoldi.\n' >&2
      tail -n 40 "$LOG_FILE" >&2 || true
      exit 1
    fi

    write_url_file
    if [[ -f "$URL_FILE" ]]; then
      local tunnel_pid=""
      tunnel_pid="$(resolve_tunnel_pid || true)"
      if [[ -n "$tunnel_pid" ]]; then
        printf '%s\n' "$tunnel_pid" > "$PID_FILE"
      fi
      printf 'Tunnel tayyor: %s\n' "$(cat "$URL_FILE")"
      return 0
    fi
    sleep 1
  done

  printf 'Tunnel URL olinmadi.\n' >&2
  tail -n 60 "$LOG_FILE" >&2 || true
  exit 1
}

stop_tunnel() {
  if ! is_running; then
    rm -f "$PID_FILE"
    pkill -f "$TUNNEL_PROCESS_PATTERN" >/dev/null 2>&1 || true
    return 0
  fi

  local pid=""
  pid="$(cat "$PID_FILE")"
  kill "$pid" >/dev/null 2>&1 || true
  pkill -f "$TUNNEL_PROCESS_PATTERN" >/dev/null 2>&1 || true
  rm -f "$PID_FILE"
}

status_tunnel() {
  if is_running; then
    write_url_file
    local pid=""
    pid="$(cat "$PID_FILE")"
    printf 'Tunnel running (pid=%s)\n' "$pid"
    if [[ -f "$URL_FILE" ]]; then
      printf 'Public URL: %s\n' "$(cat "$URL_FILE")"
    fi
  else
    printf 'Tunnel stopped\n'
  fi
}

show_url() {
  write_url_file
  if [[ -f "$URL_FILE" ]]; then
    cat "$URL_FILE"
    return 0
  fi
  printf 'Tunnel URL topilmadi\n' >&2
  exit 1
}

show_logs() {
  mkdir -p "$TUNNEL_DIR"
  touch "$LOG_FILE"
  tail -n 80 "$LOG_FILE"
}

case "${1:-}" in
  start)
    start_tunnel
    ;;
  stop)
    stop_tunnel
    ;;
  restart)
    stop_tunnel
    start_tunnel
    ;;
  status)
    status_tunnel
    ;;
  url)
    show_url
    ;;
  logs)
    show_logs
    ;;
  *)
    usage
    exit 1
    ;;
esac
