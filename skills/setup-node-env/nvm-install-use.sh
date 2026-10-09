#!/usr/bin/env bash
set -uo pipefail

# Loads nvm, then runs `nvm install` and `nvm use` from the project's .nvmrc.
#
# Usage: nvm-install-use.sh [project-dir]
# Exit codes:
#   0 — node is on the .nvmrc version
#   1 — nvm not found
#   2 — .nvmrc not found
#   3 — nvm install failed
#   4 — nvm use failed

PROJECT_DIR="${1:-.}"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
else
  echo "NVM_STATUS=not_found"
  exit 1
fi

if [[ ! -f "${PROJECT_DIR}/.nvmrc" ]]; then
  echo "NVM_STATUS=no_nvmrc"
  exit 2
fi

cd "$PROJECT_DIR" || { echo "NVM_STATUS=no_nvmrc"; exit 2; }

if ! nvm install 2>&1; then
  echo "NVM_STATUS=install_failed"
  exit 3
fi

if ! nvm use 2>&1; then
  echo "NVM_STATUS=use_failed"
  exit 4
fi

echo "NVM_STATUS=ok"
echo "NODE_VERSION=$(node --version)"
exit 0
