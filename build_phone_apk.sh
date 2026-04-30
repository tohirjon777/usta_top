#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="8080"
API_BASE_URL=""
SKIP_PUB_GET=0
OUTPUT_PATH="$HOME/Downloads/AutoMaster-phone-debug.apk"

usage() {
  cat <<'EOF'
Usage:
  ./build_phone_apk.sh [options]

Options:
  --port PORT            Backend porti (default: 8080)
  --api-base-url URL     API URL'ni qo'lda beradi
  --output PATH          Tayyor APK'ni qayerga nusxalash
  --skip-pub-get         flutter pub get ni o'tkazib yuboradi
  --help                 Yordamni ko'rsatadi

Examples:
  ./build_phone_apk.sh
  ./build_phone_apk.sh --output ~/Downloads/AutoMaster.apk
  ./build_phone_apk.sh --api-base-url http://192.168.100.222:8080
EOF
}

while (($# > 0)); do
  case "$1" in
    --port)
      PORT="${2:-}"
      shift 2
      ;;
    --api-base-url)
      API_BASE_URL="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    --skip-pub-get)
      SKIP_PUB_GET=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      printf "Noma'lum parametr: %s\n" "$1" >&2
      usage
      exit 1
      ;;
  esac
done

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

ensure_backend() {
  if curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
    return 0
  fi

  printf 'Backend ishlamayapti, service qayta ishga tushiriladi...\n'
  "$ROOT_DIR/backend_service.sh" restart >/dev/null

  for _ in $(seq 1 20); do
    if curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done

  printf "Backend health tekshiruvdan o'tmadi: http://127.0.0.1:%s/health\n" "$PORT" >&2
  exit 1
}

if [[ "$SKIP_PUB_GET" -eq 0 ]]; then
  printf 'Installing Flutter packages...\n'
  (
    cd "$ROOT_DIR"
    flutter pub get
  )
fi

ensure_backend

if [[ -z "$API_BASE_URL" ]]; then
  LAN_IP="$(detect_lan_ip)"
  if [[ -z "${LAN_IP:-}" ]]; then
    printf "Lokal IP topilmadi. --api-base-url bilan qo'lda bering.\n" >&2
    exit 1
  fi
  API_BASE_URL="http://$LAN_IP:$PORT"
fi

printf 'APK uchun API_BASE_URL=%s\n' "$API_BASE_URL"

cd "$ROOT_DIR"
flutter build apk \
  --debug \
  --dart-define=USE_BACKEND=true \
  --dart-define=API_BASE_URL="$API_BASE_URL"

mkdir -p "$(dirname "$OUTPUT_PATH")"
cp "$ROOT_DIR/build/app/outputs/flutter-apk/app-debug.apk" "$OUTPUT_PATH"

printf 'APK tayyor: %s\n' "$OUTPUT_PATH"
