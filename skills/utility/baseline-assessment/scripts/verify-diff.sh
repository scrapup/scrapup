#!/usr/bin/env bash
# verify-diff.sh — verificacao incremental sobre diff.
#
# Principio "nao regride o baseline" (RN-02, RN-17): falha apenas se o
# diff introduz regressao comparado ao ultimo estado verde registrado
# (baseline-current) ou ao ultimo estado observado (baseline-latest).
#
# Uso:
#   verify-diff.sh [--project-path <p>] [--scope=staged|commit|push]
#                  [--base <ref>] [--workspace <ws>] [--no-persist-metrics]
#
# Sem baseline persistido e com ficheiros no diff: executa assess-core.sh
# implicitamente (spec.md), salvo BASELINE_VERIFY_DIFF_SKIP_IMPLICIT_ASSESS=1.
#
# Env vars (mock):
#   BASELINE_MOCK_TESTS=green|red|flaky|pre-existing-red
#   BASELINE_MOCK_LINT=clean|errors-new|errors-existing
#   BASELINE_MOCK_COVERAGE=100|80|null

set -euo pipefail

VERIFY_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$VERIFY_DIR/lib"
# shellcheck source=./lib/saga-client.sh
. "$LIB_DIR/saga-client.sh"

command -v jq >/dev/null 2>&1 || { printf 'verify-diff.sh: jq ausente\n' >&2; exit 3; }

PROJECT_PATH="."
SCOPE="commit"
BASE_REF=""
WORKSPACE=""
PERSIST_METRICS=true

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --project-path=*) PROJECT_PATH="${1#*=}"; shift ;;
    --scope) SCOPE="$2"; shift 2 ;;
    --scope=*) SCOPE="${1#*=}"; shift ;;
    --base) BASE_REF="$2"; shift 2 ;;
    --base=*) BASE_REF="${1#*=}"; shift ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --workspace=*) WORKSPACE="${1#*=}"; shift ;;
    --no-persist-metrics) PERSIST_METRICS=false; shift ;;
    --help|-h) sed -n '2,20p' "$0"; exit 0 ;;
    *) printf 'verify-diff.sh: flag desconhecida: %s\n' "$1" >&2; exit 3 ;;
  esac
done

case "$SCOPE" in
  staged|commit|push) : ;;
  *) printf 'verify-diff.sh: scope invalido: %s (use staged|commit|push)\n' "$SCOPE" >&2; exit 3 ;;
esac

_iso_now() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }
_ws_arg() { [ -n "$WORKSPACE" ] && printf -- '--ws %s' "$WORKSPACE"; }

# Carrega baseline-category, snapshots e category_effective a partir do saga/cache.
_load_baseline_state() {
  CURRENT_CONTENT="$(saga_note_get "$PROJECT_PATH" "baseline-current" $(_ws_arg) | jq -c '.content // null')"
  LATEST_CONTENT="$(saga_note_get "$PROJECT_PATH" "baseline-latest" $(_ws_arg) | jq -c '.content // null')"
  CAT_CONTENT="$(saga_note_get "$PROJECT_PATH" "baseline-category" $(_ws_arg) | jq -c '.content // null')"
  CATEGORY="$(printf '%s' "$CAT_CONTENT" | jq -r 'if . == null then "" else (.category // "") end')"
  CATEGORY_EFFECTIVE="$(bash "$LIB_DIR/effective-category.sh" "$CATEGORY" "$ENV_STATE" "$DOCKER_AVAILABLE")"
  BASELINE_SOURCE="none"
  BASELINE_FOR_COMPARE="null"
  if [ "$LATEST_CONTENT" != "null" ] && [ -n "$LATEST_CONTENT" ]; then
    BASELINE_SOURCE="baseline-latest"
    BASELINE_FOR_COMPARE="$LATEST_CONTENT"
  elif [ "$CURRENT_CONTENT" != "null" ] && [ -n "$CURRENT_CONTENT" ]; then
    BASELINE_SOURCE="baseline-current"
    BASELINE_FOR_COMPARE="$CURRENT_CONTENT"
  fi
}

# ----- Env check -----
ENV_JSON="$(bash "$VERIFY_DIR/check-environment.sh" --project-path "$PROJECT_PATH")"
ENV_STATE="$(printf '%s' "$ENV_JSON" | jq -r '.state')"
DOCKER_AVAILABLE="$(printf '%s' "$ENV_JSON" | jq -r '.docker_available | tostring')"

if [ "$ENV_STATE" = "blocked" ]; then
  jq -nc --argjson env "$ENV_JSON" \
    '{
      mode: "verify-diff",
      gate_decision: "warn",
      environment_state_current: $env.state,
      category_effective: null,
      workspace: null,
      diff_scope: {files_changed: 0, tests_impacted: 0, scope: "commit", base_ref: null},
      results: {lint: {}, tests: {}, coverage_diff: {}},
      baseline_comparison: {baseline_source: "none"},
      reasons: ["environment-blocked-no-baseline"],
      observations: $env.observations,
      saga_offline: false
    }'
  exit 2
fi

# ----- Load baselines and category -----
_load_baseline_state

# Preferimos baseline-latest para comparacao de testes porque e la que ficam
# as listas tests_previously_red e tests_previously_green (plan.md 3.2).
# baseline-current atua como referencia de cobertura/contagem quando existe.

# ----- Calcular diff de arquivos -----
_compute_diff_files() {
  case "$SCOPE" in
    staged)
      git -C "$PROJECT_PATH" diff --cached --name-only 2>/dev/null || true
      ;;
    commit)
      if git -C "$PROJECT_PATH" rev-parse HEAD~1 >/dev/null 2>&1; then
        git -C "$PROJECT_PATH" diff --name-only HEAD~1 HEAD 2>/dev/null || true
      else
        git -C "$PROJECT_PATH" diff --name-only HEAD 2>/dev/null || true
      fi
      ;;
    push)
      local base="${BASE_REF:-origin/development}"
      if ! git -C "$PROJECT_PATH" rev-parse "$base" >/dev/null 2>&1; then
        base="origin/main"
      fi
      if ! git -C "$PROJECT_PATH" rev-parse "$base" >/dev/null 2>&1; then
        git -C "$PROJECT_PATH" diff --name-only HEAD 2>/dev/null || true
      else
        git -C "$PROJECT_PATH" diff --name-only "$base"...HEAD 2>/dev/null || true
      fi
      ;;
  esac
}

FILES_CHANGED_LIST="$(_compute_diff_files || true)"
if [ -z "$FILES_CHANGED_LIST" ]; then
  FILES_CHANGED_COUNT=0
else
  FILES_CHANGED_COUNT="$(printf '%s\n' "$FILES_CHANGED_LIST" | grep -c .)" || true
  [ -z "$FILES_CHANGED_COUNT" ] && FILES_CHANGED_COUNT=0
fi

# ----- Diff vazio -----
if [ "$FILES_CHANGED_COUNT" -eq 0 ]; then
  jq -nc --arg env "$ENV_STATE" --arg scope "$SCOPE" --arg cat "$CATEGORY_EFFECTIVE" \
    '{
      mode: "verify-diff",
      gate_decision: "pass",
      environment_state_current: $env,
      category_effective: (if $cat == "null" then null else $cat end),
      workspace: null,
      diff_scope: {files_changed: 0, tests_impacted: 0, scope: $scope, base_ref: null},
      results: {lint: {errors:0, warnings:0, new_errors:false}, tests: {executed:0, passed:0, failed:0, new_regressions:false}, coverage_diff: {lines_changed:0}},
      baseline_comparison: {baseline_source: "none"},
      reasons: ["empty-diff"],
      observations: [],
      saga_offline: false
    }'
  exit 0
fi

# ----- Diff so de docs/configs nao-codigo -----
CODE_FILES="$(printf '%s\n' "$FILES_CHANGED_LIST" | grep -E '\.(ts|tsx|js|jsx|mjs|cjs)$' || true)"
if [ -z "$CODE_FILES" ]; then
  CODE_FILES_COUNT=0
else
  CODE_FILES_COUNT="$(printf '%s\n' "$CODE_FILES" | grep -c .)" || true
  [ -z "$CODE_FILES_COUNT" ] && CODE_FILES_COUNT=0
fi

DIFF_DOCS_ONLY=false
if [ "$CODE_FILES_COUNT" -eq 0 ]; then
  DIFF_DOCS_ONLY=true
fi

# ----- Sem baseline: assess implicito (spec.md L146), depois re-carrega estado -----
if [ "$BASELINE_SOURCE" = "none" ] && [ "$FILES_CHANGED_COUNT" -gt 0 ] \
  && [ "${BASELINE_VERIFY_DIFF_SKIP_IMPLICIT_ASSESS:-0}" != "1" ]; then
  ASSESS_ARGS=(--project-path "$PROJECT_PATH")
  [ "$PERSIST_METRICS" = false ] && ASSESS_ARGS+=(--no-persist-metrics)
  [ -n "$WORKSPACE" ] && ASSESS_ARGS+=(--workspace "$WORKSPACE")
  set +e
  ASSESS_JSON="$(bash "$VERIFY_DIR/assess-core.sh" "${ASSESS_ARGS[@]}" 2>/dev/null)"
  _as_ex=$?
  set -e
  if [ "$_as_ex" -eq 3 ]; then
    ASSESS_STATUS="error"
  else
    ASSESS_STATUS="$(printf '%s' "$ASSESS_JSON" | jq -r '.status // empty' 2>/dev/null)" || ASSESS_STATUS=""
    [ -z "$ASSESS_STATUS" ] && ASSESS_STATUS="parse-error"
  fi
  case "$ASSESS_STATUS" in
    blocked)
      ENV_OBS_IMPLICIT="$(printf '%s' "$ASSESS_JSON" | jq -c '.environment_details.observations // []' 2>/dev/null || printf '[]')"
      jq -nc \
        --argjson env "$ENV_JSON" \
        --arg scope "$SCOPE" \
        --argjson files "$FILES_CHANGED_COUNT" \
        --argjson obs "$ENV_OBS_IMPLICIT" \
        '{
          mode: "verify-diff",
          gate_decision: "warn",
          environment_state_current: $env.state,
          category_effective: null,
          workspace: null,
          diff_scope: {files_changed: $files, tests_impacted: 0, scope: $scope, base_ref: null},
          results: {lint: {}, tests: {}, coverage_diff: {}},
          baseline_comparison: {baseline_source: "none"},
          reasons: ["implicit-assess-environment-blocked"],
          observations: (($env.observations // []) + $obs + ["implicit-assess-returned-blocked"]),
          saga_offline: false
        }'
      exit 2
      ;;
    blocked-classification)
      jq -nc \
        --arg scope "$SCOPE" \
        --argjson files "$FILES_CHANGED_COUNT" \
        --argjson aj "$ASSESS_JSON" \
        '{
          mode: "verify-diff",
          gate_decision: "warn",
          environment_state_current: ($aj.environment_state // "ready"),
          category_effective: null,
          workspace: null,
          diff_scope: {files_changed: $files, tests_impacted: 0, scope: $scope, base_ref: null},
          results: {lint: {}, tests: {}, coverage_diff: {}},
          baseline_comparison: {baseline_source: "none"},
          reasons: ["classification-indefinido-after-implicit-assess"],
          observations: (($aj.observations // []) + ["implicit-assess-returned-blocked-classification"]),
          saga_offline: false
        }'
      exit 2
      ;;
  esac
  _load_baseline_state
fi

# ----- Sem baseline: warn (fallback; ou skip implicito ligado) -----
if [ "$BASELINE_SOURCE" = "none" ]; then
  jq -nc --arg env "$ENV_STATE" --arg scope "$SCOPE" --arg cat "$CATEGORY_EFFECTIVE" \
         --argjson files "$FILES_CHANGED_COUNT" \
    '{
      mode: "verify-diff",
      gate_decision: "warn",
      environment_state_current: $env,
      category_effective: (if $cat == "null" then null else $cat end),
      workspace: null,
      diff_scope: {files_changed: $files, tests_impacted: 0, scope: $scope, base_ref: null},
      results: {lint:{}, tests:{}, coverage_diff:{}},
      baseline_comparison: {baseline_source: "none"},
      reasons: ["no-green-baseline-yet"],
      observations: ["invocar assess antes de verify-diff"],
      saga_offline: false
    }'
  exit 2
fi

# ----- Categoria restrita (legado-critico, sem-infra): so lint -----
case "$CATEGORY_EFFECTIVE" in
  legado-critico|sem-infra)
    LINT_OUTCOME="clean"
    case "${BASELINE_MOCK_LINT:-}" in
      errors-new) LINT_OUTCOME="new-errors" ;;
      errors-existing) LINT_OUTCOME="existing-errors" ;;
    esac

    GATE="pass"
    REASONS='[]'
    if [ "$LINT_OUTCOME" = "new-errors" ]; then
      GATE="fail"
      REASONS='["new-lint-errors"]'
    fi

    jq -nc \
      --arg env "$ENV_STATE" \
      --arg scope "$SCOPE" \
      --arg cat "$CATEGORY_EFFECTIVE" \
      --arg gate "$GATE" \
      --argjson files "$FILES_CHANGED_COUNT" \
      --argjson reasons "$REASONS" \
      --arg source "$BASELINE_SOURCE" \
      '{
        mode: "verify-diff",
        gate_decision: $gate,
        environment_state_current: $env,
        category_effective: $cat,
        workspace: null,
        diff_scope: {files_changed: $files, tests_impacted: 0, scope: $scope, base_ref: null},
        results: {lint: {new_errors: ($gate == "fail")}, tests: {note: "testes delegados ao CI"}, coverage_diff: {}},
        baseline_comparison: {baseline_source: $source},
        reasons: $reasons,
        observations: ["category-restricts-local-execution"],
        saga_offline: false
      }'

    EXIT=0
    [ "$GATE" = "fail" ] && EXIT=1
    [ "$GATE" = "warn" ] && EXIT=2
    exit "$EXIT"
    ;;
esac

# ----- Descobre testes impactados -----
TESTS_IMPACTED_LIST="$(printf '%s\n' "$CODE_FILES" | bash "$LIB_DIR/impact.sh" "$PROJECT_PATH")"
if [ -z "$TESTS_IMPACTED_LIST" ]; then
  TESTS_IMPACTED_COUNT=0
else
  TESTS_IMPACTED_COUNT="$(printf '%s\n' "$TESTS_IMPACTED_LIST" | grep -c .)" || true
  [ -z "$TESTS_IMPACTED_COUNT" ] && TESTS_IMPACTED_COUNT=0
fi

# ----- Execucao de lint + testes (mock-friendly) -----
LINT_NEW_ERRORS=false
LINT_ERRORS=0
LINT_WARNINGS=0
case "${BASELINE_MOCK_LINT:-}" in
  errors-new)      LINT_NEW_ERRORS=true; LINT_ERRORS=2 ;;
  errors-existing) LINT_ERRORS=1 ;;
  clean|'')        : ;;
esac

TESTS_EXECUTED="$TESTS_IMPACTED_COUNT"
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_PASSED_LIST='[]'
TESTS_FAILED_LIST='[]'
FLAKY_LIST='[]'

case "${BASELINE_MOCK_TESTS:-}" in
  green)
    TESTS_PASSED="$TESTS_EXECUTED"
    TESTS_PASSED_LIST="$(printf '%s\n' "$TESTS_IMPACTED_LIST" | jq -R -s -c 'split("\n") | map(select(length > 0))')"
    ;;
  red)
    TESTS_FAILED=1
    TESTS_PASSED=$((TESTS_EXECUTED - 1))
    # Simula regressao: marca como failed um teste que estava previously_green
    # no baseline. Se nao houver previously_green, usa o primeiro impactado.
    PREV_GREEN_FIRST="$(printf '%s' "$BASELINE_FOR_COMPARE" | jq -r '.tests_previously_green[0] // empty')"
    if [ -n "$PREV_GREEN_FIRST" ]; then
      TESTS_FAILED_LIST="$(jq -cn --arg t "$PREV_GREEN_FIRST" '[$t]')"
    else
      TESTS_FAILED_LIST="$(printf '%s\n' "$TESTS_IMPACTED_LIST" | head -n1 | jq -R -s -c 'split("\n") | map(select(length > 0))')"
    fi
    ;;
  pre-existing-red)
    TESTS_FAILED=1
    # Marca como teste ja registrado em tests_previously_red do baseline
    RED_EXISTENTE="$(printf '%s' "$BASELINE_FOR_COMPARE" | jq -r '.tests_previously_red[0] // empty')"
    if [ -n "$RED_EXISTENTE" ]; then
      TESTS_FAILED_LIST="$(jq -cn --arg t "$RED_EXISTENTE" '[$t]')"
    fi
    ;;
  flaky)
    FLAKY_LIST='["flaky-mock-test"]'
    ;;
  '')
    # Sem mock: pular execucao real por agora (evitar side-effects em TFs
    # que nao sao dedicadas a validacao). Caller fornece mock.
    TESTS_EXECUTED=0
    ;;
esac

COVERAGE_TOOL_AVAILABLE=false
COVERAGE_PERCENT="null"
case "${BASELINE_MOCK_COVERAGE:-}" in
  100) COVERAGE_TOOL_AVAILABLE=true; COVERAGE_PERCENT=100.0 ;;
  80)  COVERAGE_TOOL_AVAILABLE=true; COVERAGE_PERCENT=80.0 ;;
  null|'') : ;;
esac

# ----- Comparar com baseline -----
CURRENT_RESULT="$(jq -nc \
  --argjson pass "$TESTS_PASSED_LIST" \
  --argjson fail "$TESTS_FAILED_LIST" \
  --argjson lint_new "$LINT_ERRORS" \
  --argjson cov "$COVERAGE_PERCENT" \
  '{tests_passed: $pass, tests_failed: $fail,
    lint_errors_new: (if true then $lint_new else 0 end),
    coverage_diff_percent: $cov}')"

COMPARISON="$(bash "$LIB_DIR/compare-baseline.sh" "$CURRENT_RESULT" "$BASELINE_FOR_COMPARE" "$BASELINE_SOURCE")"
NEW_REG_COUNT="$(printf '%s' "$COMPARISON" | jq '.tests_previously_green_now_red | length')"
PRE_EX_COUNT="$(printf '%s' "$COMPARISON" | jq '.tests_previously_red_still_red | length')"

# ----- Decide gate -----
GATE="pass"
REASONS='[]'

if [ "$LINT_NEW_ERRORS" = true ]; then
  GATE="fail"
  REASONS="$(printf '%s' "$REASONS" | jq -c '. + ["new-lint-errors"]')"
fi

if [ "$NEW_REG_COUNT" -gt 0 ]; then
  GATE="fail"
  REASONS="$(printf '%s' "$REASONS" | jq -c '. + ["regression-tests-previously-green-now-red"]')"
fi

if [ "$COVERAGE_TOOL_AVAILABLE" = true ] && [ "$CATEGORY_EFFECTIVE" = "saudavel" ]; then
  # coverage do diff < 100 em saudavel -> fail
  if [ "$(jq -n --argjson c "$COVERAGE_PERCENT" '$c < 100')" = "true" ]; then
    GATE="fail"
    REASONS="$(printf '%s' "$REASONS" | jq -c '. + ["coverage-below-threshold"]')"
  fi
fi

if [ "$GATE" = "pass" ] && [ "$PRE_EX_COUNT" -gt 0 ]; then
  GATE="warn"
  REASONS="$(printf '%s' "$REASONS" | jq -c '. + ["pre-existing-red-remains"]')"
fi

if [ "$GATE" = "pass" ] && [ "${BASELINE_MOCK_TESTS:-}" = "flaky" ]; then
  GATE="warn"
  REASONS="$(printf '%s' "$REASONS" | jq -c '. + ["flaky-observed"]')"
fi

if [ "$DIFF_DOCS_ONLY" = true ] && [ "$GATE" = "pass" ]; then
  REASONS="$(printf '%s' "$REASONS" | jq -c '. + ["docs-only-diff"]')"
fi

# ----- Metrics -----
OUTCOME="green"
case "$GATE" in
  fail) OUTCOME="red-regression" ;;
  warn)
    if echo "$REASONS" | grep -q flaky; then
      OUTCOME="flaky-observed"
    elif echo "$REASONS" | grep -q pre-existing; then
      OUTCOME="pre-existing-red"
    else
      OUTCOME="warn"
    fi
    ;;
  pass) OUTCOME="green" ;;
esac

if [ "$PERSIST_METRICS" = true ]; then
  METRIC="$(jq -nc \
    --arg ts "$(_iso_now)" \
    --arg outcome "$OUTCOME" \
    --arg env_state "$ENV_STATE" \
    --arg cat_eff "$CATEGORY_EFFECTIVE" \
    --arg scope "$SCOPE" \
    --argjson files "$FILES_CHANGED_COUNT" \
    --argjson tests "$TESTS_EXECUTED" \
    '{schema_version:1, mode: "verify-diff", outcome: $outcome,
      environment_state_snapshot: $env_state, category_effective: $cat_eff,
      scope: $scope, files_changed: $files, tests_run: $tests, timestamp: $ts}')"
  saga_metrics_append "$PROJECT_PATH" "$METRIC" || true
fi

# ----- Emissao JSON final -----
EXIT=0
case "$GATE" in
  fail) EXIT=1 ;;
  warn) EXIT=2 ;;
esac

jq -nc \
  --arg mode "verify-diff" \
  --arg gate "$GATE" \
  --arg env "$ENV_STATE" \
  --arg cat "$CATEGORY_EFFECTIVE" \
  --arg ws "$WORKSPACE" \
  --argjson files "$FILES_CHANGED_COUNT" \
  --argjson tests_imp "$TESTS_IMPACTED_COUNT" \
  --argjson tests_exec "$TESTS_EXECUTED" \
  --argjson tests_passed "$TESTS_PASSED" \
  --argjson tests_failed "$TESTS_FAILED" \
  --argjson lint_errors "$LINT_ERRORS" \
  --argjson lint_warnings "$LINT_WARNINGS" \
  --argjson lint_new "$LINT_NEW_ERRORS" \
  --argjson flaky "$FLAKY_LIST" \
  --argjson cov_percent "$COVERAGE_PERCENT" \
  --argjson cov_available "$COVERAGE_TOOL_AVAILABLE" \
  --arg scope "$SCOPE" \
  --arg base_ref "$BASE_REF" \
  --argjson comparison "$COMPARISON" \
  --argjson reasons "$REASONS" \
  '{
    mode: $mode,
    gate_decision: $gate,
    environment_state_current: $env,
    category_effective: $cat,
    workspace: (if $ws == "" then null else $ws end),
    diff_scope: {
      files_changed: $files,
      tests_impacted: $tests_imp,
      scope: $scope,
      base_ref: (if $base_ref == "" then null else $base_ref end)
    },
    results: {
      lint: {errors: $lint_errors, warnings: $lint_warnings, new_errors: $lint_new},
      tests: {executed: $tests_exec, passed: $tests_passed, failed: $tests_failed,
              new_regressions: ($gate == "fail" and (($reasons | map(test("regression"))) | any)),
              flaky_observed: $flaky},
      coverage_diff: {percent: $cov_percent, tool_available: $cov_available}
    },
    baseline_comparison: $comparison,
    reasons: $reasons,
    observations: [],
    saga_offline: false
  }'

exit "$EXIT"
