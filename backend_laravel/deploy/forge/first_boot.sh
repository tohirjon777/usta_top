#!/bin/bash

set -euo pipefail

BASE_DIR="/var/lib/ustatop"

sudo mkdir -p "$BASE_DIR/data" \
  "$BASE_DIR/storage" \
  "$BASE_DIR/workshop-images"

sudo chown -R forge:forge "$BASE_DIR"
sudo chmod -R 775 "$BASE_DIR"

echo "Prepared directories:"
echo "  $BASE_DIR/data"
echo "  $BASE_DIR/storage"
echo "  $BASE_DIR/workshop-images"
