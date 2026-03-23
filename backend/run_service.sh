#!/bin/bash

set -euo pipefail

BACKEND_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$BACKEND_DIR/.env.local"
LOG_DIR="$BACKEND_DIR/logs"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "$ENV_FILE"
  set +a
fi

mkdir -p "$LOG_DIR"

cd "$BACKEND_DIR"

if [[ ! -f ".dart_tool/package_config.json" ]]; then
  dart pub get
fi

exec dart run bin/server.dart
