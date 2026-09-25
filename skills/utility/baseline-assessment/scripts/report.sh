#!/usr/bin/env bash
# report.sh — leitura pura do estado persistido da baseline.
#
# Uso:
#   report.sh [--project-path <p>] [--workspace <ws>]
#
# Saida (stdout JSON, conforme plan.md 4.4):
#   {
#     "mode": "report",
#     "repo": "...",
#     "workspace": "apps/api" | null,
#     "is_monorepo": bool,
#     "last_assessed_at": "...",
#     "environment_state": "ready|partial|blocked" | null,
#     "category": "saudavel|...|indefinido" | null,
#     "category_effective": "..." | null,
#     "scripts": {...} | null,
#     "runner": "...",
#     "linter": "...",
#     "overrides_active": [...],
#     "baseline_current": {...} | null,
#     "baseline_latest": {...} | null,
#     "recent_runs_summary": { last_7_days: { total, green, regressions, warns } },
#     "saga_offline": true | false  (alias de pending_saga_sync no cache; ver plan.md 4.4)
#     "observations": []
#   }
#
# category_effective e recomputada (RN-27) a partir de
# baseline-category.category + environment-state.state corrente.

set -euo pipefail

REPORT_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# saga-client.sh ja carrega cache-local.sh internamente.
# shellcheck source=./lib/saga-client.sh
. "$REPORT_SCRIPT_DIR/lib/saga-client.sh"

PROJECT_PATH="."
WORKSPACE=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --project-path=*) PROJECT_PATH="${1#*=}"; shift ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --workspace=*) WORKSPACE="${1#*=}"; shift ;;
    --help|-h) sed -n '2,30p' "$0"; exit 0 ;;
    *)
      printf 'report.sh: flag desconhecida: %s\n' "$1" >&2
      exit 3
      ;;
  esac
done

_get_content() {
  local title="$1"
  local result
  if [ -n "$WORKSPACE" ]; then
    result="$(cache_note_get "$PROJECT_PATH" "$title" --ws "$WORKSPACE")"
  else
    result="$(cache_note_get "$PROJECT_PATH" "$title")"
  fi
  if [ -z "$result" ] || [ "$result" = "null" ]; then
    printf 'null'
  else
    printf '%s' "$result" | jq -c '.content // null'
  fi
}

# Recomputa category_effective (RN-27) a partir de category + env_state.
_compute_effective_category() {
  local category="$1"
  local env_state="$2"
  local docker_available="$3"

  if [ -z "$category" ] || [ "$category" = "null" ] || [ "$category" = "indefinido" ]; then
    printf 'null'
    return
  fi
  if [ "$category" = "legado-docker-dependent" ] && \
     [ "$env_state" = "partial" ] && \
     [ "$docker_available" = "false" ]; then
    printf 'legado-critico'
    return
  fi
  printf '%s' "$category"
}

REPO_NAME="$(saga_project_name "$PROJECT_PATH" | sed 's/^test-config://')"

ENV_CONTENT="$(_get_content "environment-state")"
SCRIPTS_CONTENT="$(_get_content "test-scripts")"
CAT_CONTENT="$(_get_content "baseline-category")"
CUR_CONTENT="$(_get_content "baseline-current")"
LAT_CONTENT="$(_get_content "baseline-latest")"
OVERRIDES_CONTENT="$(_get_content "baseline-overrides")"
CONFIRM_CONTENT="$(_get_content "category-confirmation")"

ENV_STATE="$(printf '%s' "$ENV_CONTENT" | jq -r 'if . == null then "" else (.state // "") end')"
DOCKER_AVAILABLE="$(printf '%s' "$ENV_CONTENT" | jq -r 'if . == null then "true" elif has("docker_available") then (.docker_available | tostring) else "true" end')"
CATEGORY="$(printf '%s' "$CAT_CONTENT" | jq -r 'if . == null then "" else (.category // "") end')"

# Override: se category-confirmation presente, usa-a.
if [ "$CONFIRM_CONTENT" != "null" ] && [ -n "$CONFIRM_CONTENT" ]; then
  CATEGORY="$(printf '%s' "$CONFIRM_CONTENT" | jq -r '.category_confirmed // empty')"
fi

CATEGORY_EFFECTIVE="$(_compute_effective_category "$CATEGORY" "$ENV_STATE" "$DOCKER_AVAILABLE")"

RUNNER="$(printf '%s' "$SCRIPTS_CONTENT" | jq -r 'if . == null then "" else (.runner // "") end')"
LINTER="$(printf '%s' "$SCRIPTS_CONTENT" | jq -r 'if . == null then "" else (.linter // "") end')"
SCRIPTS_FIELD="$(printf '%s' "$SCRIPTS_CONTENT" | jq -c 'if . == null then null else (.scripts // null) end')"
IS_MONOREPO="$(printf '%s' "$SCRIPTS_CONTENT" | jq -r 'if . == null then false else (.monorepo.is_monorepo // false) end')"

# Overrides ativos (filtra expires_at no futuro)
now_iso="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
OVERRIDES_ACTIVE='[]'
if [ "$OVERRIDES_CONTENT" != "null" ] && [ -n "$OVERRIDES_CONTENT" ]; then
  OVERRIDES_ACTIVE="$(printf '%s' "$OVERRIDES_CONTENT" | jq -c --arg now "$now_iso" \
    '[(.overrides // [])[] | select(.expires_at > $now)]')"
fi

# Recent runs summary
recent_runs="$(cache_metrics_recent "$PROJECT_PATH" 7 2>/dev/null || printf '[]')"
recent_summary="$(printf '%s' "$recent_runs" | jq -c '
  {
    last_7_days: {
      total: length,
      green: (map(select(.outcome == "green")) | length),
      regressions: (map(select(.outcome == "red-regression")) | length),
      warns: (map(select(.outcome | test("warn|pre-existing|flaky|no-baseline"))) | length)
    }
  }')"

LAST_ASSESSED_AT="$(printf '%s' "$LAT_CONTENT" | jq -r 'if . == null then "" else (.timestamp // "") end')"
if [ -z "$LAST_ASSESSED_AT" ] && [ "$ENV_CONTENT" != "null" ]; then
  LAST_ASSESSED_AT="$(printf '%s' "$ENV_CONTENT" | jq -r '.timestamp // ""')"
fi

# saga_offline no JSON espelha pending_saga_sync (escritas por sincronizar com mcp-saga).
SAGA_OFFLINE="$(saga_sync_pending "$PROJECT_PATH" 2>/dev/null || printf 'false')"

jq -nc \
  --arg repo "$REPO_NAME" \
  --arg workspace "$WORKSPACE" \
  --argjson is_monorepo "$IS_MONOREPO" \
  --arg last_assessed_at "$LAST_ASSESSED_AT" \
  --arg env_state "$ENV_STATE" \
  --arg category "$CATEGORY" \
  --arg category_effective "$CATEGORY_EFFECTIVE" \
  --arg runner "$RUNNER" \
  --arg linter "$LINTER" \
  --argjson scripts "$SCRIPTS_FIELD" \
  --argjson overrides "$OVERRIDES_ACTIVE" \
  --argjson baseline_current "$CUR_CONTENT" \
  --argjson baseline_latest "$LAT_CONTENT" \
  --argjson recent_summary "$recent_summary" \
  --argjson saga_offline "$SAGA_OFFLINE" \
  '{
    mode: "report",
    repo: $repo,
    workspace: (if $workspace == "" then null else $workspace end),
    is_monorepo: $is_monorepo,
    last_assessed_at: (if $last_assessed_at == "" then null else $last_assessed_at end),
    environment_state: (if $env_state == "" then null else $env_state end),
    category: (if $category == "" then null else $category end),
    category_effective: (if $category_effective == "null" then null else $category_effective end),
    scripts: $scripts,
    runner: (if $runner == "" then null else $runner end),
    linter: (if $linter == "" then null else $linter end),
    overrides_active: $overrides,
    baseline_current: $baseline_current,
    baseline_latest: $baseline_latest,
    recent_runs_summary: $recent_summary,
    saga_offline: $saga_offline,
    observations: []
  }'
