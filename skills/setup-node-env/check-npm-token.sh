#!/usr/bin/env bash
set -euo pipefail

# Checks whether NPM_TOKEN is set in the current environment.
# Only relevant when the project installs packages from a private registry.
# The token is read from the environment only — never from a file.
#
# Exit codes:
#   0 — NPM_TOKEN is set
#   1 — NPM_TOKEN is missing

if [[ -n "${NPM_TOKEN:-}" ]]; then
  echo "NPM_TOKEN_STATUS=available"
  exit 0
fi

echo "NPM_TOKEN_STATUS=missing"
exit 1
