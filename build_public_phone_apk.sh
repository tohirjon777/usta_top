#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_PATH="$HOME/Downloads/UstaTop-public-debug.apk"
SKIP_PUB_GET=0

usage() {
  cat <<'EOF'
Usage:
  ./build_public_phone_apk.sh [options]

Options:
  --output PATH          Tayyor APK'ni qayerga nusxalash
  --skip-pub-get         flutter pub get ni o'tkazib yuboradi
  --help                 Yordamni ko'rsatadi
EOF
}

while (($# > 0)); do
  case "$1" in
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

cd "$ROOT_DIR"
./backend_tunnel.sh start >/dev/null
PUBLIC_URL="$(./backend_tunnel.sh url | tr -d '\r\n')"

CMD=(
  ./build_phone_apk.sh
  --api-base-url "$PUBLIC_URL"
  --output "$OUTPUT_PATH"
)

if [[ "$SKIP_PUB_GET" -eq 1 ]]; then
  CMD+=(--skip-pub-get)
fi

"${CMD[@]}"

printf 'Public backend URL: %s\n' "$PUBLIC_URL"
