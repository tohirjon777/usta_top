#!/bin/bash

set -euo pipefail

HOST=""
USER_NAME=""
PORT="22"
FORWARDED_ARGS=()

usage() {
  cat <<'EOF'
Usage:
  ./remote_install.sh --host <IP_OR_DOMAIN> --user <SSH_USER> [bootstrap args...]

Examples:
  ./remote_install.sh \
    --host 203.0.113.10 \
    --user root \
    --repo-url git@github.com:org/repo.git \
    --app-url https://api.example.com \
    --db-password super-secret

  ./remote_install.sh \
    --host 203.0.113.10 \
    --user ubuntu \
    --repo-url https://github.com/org/repo.git \
    --app-url http://203.0.113.10 \
    --db-password super-secret \
    --skip-ssl
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --host)
      HOST="${2:-}"
      shift 2
      ;;
    --user)
      USER_NAME="${2:-}"
      shift 2
      ;;
    --port)
      PORT="${2:-}"
      shift 2
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      FORWARDED_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$HOST" || -z "$USER_NAME" ]]; then
  echo "--host va --user majburiy." >&2
  usage >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_SCRIPT="$SCRIPT_DIR/bootstrap_ubuntu.sh"

escaped_args=""
for arg in "${FORWARDED_ARGS[@]}"; do
  escaped_args+=" $(printf '%q' "$arg")"
done

remote_command="bash -s --$escaped_args"
if [[ "$USER_NAME" != "root" ]]; then
  remote_command="sudo $remote_command"
fi

ssh -p "$PORT" -o StrictHostKeyChecking=accept-new "$USER_NAME@$HOST" "$remote_command" < "$BOOTSTRAP_SCRIPT"
