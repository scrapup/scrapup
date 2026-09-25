#!/usr/bin/env bash
set -euo pipefail

# Detecta versão Node.js a partir de .nvmrc ou Dockerfile do projeto.
#
# Saída (stdout): NODE_VERSION=<version> SOURCE=<nvmrc|dockerfile>
# Exit codes:
#   0 — versão encontrada
#   1 — nenhum .nvmrc nem Dockerfile encontrado
#   2 — Dockerfile encontrado mas versão Node não extraível

PROJECT_DIR="${1:-.}"

if [ -f "${PROJECT_DIR}/.nvmrc" ]; then
  version=$(tr -d '[:space:]' < "${PROJECT_DIR}/.nvmrc")
  echo "NODE_VERSION=${version}"
  echo "SOURCE=nvmrc"
  exit 0
fi

dockerfile=""
for name in Dockerfile Dockerfile.prod Dockerfile.deploy Dockerfile.production; do
  if [ -f "${PROJECT_DIR}/${name}" ]; then
    dockerfile="${PROJECT_DIR}/${name}"
    break
  fi
done

if [ -z "$dockerfile" ]; then
  echo "SOURCE=none"
  exit 1
fi

echo "DOCKERFILE=${dockerfile}"

version=$(grep -iE '^FROM\s+node:' "$dockerfile" | head -1 | sed -E 's/^FROM\s+node:([0-9]+(\.[0-9]+)*).*/\1/i' || true)

if [ -z "$version" ]; then
  echo "SOURCE=dockerfile"
  exit 2
fi

echo "NODE_VERSION=${version}"
echo "SOURCE=dockerfile"
exit 0
