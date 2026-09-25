#!/usr/bin/env bash
# effective-category.sh — helper puro que recomputa category_effective (RN-27).
# Nunca persiste.
#
# Uso:
#   effective-category.sh <category> <environment_state> <docker_available>
#
# Regras:
# - category=indefinido ou vazia -> "null"
# - category=legado-docker-dependent + env_state=partial + docker=false -> legado-critico
# - caso contrario -> category

set -euo pipefail

CATEGORY="${1:-}"
ENV_STATE="${2:-ready}"
DOCKER_AVAILABLE="${3:-true}"

if [ -z "$CATEGORY" ] || [ "$CATEGORY" = "indefinido" ] || [ "$CATEGORY" = "null" ]; then
  printf 'null'
  exit 0
fi

if [ "$CATEGORY" = "legado-docker-dependent" ] && \
   [ "$ENV_STATE" = "partial" ] && \
   [ "$DOCKER_AVAILABLE" = "false" ]; then
  printf 'legado-critico'
  exit 0
fi

printf '%s' "$CATEGORY"
