#!/usr/bin/env bash
set -euo pipefail

# Verifica se NPM_TOKEN está disponível no ambiente.
#
# Exit codes:
#   0 — NPM_TOKEN definido
#   1 — NPM_TOKEN ausente

CLAUDE_ENV="$HOME/.claude/.env"
[ -z "${NPM_TOKEN:-}" ] && [ -f "$CLAUDE_ENV" ] && . "$CLAUDE_ENV"

if [ -n "${NPM_TOKEN:-}" ]; then
  echo "NPM_TOKEN_STATUS=available"
  exit 0
fi

echo "NPM_TOKEN_STATUS=missing"
exit 1
