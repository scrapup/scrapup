#!/usr/bin/env bash
# detect-docker-dependency.sh — helper que decide se o projeto depende de Docker
# para executar testes.
#
# Heuristica dupla (RN-42 extraida de classify-project.sh):
# (a) Arquivo docker-compose.yml|yaml|compose.yml|compose.yaml presente na raiz
# (b) Algum script em package.json referencia "docker compose" ou "docker-compose"
#     ou "docker run".
#
# Retorna "true" (depende) ou "false". Se apenas (a) for verdadeiro, registra
# observacao (no stderr) mas retorna "false" para evitar falso positivo.
#
# Uso:
#   detect-docker-dependency.sh <project_path>

set -euo pipefail

project_path="${1:-.}"

compose_present=false
for f in "$project_path/docker-compose.yml" "$project_path/docker-compose.yaml" \
         "$project_path/compose.yml" "$project_path/compose.yaml"; do
  if [ -f "$f" ]; then
    compose_present=true
    break
  fi
done

scripts_reference_docker=false
if [ -f "$project_path/package.json" ] && command -v jq >/dev/null 2>&1; then
  if jq -r '.scripts // {} | to_entries[] | .value' "$project_path/package.json" 2>/dev/null \
    | grep -Eq '(docker compose|docker-compose|docker run)'; then
    scripts_reference_docker=true
  fi
fi

if [ "$compose_present" = true ] && [ "$scripts_reference_docker" = true ]; then
  printf 'true'
  exit 0
fi

if [ "$compose_present" = true ] && [ "$scripts_reference_docker" = false ]; then
  printf 'docker-compose presente mas scripts nao referenciam docker\n' >&2
fi

printf 'false'
