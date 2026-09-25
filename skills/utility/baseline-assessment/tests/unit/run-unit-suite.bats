#!/usr/bin/env bats
# Testes unitarios de run-unit-suite.sh (parsing)

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/lib/run-unit-suite.sh"
FIXTURES="$BATS_TEST_DIRNAME/../fixtures/runner-output"

setup() {
  command -v jq >/dev/null 2>&1 || skip "jq nao instalado"
}

@test "parse-jest extrai contagem e identificadores de testes verdes" {
  run bash "$SCRIPT" --parse-jest "$FIXTURES/jest-results-green.json" "/tmp/proj"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.tests_count.total == 3' >/dev/null
  echo "$output" | jq -e '.tests_count.passed == 3' >/dev/null
  echo "$output" | jq -e '.tests_count.failed == 0' >/dev/null
  echo "$output" | jq -e '.tests_previously_green | length == 3' >/dev/null
  echo "$output" | jq -e '.tests_previously_green[0] | test("payment.service.spec.ts::")' >/dev/null
}

@test "parse-jest extrai testes vermelhos" {
  run bash "$SCRIPT" --parse-jest "$FIXTURES/jest-results-red.json" "/tmp/proj"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.tests_count.failed == 1' >/dev/null
  echo "$output" | jq -e '.tests_previously_red[0] | test("handles negative amount")' >/dev/null
}

@test "parse-coverage extrai percentuais globais" {
  run bash "$SCRIPT" --parse-coverage "$FIXTURES/coverage-summary.json"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.lines == 92.5' >/dev/null
  echo "$output" | jq -e '.branches == 75' >/dev/null
  echo "$output" | jq -e '.functions == 100' >/dev/null
}

@test "sem test-cmd retorna no-test-script" {
  run bash "$SCRIPT" --project-path "." --runner jest --test-cmd ""
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.outcome == "no-test-script"' >/dev/null
}
