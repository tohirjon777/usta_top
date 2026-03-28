#!/bin/bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

printf 'Eslatma: alohida Laravel service script endi birlashtirilgan.\n'
exec "$ROOT_DIR/backend_service.sh" "$@"
