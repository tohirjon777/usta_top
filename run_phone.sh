#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PORT="8080"
DEVICE_ID=""
API_BASE_URL=""
USE_ADB_REVERSE="auto"
SKIP_PUB_GET=0
FLUTTER_ARGS=()

usage() {
  cat <<'EOF'
Usage:
  ./run_phone.sh [options] [-- flutter_run_args...]

Options:
  --device-id ID         Android device serialini beradi
  --port PORT            Backend porti (default: 8080)
  --api-base-url URL     API URL'ni qo'lda beradi
  --adb-reverse          USB orqali adb reverse ishlatadi
  --wifi                 adb reverse ishlatmaydi, lokal IP orqali ulaydi
  --skip-pub-get         flutter pub get ni o'tkazib yuboradi
  --help                 Yordamni ko'rsatadi

Examples:
  ./run_phone.sh
  ./run_phone.sh --device-id R9JN50PWH2J
  ./run_phone.sh --wifi --device-id R9JN50PWH2J
  ./run_phone.sh -- --debug
EOF
}

while (($# > 0)); do
  case "$1" in
    --device-id)
      DEVICE_ID="${2:-}"
      shift 2
      ;;
    --port)
      PORT="${2:-}"
      shift 2
      ;;
    --api-base-url)
      API_BASE_URL="${2:-}"
      shift 2
      ;;
    --adb-reverse)
      USE_ADB_REVERSE="yes"
      shift
      ;;
    --wifi)
      USE_ADB_REVERSE="no"
      shift
      ;;
    --skip-pub-get)
      SKIP_PUB_GET=1
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    --)
      shift
      FLUTTER_ARGS=("$@")
      break
      ;;
    *)
      FLUTTER_ARGS+=("$1")
      shift
      ;;
  esac
done

find_adb() {
  if command -v adb >/dev/null 2>&1; then
    command -v adb
    return 0
  fi

  local candidates=(
    "${ANDROID_HOME:-}/platform-tools/adb"
    "${ANDROID_SDK_ROOT:-}/platform-tools/adb"
    "$HOME/Library/Android/sdk/platform-tools/adb"
  )

  local candidate=""
  for candidate in "${candidates[@]}"; do
    if [[ -n "$candidate" && -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
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

pick_android_device() {
  local adb_bin="$1"
  local devices_output=""
  devices_output="$("$adb_bin" devices | awk 'NR>1 && $2=="device" {print $1}')"

  if [[ -n "$DEVICE_ID" ]]; then
    printf '%s\n' "$DEVICE_ID"
    return 0
  fi

  local count=0
  local first=""
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    ((count += 1))
    if [[ -z "$first" ]]; then
      first="$line"
    fi
  done <<< "$devices_output"

  if [[ "$count" -eq 1 && -n "$first" ]]; then
    printf '%s\n' "$first"
  fi
}

if [[ "$SKIP_PUB_GET" -eq 0 ]]; then
  printf 'Installing Flutter packages...\n'
  (
    cd "$ROOT_DIR"
    flutter pub get
  )
fi

ensure_backend

ADB_BIN=""
if ADB_BIN="$(find_adb 2>/dev/null)"; then
  :
else
  ADB_BIN=""
fi

if [[ -z "$API_BASE_URL" ]]; then
  local_mode="wifi"

  if [[ "$USE_ADB_REVERSE" == "yes" && -n "$ADB_BIN" ]]; then
    DEVICE_FOR_REVERSE="$(pick_android_device "$ADB_BIN" || true)"
    if [[ -n "${DEVICE_FOR_REVERSE:-}" ]]; then
      if [[ -n "$DEVICE_FOR_REVERSE" ]]; then
        printf 'adb reverse yoqilmoqda: %s -> tcp:%s\n' "$DEVICE_FOR_REVERSE" "$PORT"
        "$ADB_BIN" -s "$DEVICE_FOR_REVERSE" reverse "tcp:$PORT" "tcp:$PORT" >/dev/null
        API_BASE_URL="http://127.0.0.1:$PORT"
        local_mode="adb-reverse"
      fi
    fi
  fi

  if [[ -z "$API_BASE_URL" ]]; then
    LAN_IP="$(detect_lan_ip)"
    if [[ -z "${LAN_IP:-}" ]]; then
      printf "Lokal IP topilmadi. --api-base-url bilan qo'lda bering.\n" >&2
      exit 1
    fi
    API_BASE_URL="http://$LAN_IP:$PORT"
    local_mode="wifi"
  fi

  if [[ -z "$API_BASE_URL" && "$USE_ADB_REVERSE" == "auto" && -n "$ADB_BIN" ]]; then
    DEVICE_FOR_REVERSE="$(pick_android_device "$ADB_BIN" || true)"
    if [[ -n "${DEVICE_FOR_REVERSE:-}" ]]; then
      printf 'Wi-Fi topilmadi, adb reverse yoqilmoqda: %s -> tcp:%s\n' "$DEVICE_FOR_REVERSE" "$PORT"
      "$ADB_BIN" -s "$DEVICE_FOR_REVERSE" reverse "tcp:$PORT" "tcp:$PORT" >/dev/null
      API_BASE_URL="http://127.0.0.1:$PORT"
      local_mode="adb-reverse"
    fi
  fi

  if [[ -z "$API_BASE_URL" ]]; then
    printf "Telefon uchun backend manzili topilmadi. --api-base-url bilan qo'lda bering.\n" >&2
    exit 1
  fi

  printf 'Phone mode: %s\n' "$local_mode"
fi

printf 'Backend tayyor: http://127.0.0.1:%s/health\n' "$PORT"
printf 'API_BASE_URL=%s\n' "$API_BASE_URL"

RUN_ARGS=(
  "--dart-define=USE_BACKEND=true"
  "--dart-define=API_BASE_URL=$API_BASE_URL"
)

if [[ -n "$DEVICE_ID" ]]; then
  RUN_ARGS+=("-d" "$DEVICE_ID")
fi

cd "$ROOT_DIR"
CMD=(flutter run "${RUN_ARGS[@]}")
if ((${#FLUTTER_ARGS[@]} > 0)); then
  CMD+=("${FLUTTER_ARGS[@]}")
fi

"${CMD[@]}"
