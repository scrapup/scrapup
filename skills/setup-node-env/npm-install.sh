#!/usr/bin/env bash
set -uo pipefail

# Runs a plain `npm install` (never --legacy-peer-deps) and classifies failures.
# NPM_TOKEN is read from the environment only; it is needed only when the
# project uses a private registry.
#
# Version-conflict criterion: the npm error code is ERESOLVE, or the install
# failed with an engine mismatch error (`code EBADENGINE` as an error, e.g.
# with engine-strict). `npm WARN EBADENGINE` warnings are NOT a conflict.
#
# Usage: npm-install.sh [project-dir]
# Exit codes:
#   0 — success
#   1 — version / peer dependency conflict (output follows)
#   2 — any other failure (network, registry, auth, permissions, bad project dir)

PROJECT_DIR="${1:-.}"

if ! cd "$PROJECT_DIR"; then
  echo "NPM_INSTALL_STATUS=failed"
  echo "Cannot enter project directory: ${PROJECT_DIR}"
  exit 2
fi

# Keep ${NPM_TOKEN} references in .npmrc resolvable even when no token is set.
export NPM_TOKEN="${NPM_TOKEN:-}"

export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  # shellcheck source=/dev/null
  . "$NVM_DIR/nvm.sh"
  if [[ -f .nvmrc ]]; then
    nvm use >/dev/null 2>&1 || true
  fi
fi

output=$(npm install 2>&1)
exit_code=$?

if [[ "$exit_code" -eq 0 ]]; then
  echo "NPM_INSTALL_STATUS=ok"
  exit 0
fi

if echo "$output" | grep -qE '^npm (ERR!|error) code (ERESOLVE|EBADENGINE)'; then
  echo "NPM_INSTALL_STATUS=conflict"
  echo "$output"
  exit 1
fi

echo "NPM_INSTALL_STATUS=failed"
echo "$output"
exit 2
