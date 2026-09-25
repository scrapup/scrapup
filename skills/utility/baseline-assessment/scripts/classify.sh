#!/usr/bin/env bash
# classify.sh — subcomando confirm para registrar categoria confirmada pelo
# desenvolvedor quando auto-classificacao foi indefinido (ou para sobrescrever
# manualmente).
#
# Subcomando:
#   confirm --category=<c> --reason=<r> [--project-path <p>] [--workspace <ws>]
#
# --category: saudavel|legado-estavel|legado-docker-dependent|legado-critico|sem-infra

set -euo pipefail

CLASSIFY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/saga-client.sh
. "$CLASSIFY_DIR/lib/saga-client.sh"

command -v jq >/dev/null 2>&1 || { printf 'classify.sh: jq ausente\n' >&2; exit 3; }

SUBCMD="${1:-}"
shift || true

PROJECT_PATH="."
WORKSPACE=""
CATEGORY=""
REASON=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --project-path=*) PROJECT_PATH="${1#*=}"; shift ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --workspace=*) WORKSPACE="${1#*=}"; shift ;;
    --category) CATEGORY="$2"; shift 2 ;;
    --category=*) CATEGORY="${1#*=}"; shift ;;
    --reason) REASON="$2"; shift 2 ;;
    --reason=*) REASON="${1#*=}"; shift ;;
    --help|-h) sed -n '2,15p' "$0"; exit 0 ;;
    *) printf 'classify.sh: flag desconhecida: %s\n' "$1" >&2; exit 1 ;;
  esac
done

_ws_arg() { [ -n "$WORKSPACE" ] && printf -- '--ws %s' "$WORKSPACE"; }

_valid_category() {
  case "$1" in
    saudavel|legado-estavel|legado-docker-dependent|legado-critico|sem-infra) return 0 ;;
    *) return 1 ;;
  esac
}

case "$SUBCMD" in
  confirm)
    if ! _valid_category "$CATEGORY"; then
      printf 'classify confirm: --category invalida (recebido: %s)\n' "$CATEGORY" >&2
      exit 1
    fi
    if [ -z "$REASON" ]; then
      printf 'classify confirm: --reason obrigatorio\n' >&2
      exit 1
    fi

    saga_project_ensure "$PROJECT_PATH" >/dev/null
    NOW="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

    CONFIRM_CONTENT="$(jq -nc \
      --arg category "$CATEGORY" \
      --arg reason "$REASON" \
      --arg now "$NOW" \
      '{schema_version:1, category_confirmed: $category, reason: $reason, confirmed_at: $now}')"
    saga_note_upsert "$PROJECT_PATH" "category-confirmation" "context" "$CONFIRM_CONTENT" $(_ws_arg)

    # Atualiza baseline-category se existir (classified_by=user-confirmed)
    EXISTING_CAT="$(saga_note_get "$PROJECT_PATH" "baseline-category" $(_ws_arg) | jq -c '.content // null')"
    if [ "$EXISTING_CAT" != "null" ] && [ -n "$EXISTING_CAT" ]; then
      UPDATED_CAT="$(printf '%s' "$EXISTING_CAT" | jq -c \
        --arg category "$CATEGORY" \
        --arg now "$NOW" \
        '. + {category: $category, classified_by: "user-confirmed", confirmed_at: $now}')"
      saga_note_upsert "$PROJECT_PATH" "baseline-category" "context" "$UPDATED_CAT" $(_ws_arg)
    fi

    jq -nc \
      --arg category "$CATEGORY" \
      --arg reason "$REASON" \
      --arg now "$NOW" \
      '{
        mode: "classify",
        action: "confirm",
        category_confirmed: $category,
        reason: $reason,
        confirmed_at: $now
      }'
    ;;

  '')
    printf 'classify.sh: subcomando obrigatorio (confirm)\n' >&2
    exit 1
    ;;

  *)
    printf 'classify.sh: subcomando desconhecido: %s\n' "$SUBCMD" >&2
    exit 1
    ;;
esac
