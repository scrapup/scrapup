#!/usr/bin/env bash
set -euo pipefail

# Executa docker build do Dockerfile do projeto com NPM_TOKEN como build-arg.
#
# Exit codes:
#   0 — build OK
#   1 — Dockerfile não encontrado
#   2 — NPM_TOKEN não definido
#   3 — docker build falhou

CLAUDE_ENV="$HOME/.claude/.env"
[ -z "${NPM_TOKEN:-}" ] && [ -f "$CLAUDE_ENV" ] && . "$CLAUDE_ENV"

PROJECT_DIR="${1:-.}"

dockerfile=""
for name in Dockerfile Dockerfile.prod Dockerfile.deploy Dockerfile.production; do
  if [ -f "${PROJECT_DIR}/${name}" ]; then
    dockerfile="${PROJECT_DIR}/${name}"
    break
  fi
done

if [ -z "$dockerfile" ]; then
  echo "DOCKER_BUILD_STATUS=no_dockerfile"
  exit 1
fi

if [ -z "${NPM_TOKEN:-}" ]; then
  echo "DOCKER_BUILD_STATUS=no_npm_token"
  exit 2
fi

echo "Building ${dockerfile}..."
if docker build --build-arg NPM_TOKEN="${NPM_TOKEN}" -f "$dockerfile" "$PROJECT_DIR"; then
  echo "DOCKER_BUILD_STATUS=ok"
  exit 0
fi

echo "DOCKER_BUILD_STATUS=failed"
exit 3
