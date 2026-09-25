#!/usr/bin/env bash

# Carrega nvm, executa nvm install e nvm use a partir do .nvmrc.
#
# Exit codes:
#   0 — node na versão correta
#   1 — nvm não encontrado
#   2 — .nvmrc não encontrado
#   3 — nvm install falhou

PROJECT_DIR="${1:-.}"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
else
  echo "NVM_STATUS=not_found"
  exit 1
fi

if [ ! -f "${PROJECT_DIR}/.nvmrc" ]; then
  echo "NVM_STATUS=no_nvmrc"
  exit 2
fi

cd "$PROJECT_DIR"

if ! nvm install 2>&1; then
  echo "NVM_STATUS=install_failed"
  exit 3
fi

nvm use

echo "NVM_STATUS=ok"
echo "NODE_VERSION=$(node --version)"
exit 0
