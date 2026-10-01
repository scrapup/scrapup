#!/usr/bin/env bash
set -uo pipefail

# Updates the Node.js version in the existing .nvmrc and Dockerfile(s), then
# runs nvm install/use. Run ONLY after the user explicitly approved the version.
#
# Usage: update-node-version.sh <version> [project-dir]
# Exit codes:
#   0 — files updated and nvm on the new version
#   1 — version missing or invalid (expected e.g. 20, 20.11, 20.11.1, v20.11.1)
#   2 — nothing updated (no .nvmrc and no Dockerfile with `FROM node:<version>`)
#   3 — files updated but nvm not found
#   4 — files updated but nvm install/use failed

NEW_VERSION="${1:-}"
PROJECT_DIR="${2:-.}"

if ! printf '%s' "$NEW_VERSION" | grep -qE '^v?[0-9]+(\.[0-9]+){0,2}$'; then
  echo "Usage: $0 <version> [project-dir]"
  exit 1
fi

# Dockerfile tags never carry the leading "v".
IMAGE_VERSION="${NEW_VERSION#v}"
updated=0

nvmrc="${PROJECT_DIR}/.nvmrc"
if [ -f "$nvmrc" ]; then
  echo "$NEW_VERSION" > "$nvmrc"
  echo "UPDATED=nvmrc"
  updated=1
fi

for name in Dockerfile Dockerfile.prod Dockerfile.deploy Dockerfile.production; do
  dockerfile="${PROJECT_DIR}/${name}"
  if [ -f "$dockerfile" ] && grep -qiE '^FROM[[:space:]]+node:[0-9]' "$dockerfile"; then
    sed -i.bak -E "s/^([Ff][Rr][Oo][Mm][[:space:]]+node:)[0-9]+(\.[0-9]+)*/\1${IMAGE_VERSION}/" "$dockerfile" \
      && rm -f "${dockerfile}.bak"
    echo "UPDATED=dockerfile:${dockerfile}"
    updated=1
  fi
done

if [ "$updated" -eq 0 ]; then
  echo "NO_FILES_UPDATED=true"
  exit 2
fi

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  echo "NVM_STATUS=not_found"
  exit 3
fi

# shellcheck source=/dev/null
. "$NVM_DIR/nvm.sh"
cd "$PROJECT_DIR" || exit 4
if ! nvm install "$NEW_VERSION" || ! nvm use "$NEW_VERSION"; then
  echo "NVM_STATUS=failed"
  exit 4
fi

echo "NODE_VERSION=$(node --version)"
exit 0
