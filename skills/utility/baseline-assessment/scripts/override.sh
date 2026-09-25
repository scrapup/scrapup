#!/usr/bin/env bash
# override.sh — gerencia overrides de scripts via baseline-overrides note.
#
# Subcomandos:
#   set    --script=<s> --alternative=<cmd|disabled> --reason=<r> [--ttl-days=<n>]
#          [--project-path <p>] [--workspace <ws>]
#   remove --script=<s> [--project-path <p>] [--workspace <ws>]
#
# Saidas: JSON conforme plan.md 4.5.
# Validacoes: RN-09 (TTL 1-30), script em {test,lint,build,typecheck,cov},
# reason >=10 chars, alternative nao-vazio.

set -euo pipefail

OVERRIDE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/saga-client.sh
. "$OVERRIDE_DIR/lib/saga-client.sh"

command -v jq >/dev/null 2>&1 || { printf 'override.sh: jq ausente\n' >&2; exit 3; }

SUBCMD="${1:-}"
shift || true

PROJECT_PATH="."
WORKSPACE=""
SCRIPT=""
ALTERNATIVE=""
TTL_DAYS=7
REASON=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --project-path=*) PROJECT_PATH="${1#*=}"; shift ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --workspace=*) WORKSPACE="${1#*=}"; shift ;;
    --script) SCRIPT="$2"; shift 2 ;;
    --script=*) SCRIPT="${1#*=}"; shift ;;
    --alternative) ALTERNATIVE="$2"; shift 2 ;;
    --alternative=*) ALTERNATIVE="${1#*=}"; shift ;;
    --ttl-days) TTL_DAYS="$2"; shift 2 ;;
    --ttl-days=*) TTL_DAYS="${1#*=}"; shift ;;
    --reason) REASON="$2"; shift 2 ;;
    --reason=*) REASON="${1#*=}"; shift ;;
    --help|-h) sed -n '2,15p' "$0"; exit 0 ;;
    *) printf 'override.sh: flag desconhecida: %s\n' "$1" >&2; exit 1 ;;
  esac
done

_ws_arg() { [ -n "$WORKSPACE" ] && printf -- '--ws %s' "$WORKSPACE"; }

_validate_script() {
  case "$1" in
    test|lint|build|typecheck|cov) return 0 ;;
    *) return 1 ;;
  esac
}

_iso_future() {
  local days="$1"
  date -u -v+"${days}"d +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || \
  date -u -d "+${days} days" +'%Y-%m-%dT%H:%M:%SZ'
}

case "$SUBCMD" in
  set)
    if ! _validate_script "$SCRIPT"; then
      printf 'override set: --script deve ser test|lint|build|typecheck|cov (recebido: %s)\n' "$SCRIPT" >&2
      exit 1
    fi
    if [ -z "$ALTERNATIVE" ]; then
      printf 'override set: --alternative obrigatorio (use \"disabled\" para desativar)\n' >&2
      exit 1
    fi
    if [ -z "$REASON" ] || [ "${#REASON}" -lt 10 ]; then
      printf 'override set: --reason deve ter >=10 caracteres\n' >&2
      exit 1
    fi
    if ! [[ "$TTL_DAYS" =~ ^[0-9]+$ ]] || [ "$TTL_DAYS" -lt 1 ] || [ "$TTL_DAYS" -gt 30 ]; then
      printf 'override set: --ttl-days deve estar entre 1 e 30\n' >&2
      exit 1
    fi

    saga_project_ensure "$PROJECT_PATH" >/dev/null
    EXPIRES="$(_iso_future "$TTL_DAYS")"
    NOW="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

    # Le nota atual e aplica upsert da entrada
    EXISTING="$(saga_note_get "$PROJECT_PATH" "baseline-overrides" $(_ws_arg) | jq -c '.content // null')"
    if [ "$EXISTING" = "null" ] || [ -z "$EXISTING" ]; then
      CURRENT_ARR='[]'
    else
      CURRENT_ARR="$(printf '%s' "$EXISTING" | jq -c '.overrides // []')"
    fi

    REPLACED=false
    if printf '%s' "$CURRENT_ARR" | jq -e --arg s "$SCRIPT" 'any(.[]; .script == $s)' >/dev/null; then
      REPLACED=true
      CURRENT_ARR="$(printf '%s' "$CURRENT_ARR" | jq -c --arg s "$SCRIPT" 'map(select(.script != $s))')"
    fi

    NEW_ARR="$(printf '%s' "$CURRENT_ARR" | jq -c \
      --arg s "$SCRIPT" \
      --arg alt "$ALTERNATIVE" \
      --arg exp "$EXPIRES" \
      --arg reason "$REASON" \
      --arg now "$NOW" \
      '. + [{script: $s, alternative: $alt, expires_at: $exp, reason: $reason, created_at: $now}]')"

    CONTENT="$(jq -nc \
      --argjson arr "$NEW_ARR" \
      --arg now "$NOW" \
      '{schema_version:1, overrides: $arr, updated_at: $now}')"

    saga_note_upsert "$PROJECT_PATH" "baseline-overrides" "context" "$CONTENT" $(_ws_arg)

    OBS='[]'
    [ "$REPLACED" = true ] && OBS='["override-replaced"]'

    jq -nc \
      --arg script "$SCRIPT" \
      --arg alt "$ALTERNATIVE" \
      --arg exp "$EXPIRES" \
      --arg reason "$REASON" \
      --argjson obs "$OBS" \
      '{
        mode: "override",
        action: "set",
        script: $script,
        override_active: true,
        alternative: $alt,
        expires_at: $exp,
        reason: $reason,
        observations: $obs
      }'
    ;;

  remove)
    if ! _validate_script "$SCRIPT"; then
      printf 'override remove: --script invalido\n' >&2
      exit 1
    fi

    saga_project_ensure "$PROJECT_PATH" >/dev/null
    EXISTING="$(saga_note_get "$PROJECT_PATH" "baseline-overrides" $(_ws_arg) | jq -c '.content // null')"
    if [ "$EXISTING" = "null" ] || [ -z "$EXISTING" ]; then
      printf 'override remove: nao ha overrides registrados\n' >&2
      exit 1
    fi

    CURRENT_ARR="$(printf '%s' "$EXISTING" | jq -c '.overrides // []')"
    if ! printf '%s' "$CURRENT_ARR" | jq -e --arg s "$SCRIPT" 'any(.[]; .script == $s)' >/dev/null; then
      printf 'override remove: override para --script=%s nao encontrado\n' "$SCRIPT" >&2
      exit 1
    fi

    NEW_ARR="$(printf '%s' "$CURRENT_ARR" | jq -c --arg s "$SCRIPT" 'map(select(.script != $s))')"
    NOW="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    CONTENT="$(jq -nc --argjson arr "$NEW_ARR" --arg now "$NOW" \
      '{schema_version:1, overrides: $arr, updated_at: $now}')"

    saga_note_upsert "$PROJECT_PATH" "baseline-overrides" "context" "$CONTENT" $(_ws_arg)

    jq -nc --arg script "$SCRIPT" \
      '{mode: "override", action: "remove", script: $script, override_active: false}'
    ;;

  '')
    printf 'override.sh: subcomando obrigatorio (set ou remove)\n' >&2
    exit 1
    ;;

  *)
    printf 'override.sh: subcomando desconhecido: %s\n' "$SUBCMD" >&2
    exit 1
    ;;
esac
