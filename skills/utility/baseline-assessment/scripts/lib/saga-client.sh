#!/usr/bin/env bash
# saga-client.sh — wrapper sobre cache-local.sh
#
# No modelo shell-first, cache-local e a camada primaria. Este wrapper
# expoe uma API semantica proxima da saga (project_ensure, note_upsert,
# note_list, note_search) para facilitar migracao futura: quando o
# o agente chamar a tool MCP para sincronizar, a ordem dos campos e
# titulos de notas ja respeita o contrato do mcp-saga.
#
# Funcoes publicas:
#   saga_project_name <project_path>           -> emite "test-config:<repo>"
#   saga_project_ensure <project_path>          -> cria arquivo cache se necessario
#   saga_note_upsert <project_path> <title> <type> <content_json> [--ws <path>]
#   saga_note_list <project_path> [--ws <path>] [--pattern <regex>]
#   saga_note_search <project_path> <query> [--ws <path>]
#   saga_note_get <project_path> <title> [--ws <path>]
#   saga_metrics_append <project_path> <entry_json>
#   saga_sync_pending <project_path>            -> retorna bool

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./cache-local.sh
. "$SCRIPT_DIR/cache-local.sh"

saga_project_name() {
  local project_path="${1:?project_path obrigatorio}"
  local repo_name=""
  if [ -d "$project_path/.git" ]; then
    local origin
    origin="$(cd "$project_path" && git config --get remote.origin.url 2>/dev/null || true)"
    if [ -n "$origin" ]; then
      repo_name="$(printf '%s' "$origin" | sed -E 's|.*[/:]([^/]+/[^/]+)(\.git)?$|\1|; s|\.git$||')"
      repo_name="$(printf '%s' "$repo_name" | sed -E 's|^[^/]+/||')"
    fi
  fi
  [ -z "$repo_name" ] && repo_name="$(cd "$project_path" && basename "$(pwd)")"
  printf 'test-config:%s' "$repo_name"
}

saga_project_ensure() {
  local project_path="${1:?project_path obrigatorio}"
  local project_name; project_name="$(saga_project_name "$project_path")"
  cache_init "$project_path" "$project_name" >/dev/null
  printf '%s' "$project_name"
}

saga_note_upsert() {
  # signature: <project_path> <title> <type> <content_json> [--ws <ws>]
  local project_path="${1:?}"
  local title="${2:?}"
  local note_type="${3:?}"
  local content_json="${4:?}"
  shift 4

  # Envolve content com metadados do saga (type, schema_version se ausente).
  local enriched
  enriched="$(printf '%s' "$content_json" | jq -c --arg t "$note_type" \
    'if type == "object" then . + {_note_type: $t} else {value: ., _note_type: $t} end
     | if has("schema_version") then . else . + {schema_version: 1} end')"

  cache_note_upsert "$project_path" "$title" "$enriched" "$@"
}

saga_note_list() {
  cache_note_list "$@"
}

saga_note_get() {
  cache_note_get "$@"
}

saga_note_search() {
  local project_path="${1:?}"
  local query="${2:?}"
  shift 2
  local workspace=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --ws) workspace="$2"; shift 2 ;;
      --ws=*) workspace="${1#*=}"; shift ;;
      *) shift ;;
    esac
  done
  # Busca textual simples no conteudo das notes.
  local list
  if [ -n "$workspace" ]; then
    list="$(cache_note_list "$project_path" --ws "$workspace")"
  else
    list="$(cache_note_list "$project_path")"
  fi
  printf '%s' "$list" | jq -c --arg q "$query" \
    'map(select((.title + " " + (.content | tostring)) | test($q; "i")))'
}

saga_metrics_append() {
  cache_metrics_append "$@"
}

saga_sync_pending() {
  cache_is_pending "$@"
}

# CLI
if [ "${BASH_SOURCE[0]:-$0}" = "${0}" ]; then
  cmd="${1:-help}"
  shift || true
  case "$cmd" in
    project-name)    saga_project_name "$@" ;;
    project-ensure)  saga_project_ensure "$@" ;;
    note-upsert)     saga_note_upsert "$@" ;;
    note-list)       saga_note_list "$@" ;;
    note-get)        saga_note_get "$@" ;;
    note-search)     saga_note_search "$@" ;;
    metrics-append)  saga_metrics_append "$@" ;;
    sync-pending)    saga_sync_pending "$@" ;;
    help|--help|-h)  sed -n '3,20p' "$0" ;;
    *)
      printf 'saga-client.sh: comando desconhecido: %s\n' "$cmd" >&2
      exit 3
      ;;
  esac
fi
