#!/usr/bin/env bash
set -euo pipefail

# Atualiza versão Node.js no .nvmrc e Dockerfile(s), executa nvm install/use.
#
# Uso: update-node-version.sh <versão> [diretório-projeto]
# Exit codes:
#   0 — arquivos atualizados e nvm na nova versão
#   1 — versão não informada
#   2 — nenhum arquivo encontrado para atualizar

NEW_VERSION="${1:-}"
PROJECT_DIR="${2:-.}"

if [ -z "$NEW_VERSION" ]; then
  echo "Uso: $0 <versão> [diretório-projeto]"
  exit 1
fi

updated=0

nvmrc="${PROJECT_DIR}/.nvmrc"
echo "$NEW_VERSION" > "$nvmrc"
echo "UPDATED=nvmrc"
updated=1

for name in Dockerfile Dockerfile.prod Dockerfile.deploy Dockerfile.production; do
  dockerfile="${PROJECT_DIR}/${name}"
  if [ -f "$dockerfile" ] && grep -qiE '^FROM\s+node:' "$dockerfile"; then
    sed -i '' -E "s/^(FROM\s+node:)[0-9]+(\.[0-9]+)*/\1${NEW_VERSION}/" "$dockerfile"
    echo "UPDATED=dockerfile:${dockerfile}"
    updated=1
  fi
done

if [ "$updated" -eq 0 ]; then
  echo "NO_FILES_UPDATED=true"
  exit 2
fi

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ -s "$NVM_DIR/nvm.sh" ]; then
  . "$NVM_DIR/nvm.sh"
  cd "$PROJECT_DIR"
  nvm install "$NEW_VERSION"
  nvm use "$NEW_VERSION"
  echo "NODE_VERSION=$(node --version)"
fi

exit 0
