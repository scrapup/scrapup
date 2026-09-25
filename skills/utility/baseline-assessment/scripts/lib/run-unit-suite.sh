#!/usr/bin/env bash
# run-unit-suite.sh — executa testes unitarios e extrai baseline + coverage.
#
# Uso operacional:
#   run-unit-suite.sh --project-path <dir> --runner <jest|vitest|mocha|none>
#       --test-cmd "<cmd>" [--cov-cmd "<cmd>"] [--workspace <ws>]
#       [--timeout-seconds <n>]
#
# Uso de teste (parsing isolado):
#   run-unit-suite.sh --parse-jest <results.json> [--project-path <dir>]
#   run-unit-suite.sh --parse-coverage <coverage-summary.json>
#
# Saida JSON (stdout):
#   outcome, tests_count, tests_previously_red, tests_previously_green,
#   coverage_global, tests_runtime_ms, observations

set -euo pipefail

_parse_jest_json() {
  local file="$1"
  local project_path="${2:-.}"
  if [ ! -f "$file" ]; then
    jq -nc '{tests_count:{total:0,passed:0,failed:0,skipped:0},tests_previously_red:[],tests_previously_green:[],observations:["jest-json-ausente"]}'
    return
  fi
  jq -nc --arg pp "$project_path" --slurpfile j "$file" '
    ($j[0]) as $r |
    {
      tests_count: {
        total: ($r.numTotalTests // 0),
        passed: ($r.numPassedTests // 0),
        failed: ($r.numFailedTests // 0),
        skipped: (($r.numPendingTests // 0) + ($r.numTodoTests // 0))
      },
      tests_previously_red: [
        $r.testResults[]? |
        .name as $f |
        ($f | if startswith($pp) then .[($pp | length):] | ltrimstr("/") else $f end) as $rel |
        .assertionResults[]? | select(.status == "failed") | ($rel + "::" + .fullName)
      ],
      tests_previously_green: [
        $r.testResults[]? |
        .name as $f |
        ($f | if startswith($pp) then .[($pp | length):] | ltrimstr("/") else $f end) as $rel |
        .assertionResults[]? | select(.status == "passed") | ($rel + "::" + .fullName)
      ],
      observations: []
    }
  '
}

_parse_vitest_json() {
  local file="$1"
  local project_path="${2:-.}"
  if [ ! -f "$file" ]; then
    jq -nc '{tests_count:{total:0,passed:0,failed:0,skipped:0},tests_previously_red:[],tests_previously_green:[],observations:["vitest-json-ausente"]}'
    return
  fi
  # Vitest json reporter: array de ficheiros ou objeto estilo jest.
  jq -nc --arg pp "$project_path" --slurpfile raw "$file" '
    def vitest_file($f):
      if ($f | type) == "array" then $f[]
      elif ($f.testResults // null) != null then $f.testResults[]
      else empty end;
    ($raw[0]) as $root |
    [vitest_file($root)] as $files |
    {
      tests_count: {
        total: ([$files[] | .assertionResults[]?] | length),
        passed: ([$files[] | .assertionResults[]? | select(.status == "passed")] | length),
        failed: ([$files[] | .assertionResults[]? | select(.status == "failed")] | length),
        skipped: ([$files[] | .assertionResults[]? | select(.status == "skipped" or .status == "pending")] | length)
      },
      tests_previously_red: [
        $files[] |
        (.name // .file // "unknown") as $f |
        ($f | if startswith($pp) then .[($pp | length):] | ltrimstr("/") else $f end) as $rel |
        .assertionResults[]? | select(.status == "failed") |
        ($rel + "::" + (.fullName // .title // "unnamed"))
      ],
      tests_previously_green: [
        $files[] |
        (.name // .file // "unknown") as $f |
        ($f | if startswith($pp) then .[($pp | length):] | ltrimstr("/") else $f end) as $rel |
        .assertionResults[]? | select(.status == "passed") |
        ($rel + "::" + (.fullName // .title // "unnamed"))
      ],
      observations: []
    }
  '
}

_parse_coverage_summary() {
  local file="$1"
  if [ ! -f "$file" ]; then
    printf 'null'
    return
  fi
  jq -c '
    if (.total // null) == null then null
    else {
      lines: (.total.lines.pct // 0),
      branches: (.total.branches.pct // 0),
      functions: (.total.functions.pct // 0),
      statements: (.total.statements.pct // 0)
    } end
  ' "$file" 2>/dev/null || printf 'null'
}

_timeout_bin() {
  if command -v timeout >/dev/null 2>&1; then
    printf 'timeout'
  elif command -v gtimeout >/dev/null 2>&1; then
    printf 'gtimeout'
  else
    printf ''
  fi
}

_run_in_project() {
  local target_dir="$1"
  local timeout_sec="$2"
  local cmd="$3"
  local timeout_bin
  timeout_bin="$(_timeout_bin)"
  (
    cd "$target_dir"
    if [ -d "./node_modules/.bin" ]; then
      export PATH="$(pwd)/node_modules/.bin:$PATH"
    fi
    if [ -n "$timeout_bin" ]; then
      "$timeout_bin" "$timeout_sec" bash -c "$cmd"
    else
      bash -c "$cmd"
    fi
  )
}

# Constroi comando com reporter JSON e coverage quando o runner e conhecido.
_build_runner_cmd() {
  local runner="$1"
  local base_cmd="$2"
  local results_json="$3"
  local cov_dir="$4"
  local want_cov="$5"

  case "$runner" in
    jest)
      if [[ "$base_cmd" =~ ^jest([[:space:]]|$) ]]; then
        local extra_args="${base_cmd#jest}"
        extra_args="${extra_args# }"
        local cmd="jest --json --outputFile=\"$results_json\" --passWithNoTests"
        if [ -n "$extra_args" ]; then
          cmd="$cmd $extra_args"
        fi
        if [ "$want_cov" = true ]; then
          cmd="$cmd --coverage --coverageReporters=json-summary --coverageDirectory=\"$cov_dir\""
        fi
        printf '%s' "$cmd"
        return 0
      fi
      ;;
    vitest)
      if [[ "$base_cmd" =~ ^vitest([[:space:]]|$) ]]; then
        local cmd="$base_cmd --reporter=json --outputFile=\"$results_json\""
        if [ "$want_cov" = true ]; then
          cmd="$cmd --coverage"
        fi
        printf '%s' "$cmd"
        return 0
      fi
      ;;
  esac
  printf '%s' "$base_cmd"
  return 1
}

_emit_result() {
  local outcome="$1"
  local tests_count="$2"
  local red="$3"
  local green="$4"
  local cov="$5"
  local runtime="$6"
  local obs="$7"
  jq -nc \
    --arg outcome "$outcome" \
    --argjson count "$tests_count" \
    --argjson red "$red" \
    --argjson green "$green" \
    --argjson cov "$cov" \
    --arg runtime "$runtime" \
    --argjson obs "$obs" \
    '{
      outcome: $outcome,
      tests_count: $count,
      tests_previously_red: $red,
      tests_previously_green: $green,
      coverage_global: (if $cov == null then null else $cov end),
      tests_runtime_ms: ($runtime | tonumber),
      observations: $obs
    }'
}

# ----- Modo parse-only (testes unitarios) -----
if [ "${1:-}" = "--parse-jest" ]; then
  _parse_jest_json "${2:?}" "${3:-.}"
  exit 0
fi
if [ "${1:-}" = "--parse-coverage" ]; then
  _parse_coverage_summary "${2:?}"
  exit 0
fi
if [ "${1:-}" = "--parse-vitest" ]; then
  _parse_vitest_json "${2:?}" "${3:-.}"
  exit 0
fi

# ----- Modo operacional -----
PROJECT_PATH="."
WORKSPACE=""
RUNNER="none"
TEST_CMD=""
COV_CMD=""
TIMEOUT_SECONDS=600

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --project-path=*) PROJECT_PATH="${1#*=}"; shift ;;
    --workspace) WORKSPACE="$2"; shift 2 ;;
    --workspace=*) WORKSPACE="${1#*=}"; shift ;;
    --runner) RUNNER="$2"; shift 2 ;;
    --runner=*) RUNNER="${1#*=}"; shift ;;
    --test-cmd) TEST_CMD="$2"; shift 2 ;;
    --test-cmd=*) TEST_CMD="${1#*=}"; shift ;;
    --cov-cmd) COV_CMD="$2"; shift 2 ;;
    --cov-cmd=*) COV_CMD="${1#*=}"; shift ;;
    --timeout-seconds) TIMEOUT_SECONDS="$2"; shift 2 ;;
    --timeout-seconds=*) TIMEOUT_SECONDS="${1#*=}"; shift ;;
    --help|-h)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      printf 'run-unit-suite.sh: flag desconhecida: %s\n' "$1" >&2
      exit 3
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  printf 'run-unit-suite.sh: jq ausente\n' >&2
  exit 3
fi

if [ -z "$TEST_CMD" ]; then
  _emit_result "no-test-script" \
    '{"total":0,"passed":0,"failed":0,"skipped":0}' \
    '[]' '[]' 'null' 0 '["test-script-ausente"]'
  exit 0
fi

TARGET_DIR="$PROJECT_PATH"
if [ -n "$WORKSPACE" ]; then
  TARGET_DIR="$PROJECT_PATH/$WORKSPACE"
fi

TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/baseline-unit.XXXXXX")"
trap 'rm -rf "$TMP_DIR"' EXIT

RESULTS_JSON="$TMP_DIR/results.json"
COV_DIR="$TMP_DIR/coverage"
mkdir -p "$COV_DIR"

# Preferir script de coverage (test:cov) quando disponivel: uma unica execucao.
EXEC_CMD="$TEST_CMD"
WANT_COV=false
if [ -n "$COV_CMD" ]; then
  EXEC_CMD="$COV_CMD"
  WANT_COV=true
fi

BUILT_CMD=""
STRUCTURED=false
if BUILT_CMD="$(_build_runner_cmd "$RUNNER" "$EXEC_CMD" "$RESULTS_JSON" "$COV_DIR" "$WANT_COV")"; then
  STRUCTURED=true
else
  BUILT_CMD="$EXEC_CMD"
fi

OBS='[]'
if [ "$STRUCTURED" = false ]; then
  OBS="$(jq -nc '["runner-output-not-parsed"]')"
fi

_start_seconds() { date +%s; }

start_s="$(_start_seconds)"
set +e
_run_in_project "$TARGET_DIR" "$TIMEOUT_SECONDS" "$BUILT_CMD" >/dev/null 2>&1
rc=$?
set -e
end_s="$(_start_seconds)"
RUNTIME_MS=$(( (end_s - start_s) * 1000 ))

TIMEOUT_BIN="$(_timeout_bin)"
if [ "$rc" -eq 124 ] && [ -n "$TIMEOUT_BIN" ]; then
  _emit_result "timeout" \
    '{"total":0,"passed":0,"failed":0,"skipped":0}' \
    '[]' '[]' 'null' "$RUNTIME_MS" \
    "$(jq -nc '["suite-timeout"]')"
  exit 0
fi

PARSED='null'
case "$RUNNER" in
  jest) PARSED="$(_parse_jest_json "$RESULTS_JSON" "$TARGET_DIR")" ;;
  vitest) PARSED="$(_parse_vitest_json "$RESULTS_JSON" "$TARGET_DIR")" ;;
  *)
    if [ "$STRUCTURED" = false ]; then
      PARSED="$(jq -nc '{tests_count:{total:0,passed:0,failed:0,skipped:0},tests_previously_red:[],tests_previously_green:[],observations:[]}')"
    fi
    ;;
esac

TESTS_COUNT='{"total":0,"passed":0,"failed":0,"skipped":0}'
TESTS_RED='[]'
TESTS_GREEN='[]'
if [ "$PARSED" != "null" ] && [ -n "$PARSED" ]; then
  TESTS_COUNT="$(printf '%s' "$PARSED" | jq -c '.tests_count')"
  TESTS_RED="$(printf '%s' "$PARSED" | jq -c '.tests_previously_red')"
  TESTS_GREEN="$(printf '%s' "$PARSED" | jq -c '.tests_previously_green')"
  PARSE_OBS="$(printf '%s' "$PARSED" | jq -c '.observations // []')"
  OBS="$(jq -nc --argjson a "$OBS" --argjson b "$PARSE_OBS" '$a + $b')"
fi

COVERAGE_GLOBAL='null'
if [ "$WANT_COV" = true ]; then
  COV_FILE=""
  for candidate in \
    "$COV_DIR/coverage-summary.json" \
    "$TARGET_DIR/coverage/coverage-summary.json" \
    "$COV_DIR/coverage/coverage-summary.json"; do
    if [ -f "$candidate" ]; then
      COV_FILE="$candidate"
      break
    fi
  done
  if [ -n "$COV_FILE" ]; then
    COVERAGE_GLOBAL="$(_parse_coverage_summary "$COV_FILE")"
  else
    OBS="$(jq -nc --argjson o "$OBS" '$o + ["coverage-summary-ausente"]')"
  fi
fi

FAILED_COUNT="$(printf '%s' "$TESTS_COUNT" | jq -r '.failed // 0')"
PASSED_COUNT="$(printf '%s' "$TESTS_COUNT" | jq -r '.passed // 0')"

OUTCOME="red-known"
if [ "$rc" -eq 0 ] && [ "$FAILED_COUNT" -eq 0 ]; then
  OUTCOME="green"
elif [ "$rc" -eq 0 ] && [ "$FAILED_COUNT" -gt 0 ]; then
  OUTCOME="red-known"
elif [ "$rc" -ne 0 ] && [ "$STRUCTURED" = false ]; then
  OUTCOME="red-known"
  OBS="$(jq -nc --argjson o "$OBS" '$o + ["suite-exit-nonzero-sem-parse"]')"
elif [ "$rc" -ne 0 ] && [ "$FAILED_COUNT" -eq 0 ] && [ "$PASSED_COUNT" -eq 0 ]; then
  OUTCOME="red-known"
  OBS="$(jq -nc --argjson o "$OBS" '$o + ["suite-exit-nonzero"]')"
elif [ "$rc" -ne 0 ] && [ "$FAILED_COUNT" -gt 0 ]; then
  OUTCOME="red-known"
fi

_emit_result "$OUTCOME" "$TESTS_COUNT" "$TESTS_RED" "$TESTS_GREEN" \
  "$COVERAGE_GLOBAL" "$RUNTIME_MS" "$OBS"
