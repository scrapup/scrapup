#!/usr/bin/env bash

# Executa npm install (puro, sem --legacy-peer-deps).
# Classifica o tipo de falha pelo output.
#
# Exit codes:
#   0 — sucesso
#   1 — conflito de versão / peer deps (output contém detalhes)
#   2 — outra falha (rede, registry, permissões)

CLAUDE_ENV="$HOME/.claude/.env"
[ -z "${NPM_TOKEN:-}" ] && [ -f "$CLAUDE_ENV" ] && . "$CLAUDE_ENV"
export NPM_TOKEN="${NPM_TOKEN:-}"

PROJECT_DIR="${1:-.}"

cd "$PROJECT_DIR"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -f .nvmrc ] && nvm use >/dev/null 2>&1 || true

output=$(npm install 2>&1)
exit_code=$?

if [ "$exit_code" -eq 0 ]; then
  echo "NPM_INSTALL_STATUS=ok"
  exit 0
fi

if echo "$output" | grep -qiE 'ERESOLVE|peer dep|engine|could not resolve'; then
  echo "NPM_INSTALL_STATUS=conflict"
  echo "$output"
  exit 1
fi

echo "NPM_INSTALL_STATUS=failed"
echo "$output"
exit 2
