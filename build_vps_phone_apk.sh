#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_BASE_URL="${API_BASE_URL:-http://45.80.148.221}"
OUTPUT_PATH="$HOME/Downloads/UstaTop-vps-release.apk"
BUILD_MODE="release"
SKIP_PUB_GET=0
SKIP_HEALTH_CHECK=0

usage() {
  cat <<'EOF'
Usage:
  ./build_vps_phone_apk.sh [options]

Options:
  --api-base-url URL     VPS/API URL (default: http://45.80.148.221)
  --output PATH          Tayyor APK'ni qayerga nusxalash
  --debug                Debug APK yig'adi
  --release              Release APK yig'adi (default)
  --skip-pub-get         flutter pub get ni o'tkazib yuboradi
  --skip-health-check    Backend /health tekshiruvini o'tkazib yuboradi
  --help                 Yordamni ko'rsatadi
EOF
}

while (($# > 0)); do
  case "$1" in
    --api-base-url)
      API_BASE_URL="${2:-}"
      shift 2
      ;;
    --output)
      OUTPUT_PATH="${2:-}"
      shift 2
      ;;
    --debug)
      BUILD_MODE="debug"
      shift
      ;;
    --release)
      BUILD_MODE="release"
      shift
      ;;
    --skip-pub-get)
      SKIP_PUB_GET=1
      shift
      ;;
    --skip-health-check)
      SKIP_HEALTH_CHECK=1
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

API_BASE_URL="${API_BASE_URL%/}"
if [[ -z "$API_BASE_URL" ]]; then
  printf "API_BASE_URL bo'sh bo'lishi mumkin emas.\n" >&2
  exit 1
fi

if [[ "$SKIP_HEALTH_CHECK" -eq 0 ]]; then
  printf 'Backend tekshirilmoqda: %s/health\n' "$API_BASE_URL"
  curl -fsS "$API_BASE_URL/health" >/dev/null
fi

if [[ "$SKIP_PUB_GET" -eq 0 ]]; then
  printf 'Installing Flutter packages...\n'
  (
    cd "$ROOT_DIR"
    flutter pub get
  )
fi

printf 'APK uchun API_BASE_URL=%s\n' "$API_BASE_URL"
printf 'Build mode: %s\n' "$BUILD_MODE"

cd "$ROOT_DIR"
flutter build apk \
  "--$BUILD_MODE" \
  --dart-define=USE_BACKEND=true \
  --dart-define=API_BASE_URL="$API_BASE_URL"

mkdir -p "$(dirname "$OUTPUT_PATH")"
cp "$ROOT_DIR/build/app/outputs/flutter-apk/app-$BUILD_MODE.apk" "$OUTPUT_PATH"

printf 'APK tayyor: %s\n' "$OUTPUT_PATH"
