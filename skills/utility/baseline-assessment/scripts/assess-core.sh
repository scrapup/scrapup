#!/usr/bin/env bash
# assess-core.sh — orquestra o modo assess da baseline-assessment.
#
# Fluxo (conforme diagrams/baseline-seq-assess-success.puml):
#   1. parse flags
#   2. workspace-detect (erro quando monorepo sem --workspace)
#   3. check-environment (se blocked, retorna cedo)
#   4. detect-runner (obtem manifest_hash)
#   5. compara hash com cache -> status=cached se bate e sem --force
#   6. classify-project (se category=indefinido, retorna blocked-classification)
#   7. recomputa category_effective via effective-category.sh
#   8. executa suite (test/lint) quando categoria efetiva permite
#   9. persiste batch: test-scripts, baseline-category, baseline-latest (sempre),
#      baseline-current (se verde), metrics:run
#   10. emite JSON estruturado (plan.md 4.2)
#
# Flags:
#   --project-path <p>       default "."
#   --workspace <ws>         escopo em monorepo
#   --force                  ignora cache
#   --timeout-seconds <n>    default 600 para a suite
#   --no-persist-metrics     pula metrics:run (uso em testes)
#   --skip-suite             pula execucao da suite (uso em testes)
#
# Env vars (mock):
#   BASELINE_MOCK_SUITE=green|red|timeout  forca resultado da suite

set -euo pipefail

ASSESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$ASSESS_DIR/lib"
# shellcheck source=./lib/saga-client.sh
. "$LIB_DIR/saga-client.sh"

command -v jq >/dev/null 2>&1 || { printf 'assess-core.sh: jq ausente\n' >&2; exit 3; }

PROJECT_PATH="."
WORKSPACE=""
FORCE=false
TIMEOUT_SECONDS=600
PERSIST_METRICS=true
RUN_SUITE=true

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --project-path=*) PROJECT_PATH="${1#*=}"; shift ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --workspace=*) WORKSPACE="${1#*=}"; shift ;;
    --force) FORCE=true; shift ;;
    --timeout-seconds) TIMEOUT_SECONDS="$2"; shift 2 ;;
    --timeout-seconds=*) TIMEOUT_SECONDS="${1#*=}"; shift ;;
    --no-persist-metrics) PERSIST_METRICS=false; shift ;;
    --skip-suite) RUN_SUITE=false; shift ;;
    --help|-h) sed -n '2,30p' "$0"; exit 0 ;;
    *) printf 'assess-core.sh: flag desconhecida: %s\n' "$1" >&2; exit 3 ;;
  esac
done

_iso_now() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }

_ws_arg() {
  [ -n "$WORKSPACE" ] && printf -- '--ws %s' "$WORKSPACE"
}

# Detecta binario de timeout portavel entre Linux (GNU coreutils: `timeout`)
# e macOS (coreutils instalado via brew: `gtimeout`). Retorna o nome do
# executavel ou string vazia quando nenhum dos dois esta disponivel.
_timeout_bin() {
  if command -v timeout >/dev/null 2>&1; then
    printf 'timeout'
  elif command -v gtimeout >/dev/null 2>&1; then
    printf 'gtimeout'
  else
    printf ''
  fi
}

_git_head_sha() {
  if [ -d "$PROJECT_PATH/.git" ] || git -C "$PROJECT_PATH" rev-parse --show-toplevel >/dev/null 2>&1; then
    git -C "$PROJECT_PATH" rev-parse HEAD 2>/dev/null || printf ''
  fi
}

# ----- RT-02: workspace-detect -----
MONOREPO_JSON="$(bash "$LIB_DIR/workspace-detect.sh" "$PROJECT_PATH")"
IS_MONOREPO="$(printf '%s' "$MONOREPO_JSON" | jq -r '.is_monorepo')"
MONOREPO_TOOL="$(printf '%s' "$MONOREPO_JSON" | jq -r '.tool // ""')"

if [ "$IS_MONOREPO" = "true" ] && [ -z "$WORKSPACE" ]; then
  # Permite execucao na raiz mesmo em monorepo (sinaliza observacao).
  # Caller pode forcar por-workspace invocando com --workspace.
  :
fi

# ----- RT-04a: check-environment -----
ENV_JSON="$(bash "$ASSESS_DIR/check-environment.sh" --project-path "$PROJECT_PATH")"
ENV_STATE="$(printf '%s' "$ENV_JSON" | jq -r '.state')"
DOCKER_AVAILABLE="$(printf '%s' "$ENV_JSON" | jq -r '.docker_available | tostring')"
ENV_OBSERVATIONS="$(printf '%s' "$ENV_JSON" | jq -c '.observations')"

if [ "$ENV_STATE" = "blocked" ]; then
  jq -nc \
    --argjson env "$ENV_JSON" \
    --arg ts "$(_iso_now)" \
    '{
      mode: "assess",
      status: "blocked",
      environment_state: $env.state,
      environment_details: $env,
      workspace: null,
      is_monorepo: false,
      category: null,
      category_effective: null,
      scripts: null,
      runner: null,
      linter: null,
      overrides_active: [],
      baseline_current: null,
      baseline_latest: null,
      observations: ($env.observations + ["environment-blocked"]),
      recommendations: ["resolver pre-requisitos do ambiente e re-executar assess"],
      timestamp: $ts
    }'
  exit 1
fi

# ----- RT-04b: detect-runner -----
DETECT_ARGS=(--project-path "$PROJECT_PATH")
[ -n "$WORKSPACE" ] && DETECT_ARGS+=(--workspace "$WORKSPACE")
DETECT_JSON="$(bash "$ASSESS_DIR/detect-runner.sh" "${DETECT_ARGS[@]}")"
MANIFEST_HASH="$(printf '%s' "$DETECT_JSON" | jq -r '.manifest_hash')"
RUNNER="$(printf '%s' "$DETECT_JSON" | jq -r '.runner')"
LINTER="$(printf '%s' "$DETECT_JSON" | jq -r '.linter')"
SCRIPTS_FIELD="$(printf '%s' "$DETECT_JSON" | jq -c '.scripts')"
DETECT_OBS="$(printf '%s' "$DETECT_JSON" | jq -c '.observations')"

# ----- RT-04b.1: carregar overrides persistidos em baseline-overrides -----
# Espelha logica de report.sh (filtra expires_at no futuro). Sera usado no
# bloco de execucao da suite (aplicar .alternative no lugar do script detectado)
# e no JSON final (campo overrides_active, em vez de [] hardcoded).
OVERRIDES_CONTENT="$(saga_note_get "$PROJECT_PATH" "baseline-overrides" $(_ws_arg) | jq -c '.content // null')"
NOW_ISO="$(_iso_now)"
OVERRIDES_ACTIVE='[]'
if [ "$OVERRIDES_CONTENT" != "null" ] && [ -n "$OVERRIDES_CONTENT" ]; then
  OVERRIDES_ACTIVE="$(printf '%s' "$OVERRIDES_CONTENT" | jq -c --arg now "$NOW_ISO" \
    '[(.overrides // [])[] | select(.expires_at > $now)]')"
fi

# ----- RT-05: hash compare / cached -----
CACHED_SCRIPTS="$(saga_note_get "$PROJECT_PATH" "test-scripts" $(_ws_arg))"
CACHED_HASH=""
if [ "$CACHED_SCRIPTS" != "null" ] && [ -n "$CACHED_SCRIPTS" ]; then
  CACHED_HASH="$(printf '%s' "$CACHED_SCRIPTS" | jq -r '.content.manifest_hash // empty')"
fi

if [ "$FORCE" = false ] && [ -n "$CACHED_HASH" ] && [ "$CACHED_HASH" = "$MANIFEST_HASH" ]; then
  CACHED_CATEGORY="$(saga_note_get "$PROJECT_PATH" "baseline-category" $(_ws_arg) | jq -c '.content // null')"
  CACHED_CURRENT="$(saga_note_get "$PROJECT_PATH" "baseline-current" $(_ws_arg) | jq -c '.content // null')"
  CACHED_LATEST="$(saga_note_get "$PROJECT_PATH" "baseline-latest" $(_ws_arg) | jq -c '.content // null')"

  CATEGORY="$(printf '%s' "$CACHED_CATEGORY" | jq -r 'if . == null then "" else (.category // "") end')"
  CATEGORY_EFFECTIVE="$(bash "$LIB_DIR/effective-category.sh" "$CATEGORY" "$ENV_STATE" "$DOCKER_AVAILABLE")"

  jq -nc \
    --argjson env "$ENV_JSON" \
    --arg ws "$WORKSPACE" \
    --argjson is_monorepo "$IS_MONOREPO" \
    --arg category "$CATEGORY" \
    --arg category_effective "$CATEGORY_EFFECTIVE" \
    --argjson scripts "$SCRIPTS_FIELD" \
    --arg runner "$RUNNER" \
    --arg linter "$LINTER" \
    --argjson overrides "$OVERRIDES_ACTIVE" \
    --argjson current "$CACHED_CURRENT" \
    --argjson latest "$CACHED_LATEST" \
    '{
      mode: "assess",
      status: "cached",
      environment_state: $env.state,
      environment_details: $env,
      workspace: (if $ws == "" then null else $ws end),
      is_monorepo: $is_monorepo,
      category: (if $category == "" then null else $category end),
      category_effective: (if $category_effective == "null" then null else $category_effective end),
      scripts: $scripts,
      runner: $runner,
      linter: $linter,
      overrides_active: $overrides,
      baseline_current: $current,
      baseline_latest: $latest,
      observations: ["cache-hit"],
      recommendations: []
    }'
  exit 0
fi

# ----- RT-06: classify (com consulta a classification-override do saga) -----
CLASSIFICATION_OVERRIDE_CONTENT="$(saga_note_get "$PROJECT_PATH" "category-confirmation" $(_ws_arg) | jq -c '.content // null')"
if [ "$CLASSIFICATION_OVERRIDE_CONTENT" != "null" ] && [ -n "$CLASSIFICATION_OVERRIDE_CONTENT" ]; then
  CLASSIFICATION_OVERRIDE_JSON="$(printf '%s' "$CLASSIFICATION_OVERRIDE_CONTENT" | jq -c '{category: .category_confirmed, reason}')"
else
  CLASSIFICATION_OVERRIDE_JSON="null"
fi

CLASSIFY_INPUT="$(jq -nc \
  --arg p "$PROJECT_PATH" \
  --argjson dr "$DETECT_JSON" \
  --arg es "$ENV_STATE" \
  --argjson da "$DOCKER_AVAILABLE" \
  --argjson override "$CLASSIFICATION_OVERRIDE_JSON" \
  '{project_path: $p, detect_result: $dr, environment_state: $es, docker_available: $da, classification_override: $override}')"

CLASSIFY_JSON="$(printf '%s' "$CLASSIFY_INPUT" | bash "$ASSESS_DIR/classify-project.sh")"
CATEGORY="$(printf '%s' "$CLASSIFY_JSON" | jq -r '.category')"
CLASSIFY_OBS="$(printf '%s' "$CLASSIFY_JSON" | jq -c '.observations')"

if [ "$CATEGORY" = "indefinido" ]; then
  # Persiste test-scripts + baseline-category (indefinido) mas NAO baseline-latest/current
  SCRIPTS_CONTENT="$(jq -nc \
    --argjson dr "$DETECT_JSON" \
    --arg hash "$MANIFEST_HASH" \
    --arg ts "$(_iso_now)" \
    '{schema_version:1, scripts: $dr.scripts, runner: $dr.runner, linter: $dr.linter,
      manifest_hash: $hash, timestamp: $ts, monorepo: $dr.monorepo}')"
  saga_note_upsert "$PROJECT_PATH" "test-scripts" "context" "$SCRIPTS_CONTENT" $(_ws_arg) || true

  CATEGORY_CONTENT="$(jq -nc \
    --argjson classify "$CLASSIFY_JSON" \
    --arg ts "$(_iso_now)" \
    '{schema_version:1, category: "indefinido", signals: $classify.signals,
      timestamp: $ts, classified_by: "auto"}')"
  saga_note_upsert "$PROJECT_PATH" "baseline-category" "context" "$CATEGORY_CONTENT" $(_ws_arg) || true

  jq -nc \
    --argjson env "$ENV_JSON" \
    --argjson classify "$CLASSIFY_JSON" \
    --arg ws "$WORKSPACE" \
    --argjson is_monorepo "$IS_MONOREPO" \
    --argjson scripts "$SCRIPTS_FIELD" \
    --arg runner "$RUNNER" \
    --arg linter "$LINTER" \
    --argjson overrides "$OVERRIDES_ACTIVE" \
    '{
      mode: "assess",
      status: "blocked-classification",
      environment_state: $env.state,
      environment_details: $env,
      workspace: (if $ws == "" then null else $ws end),
      is_monorepo: $is_monorepo,
      category: "indefinido",
      category_effective: null,
      scripts: $scripts,
      runner: $runner,
      linter: $linter,
      overrides_active: $overrides,
      observations: ($classify.observations + ["classification-indefinido"]),
      recommendations: ["invocar baseline-check.sh classify confirm com categoria explicita"]
    }'
  exit 1
fi

# ----- RT-04c: effective category -----
CATEGORY_EFFECTIVE="$(bash "$LIB_DIR/effective-category.sh" "$CATEGORY" "$ENV_STATE" "$DOCKER_AVAILABLE")"

# ----- RT-06: execucao da suite quando aplicavel -----
TESTS_PREVIOUSLY_RED='[]'
TESTS_PREVIOUSLY_GREEN='[]'
TESTS_COUNT='{"total":0,"passed":0,"failed":0,"skipped":0}'
COVERAGE_GLOBAL='null'
TESTS_RUNTIME_MS=0
OUTCOME="not-executed"
STATUS="no-execution"
REASON=""
SUITE_OBS='[]'

_permits_local_execution() {
  case "$CATEGORY_EFFECTIVE" in
    saudavel|legado-estavel|legado-docker-dependent) return 0 ;;
    *) return 1 ;;
  esac
}

if [ "$RUN_SUITE" = true ] && _permits_local_execution; then
  case "${BASELINE_MOCK_SUITE:-}" in
    green)
      OUTCOME="green"
      STATUS="green"
      TESTS_COUNT='{"total":10,"passed":10,"failed":0,"skipped":0}'
      TESTS_PREVIOUSLY_GREEN='["mock-test-1","mock-test-2"]'
      COVERAGE_GLOBAL='{"lines":92.4,"branches":88.1,"functions":95.0,"statements":92.1}'
      ;;
    red)
      OUTCOME="red-known"
      STATUS="red-known"
      TESTS_COUNT='{"total":10,"passed":8,"failed":2,"skipped":0}'
      TESTS_PREVIOUSLY_RED='["mock-test-failing"]'
      TESTS_PREVIOUSLY_GREEN='["mock-test-passing"]'
      COVERAGE_GLOBAL='{"lines":85.2,"branches":80.1,"functions":90.0,"statements":85.0}'
      ;;
    timeout)
      OUTCOME="timeout"
      STATUS="red-known"
      REASON="suite-timeout"
      CATEGORY="legado-estavel"
      ;;
    *)
      TEST_CMD="$(printf '%s' "$DETECT_JSON" | jq -r '.scripts.test // empty')"
      COV_CMD="$(printf '%s' "$DETECT_JSON" | jq -r '.scripts.cov // empty')"

      OVERRIDE_TEST="$(printf '%s' "$OVERRIDES_ACTIVE" | jq -r \
        '([.[] | select(.script == "test")] | first // empty | .alternative // empty)')"
      if [ -n "$OVERRIDE_TEST" ]; then
        if [ "$OVERRIDE_TEST" = "disabled" ]; then
          TEST_CMD=""
          OUTCOME="disabled-by-override"
          STATUS="no-execution"
          REASON="test-script-desativado-por-override"
        else
          TEST_CMD="$OVERRIDE_TEST"
        fi
      fi

      OVERRIDE_COV="$(printf '%s' "$OVERRIDES_ACTIVE" | jq -r \
        '([.[] | select(.script == "cov")] | first // empty | .alternative // empty)')"
      if [ -n "$OVERRIDE_COV" ]; then
        if [ "$OVERRIDE_COV" = "disabled" ]; then
          COV_CMD=""
        else
          COV_CMD="$OVERRIDE_COV"
        fi
      fi

      if [ -n "$TEST_CMD" ]; then
        SUITE_ARGS=(--project-path "$PROJECT_PATH" --runner "$RUNNER" \
          --test-cmd "$TEST_CMD" --timeout-seconds "$TIMEOUT_SECONDS")
        [ -n "$WORKSPACE" ] && SUITE_ARGS+=(--workspace "$WORKSPACE")
        [ -n "$COV_CMD" ] && SUITE_ARGS+=(--cov-cmd "$COV_CMD")

        SUITE_JSON="$(bash "$LIB_DIR/run-unit-suite.sh" "${SUITE_ARGS[@]}")"
        OUTCOME="$(printf '%s' "$SUITE_JSON" | jq -r '.outcome')"
        TESTS_COUNT="$(printf '%s' "$SUITE_JSON" | jq -c '.tests_count')"
        TESTS_PREVIOUSLY_RED="$(printf '%s' "$SUITE_JSON" | jq -c '.tests_previously_red')"
        TESTS_PREVIOUSLY_GREEN="$(printf '%s' "$SUITE_JSON" | jq -c '.tests_previously_green')"
        COVERAGE_GLOBAL="$(printf '%s' "$SUITE_JSON" | jq -c '.coverage_global')"
        TESTS_RUNTIME_MS="$(printf '%s' "$SUITE_JSON" | jq -r '.tests_runtime_ms')"
        SUITE_OBS="$(printf '%s' "$SUITE_JSON" | jq -c '.observations // []')"

        case "$OUTCOME" in
          green) STATUS="green" ;;
          red-known) STATUS="red-known" ;;
          timeout)
            STATUS="red-known"
            REASON="suite-timeout"
            ;;
          no-test-script)
            STATUS="no-execution"
            REASON="test-script-ausente"
            ;;
          *)
            STATUS="red-known"
            ;;
        esac

        if printf '%s' "$SUITE_OBS" | jq -e 'any(. == "runner-output-not-parsed")' >/dev/null 2>&1; then
          REASON="${REASON:+$REASON; }runner-output-not-parsed"
        fi
        if printf '%s' "$SUITE_OBS" | jq -e 'any(. == "coverage-summary-ausente")' >/dev/null 2>&1; then
          REASON="${REASON:+$REASON; }coverage-summary-ausente"
        fi
      elif [ "$OUTCOME" = "not-executed" ]; then
        OUTCOME="no-test-script"
        STATUS="no-execution"
        REASON="test-script-ausente"
      fi
      ;;
  esac
else
  STATUS="no-execution"
  REASON="categoria-efetiva-nao-permite-execucao-local"
fi

# ----- RT-07: persistencia batch -----
NOW="$(_iso_now)"
COMMIT_SHA="$(_git_head_sha)"

# test-scripts
SCRIPTS_CONTENT="$(jq -nc \
  --argjson dr "$DETECT_JSON" \
  --arg hash "$MANIFEST_HASH" \
  --arg ts "$NOW" \
  '{schema_version:1, scripts: $dr.scripts, runner: $dr.runner, linter: $dr.linter,
    manifest_hash: $hash, timestamp: $ts, monorepo: $dr.monorepo}')"
saga_note_upsert "$PROJECT_PATH" "test-scripts" "context" "$SCRIPTS_CONTENT" $(_ws_arg) || true

# baseline-category
CATEGORY_CONTENT="$(jq -nc \
  --arg category "$CATEGORY" \
  --argjson signals "$(printf '%s' "$CLASSIFY_JSON" | jq -c '.signals')" \
  --arg ts "$NOW" \
  '{schema_version:1, category: $category, signals: $signals,
    timestamp: $ts, classified_by: "auto"}')"
saga_note_upsert "$PROJECT_PATH" "baseline-category" "context" "$CATEGORY_CONTENT" $(_ws_arg) || true

# baseline-latest (sempre, apos assess com ambiente nao-blocked)
LATEST_CONTENT="$(jq -nc \
  --argjson count "$TESTS_COUNT" \
  --argjson red "$TESTS_PREVIOUSLY_RED" \
  --argjson green "$TESTS_PREVIOUSLY_GREEN" \
  --argjson cov "$COVERAGE_GLOBAL" \
  --arg runtime "$TESTS_RUNTIME_MS" \
  --arg sha "$COMMIT_SHA" \
  --arg ts "$NOW" \
  --arg outcome "$OUTCOME" \
  '{schema_version:1, tests_count: $count, tests_previously_red: $red,
    tests_previously_green: $green, coverage_global: $cov,
    tests_runtime_ms: ($runtime | tonumber), commit_sha: (if $sha == "" then null else $sha end),
    timestamp: $ts, outcome: $outcome}')"
saga_note_upsert "$PROJECT_PATH" "baseline-latest" "context" "$LATEST_CONTENT" $(_ws_arg) || true

# baseline-current (APENAS se totalmente verde; preserva o anterior senao)
BASELINE_CURRENT='null'
if [ "$STATUS" = "green" ]; then
  CURRENT_CONTENT="$(jq -nc \
    --argjson count "$TESTS_COUNT" \
    --argjson cov "$COVERAGE_GLOBAL" \
    --arg runtime "$TESTS_RUNTIME_MS" \
    --arg sha "$COMMIT_SHA" \
    --arg ts "$NOW" \
    '{schema_version:1, tests_count: $count, coverage_global: $cov,
      tests_runtime_ms: ($runtime | tonumber), commit_sha: (if $sha == "" then null else $sha end),
      timestamp: $ts}')"
  saga_note_upsert "$PROJECT_PATH" "baseline-current" "context" "$CURRENT_CONTENT" $(_ws_arg) || true
  BASELINE_CURRENT="$CURRENT_CONTENT"
else
  BASELINE_CURRENT="$(saga_note_get "$PROJECT_PATH" "baseline-current" $(_ws_arg) | jq -c '.content // null')"
fi

# metrics:run
if [ "$PERSIST_METRICS" = true ]; then
  METRIC_ENTRY="$(jq -nc \
    --arg ts "$NOW" \
    --arg outcome "$OUTCOME" \
    --arg env_state "$ENV_STATE" \
    --arg cat_eff "$CATEGORY_EFFECTIVE" \
    --arg mode "assess" \
    --arg runtime "$TESTS_RUNTIME_MS" \
    --arg sha "$COMMIT_SHA" \
    '{schema_version:1, mode: $mode, outcome: $outcome,
      environment_state_snapshot: $env_state, category_effective: $cat_eff,
      duration_ms: ($runtime | tonumber), commit_sha: (if $sha == "" then null else $sha end),
      timestamp: $ts}')"
  saga_metrics_append "$PROJECT_PATH" "$METRIC_ENTRY" || true
fi

# ----- RT-08: JSON final -----
COMBINED_OBS="$(jq -cn \
  --argjson env "$ENV_OBSERVATIONS" \
  --argjson dr "$DETECT_OBS" \
  --argjson cls "$CLASSIFY_OBS" \
  --argjson suite "$SUITE_OBS" \
  --arg reason "$REASON" \
  '($env + $dr + $cls + $suite) + (if $reason == "" then [] else [$reason] end)')"

jq -nc \
  --argjson env "$ENV_JSON" \
  --arg ws "$WORKSPACE" \
  --argjson is_monorepo "$IS_MONOREPO" \
  --arg status "$STATUS" \
  --arg category "$CATEGORY" \
  --arg category_effective "$CATEGORY_EFFECTIVE" \
  --argjson scripts "$SCRIPTS_FIELD" \
  --arg runner "$RUNNER" \
  --arg linter "$LINTER" \
  --argjson overrides "$OVERRIDES_ACTIVE" \
  --argjson baseline_current "$BASELINE_CURRENT" \
  --argjson baseline_latest "$LATEST_CONTENT" \
  --argjson observations "$COMBINED_OBS" \
  '{
    mode: "assess",
    status: $status,
    environment_state: $env.state,
    environment_details: $env,
    workspace: (if $ws == "" then null else $ws end),
    is_monorepo: $is_monorepo,
    category: $category,
    category_effective: (if $category_effective == "null" then null else $category_effective end),
    scripts: $scripts,
    runner: $runner,
    linter: $linter,
    overrides_active: $overrides,
    baseline_current: $baseline_current,
    baseline_latest: $baseline_latest,
    observations: $observations,
    recommendations: []
  }'
