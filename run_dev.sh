#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"

BIND_HOST="0.0.0.0"
PORT="8080"
API_BASE_URL=""
USE_ANDROID_EMULATOR=0
SKIP_PUB_GET=0
BACKEND_ONLY=0
FLUTTER_ARGS=()

usage() {
  cat <<'EOF'
Usage:
  ./run_dev.sh [options] [-- flutter_run_args...]

Options:
  --android-emulator   App uchun API URL'ni http://10.0.2.2:<port> qiladi
  --api-base-url URL   App uchun custom API URL beradi
  --bind-host HOST     Backend bind hosti (default: 0.0.0.0)
  --port PORT          Backend porti (default: 8080)
  --skip-pub-get       `flutter pub get` va `dart pub get` ni o'tkazib yuboradi
  --backend-only       Faqat backendni ishga tushiradi
  --help               Yordamni ko'rsatadi

Examples:
  ./run_dev.sh
  TELEGRAM_BOT_TOKEN=... ./run_dev.sh
  ./run_dev.sh -- --device-id chrome
  ./run_dev.sh --android-emulator -- -d emulator-5554
  ./run_dev.sh --api-base-url http://192.168.100.25:8080 -- -d RMX1234
EOF
}

while (($# > 0)); do
  case "$1" in
    --android-emulator)
      USE_ANDROID_EMULATOR=1
      shift
      ;;
    --api-base-url)
      API_BASE_URL="${2:-}"
      shift 2
      ;;
    --bind-host)
      BIND_HOST="${2:-}"
      shift 2
      ;;
    --port)
      PORT="${2:-}"
      shift 2
      ;;
    --skip-pub-get)
      SKIP_PUB_GET=1
      shift
      ;;
    --backend-only)
      BACKEND_ONLY=1
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

if [[ -z "$API_BASE_URL" ]]; then
  if [[ "$USE_ANDROID_EMULATOR" -eq 1 ]]; then
    API_BASE_URL="http://10.0.2.2:$PORT"
  else
    API_BASE_URL="http://127.0.0.1:$PORT"
  fi
fi

REQUIRED_COMMANDS=(dart curl)

if [[ "$BACKEND_ONLY" -eq 0 ]]; then
  REQUIRED_COMMANDS+=(flutter)
fi

for required_command in "${REQUIRED_COMMANDS[@]}"; do
  if ! command -v "$required_command" >/dev/null 2>&1; then
    printf 'Missing required command: %s\n' "$required_command" >&2
    exit 1
  fi
done

if [[ "$SKIP_PUB_GET" -eq 0 ]]; then
  printf 'Installing backend packages...\n'
  (
    cd "$BACKEND_DIR"
    dart pub get
  )

  if [[ "$BACKEND_ONLY" -eq 0 ]]; then
    printf 'Installing Flutter packages...\n'
    (
      cd "$ROOT_DIR"
      flutter pub get
    )
  fi
fi

BACKEND_PID=""
BACKEND_STARTED_BY_SCRIPT=0

cleanup() {
  if [[ "$BACKEND_STARTED_BY_SCRIPT" -eq 1 ]] && [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    printf '\nStopping backend...\n'
    kill "$BACKEND_PID" >/dev/null 2>&1 || true
    wait "$BACKEND_PID" 2>/dev/null || true
  fi
}

trap cleanup EXIT INT TERM

if curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
  printf 'Existing backend detected on http://127.0.0.1:%s, reusing it.\n' "$PORT"
else
  printf 'Starting backend on http://127.0.0.1:%s ...\n' "$PORT"
  (
    cd "$BACKEND_DIR"
    HOST="$BIND_HOST" PORT="$PORT" dart run bin/server.dart
  ) &
  BACKEND_PID="$!"
  BACKEND_STARTED_BY_SCRIPT=1

  for _ in $(seq 1 60); do
    if curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
      break
    fi

    if ! kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
      printf 'Backend ishga tushmay qoldi.\n' >&2
      wait "$BACKEND_PID"
      exit 1
    fi

    sleep 1
  done
fi

if ! curl -fsS "http://127.0.0.1:$PORT/health" >/dev/null 2>&1; then
  printf "Backend health tekshiruvdan o'tmadi: http://127.0.0.1:%s/health\n" "$PORT" >&2
  exit 1
fi

printf 'Backend tayyor.\n'
printf 'Admin panel: http://127.0.0.1:%s/admin/login\n' "$PORT"
printf 'Owner panel: http://127.0.0.1:%s/owner/login\n' "$PORT"

if [[ "$BACKEND_ONLY" -eq 1 ]]; then
  if [[ "$BACKEND_STARTED_BY_SCRIPT" -eq 1 ]]; then
    printf "Backend-only mode. To'xtatish uchun Ctrl+C bosing.\n"
    wait "$BACKEND_PID"
  else
    printf "Backend-only mode: mavjud backend ishlayapti, hech narsa ishga tushirilmadi.\n"
  fi
  exit 0
fi

printf 'Flutter app ishga tushmoqda...\n'
printf 'API_BASE_URL=%s\n' "$API_BASE_URL"

cd "$ROOT_DIR"
flutter run \
  --dart-define=USE_BACKEND=true \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  "${FLUTTER_ARGS[@]}"
