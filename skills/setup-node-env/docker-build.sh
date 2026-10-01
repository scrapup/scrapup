#!/usr/bin/env bash
set -uo pipefail

# Builds the project's Dockerfile with BuildKit. When NPM_TOKEN is set, it is
# passed as a BuildKit secret (never as a build-arg, which would leak it into
# the image history). The Dockerfile must consume it with:
#   RUN --mount=type=secret,id=npm_token NPM_TOKEN="$(cat /run/secrets/npm_token)" npm ci
#
# Usage: docker-build.sh [project-dir]
# Exit codes:
#   0 — build OK
#   1 — Dockerfile not found
#   2 — the Dockerfile mounts the npm_token secret but NPM_TOKEN is not set
#   3 — docker build failed

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

secret_args=()
if [ -n "${NPM_TOKEN:-}" ]; then
  secret_args=(--secret "id=npm_token,env=NPM_TOKEN")
elif grep -qE 'id=npm_token' "$dockerfile"; then
  echo "DOCKER_BUILD_STATUS=no_npm_token"
  exit 2
fi

echo "Building ${dockerfile}..."
if DOCKER_BUILDKIT=1 docker build ${secret_args[@]+"${secret_args[@]}"} -f "$dockerfile" "$PROJECT_DIR"; then
  echo "DOCKER_BUILD_STATUS=ok"
  exit 0
fi

echo "DOCKER_BUILD_STATUS=failed"
exit 3
