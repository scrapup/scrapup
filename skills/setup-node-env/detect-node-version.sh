#!/usr/bin/env bash
set -euo pipefail

# Detects the project's Node.js version from .nvmrc or the Dockerfile.
#
# Usage: detect-node-version.sh [project-dir]
# Output (stdout, KEY=VALUE lines):
#   NODE_VERSION=<version>   only on exit 0
#   SOURCE=<nvmrc|dockerfile|none>
#   DOCKERFILE=<path>        whenever a Dockerfile was found (exit 0 via dockerfile, or exit 2)
# Exit codes:
#   0 — version found
#   1 — neither .nvmrc nor a Dockerfile found
#   2 — Dockerfile found but the Node version cannot be extracted

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

version=$(grep -iE '^FROM[[:space:]]+node:[0-9]' "$dockerfile" | head -1 | sed -E 's/^[Ff][Rr][Oo][Mm][[:space:]]+node:([0-9]+(\.[0-9]+)*).*/\1/' || true)

if [ -z "$version" ]; then
  echo "SOURCE=dockerfile"
  exit 2
fi

echo "NODE_VERSION=${version}"
echo "SOURCE=dockerfile"
exit 0
