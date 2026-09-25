#!/usr/bin/env bash
# compare-baseline.sh — compara resultado corrente com baseline (current/latest)
# e calcula deltas relevantes para decidir gate_decision (RN-17).
#
# Uso:
#   compare-baseline.sh '<current_result_json>' '<baseline_json>' '<baseline_source>'
#
# current_result_json:
#   { "tests_passed": [...], "tests_failed": [...], "lint_errors_new": int,
#     "coverage_diff_percent": number|null }
#
# baseline_json:
#   { "tests_previously_green": [...], "tests_previously_red": [...],
#     "coverage_global": {...}|null, ... }
#
# baseline_source: "baseline-current" | "baseline-latest" | "none"
#
# Saida (stdout JSON):
#   {
#     "tests_previously_green_now_red": [...],
#     "tests_previously_red_still_red": [...],
#     "tests_previously_red_now_green": [...],
#     "lint_errors_delta": "+0"|"+N"|"-N",
#     "coverage_global_delta": "+0.0"|"+x.x"|"-x.x",
#     "baseline_source": "..."
#   }

set -euo pipefail

current="${1:-}"
baseline="${2:-}"
baseline_source="${3:-none}"

if [ -z "$current" ] || [ -z "$baseline" ]; then
  printf 'compare-baseline.sh: argumentos obrigatorios\n' >&2
  exit 3
fi

command -v jq >/dev/null 2>&1 || { printf 'compare-baseline.sh: jq ausente\n' >&2; exit 3; }

jq -nc \
  --argjson cur "$current" \
  --argjson base "$baseline" \
  --arg source "$baseline_source" \
  '
  def list_of_strings: if . == null then [] else . end;
  ($cur.tests_passed // []) as $cur_pass |
  ($cur.tests_failed // []) as $cur_fail |
  ($base.tests_previously_green // []) as $was_green |
  ($base.tests_previously_red // []) as $was_red |

  {
    tests_previously_green_now_red: ($cur_fail | map(select(. as $t | $was_green | index($t) != null))),
    tests_previously_red_still_red: ($cur_fail | map(select(. as $t | $was_red | index($t) != null))),
    tests_previously_red_now_green: ($cur_pass | map(select(. as $t | $was_red | index($t) != null))),
    lint_errors_delta: ($cur.lint_errors_new // 0 | if . == 0 then "+0" elif . > 0 then "+\(.)" else "\(.)" end),
    coverage_global_delta: (
      if ($cur.coverage_diff_percent // null) == null then "+0.0"
      else
        ($cur.coverage_diff_percent) as $d |
        if $d >= 0 then "+\($d)" else "\($d)" end
      end
    ),
    baseline_source: $source
  }
  '
