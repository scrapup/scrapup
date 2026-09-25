#!/usr/bin/env bats
# Testes de verify-diff.sh e seus helpers (impact, compare-baseline)

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/verify-diff.sh"
LIB="$BATS_TEST_DIRNAME/../../scripts/lib"
FIXTURES="$BATS_TEST_DIRNAME/../fixtures/projects"

setup() {
  command -v jq >/dev/null 2>&1 || skip "jq nao instalado"
  export BASELINE_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
  export BASELINE_MOCK_NODE=ok
  export BASELINE_SKIP_DOCKER=1

  # Cria um projeto git local com baseline pre-semeada
  export PROJ="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$PROJ/src"
  cp "$FIXTURES/nestjs-saudavel/package.json" "$PROJ/"
  cp "$FIXTURES/nestjs-saudavel/tsconfig.json" "$PROJ/"
  echo 'export const a = 1;' > "$PROJ/src/a.ts"
  echo 'export const b = 2;' > "$PROJ/src/b.test.ts"
  (cd "$PROJ" && git init -q && git config user.email test@x && git config user.name test \
   && git add -A && git commit -q -m "init")

  # Semeia baseline-category=saudavel + baseline-current
  bash "$LIB/saga-client.sh" project-ensure "$PROJ" >/dev/null
  bash "$LIB/saga-client.sh" note-upsert "$PROJ" "baseline-category" "context" \
    '{"schema_version":1,"category":"saudavel","classified_by":"auto"}'
  bash "$LIB/saga-client.sh" note-upsert "$PROJ" "baseline-current" "context" \
    '{"schema_version":1,"tests_count":{"total":10,"passed":10,"failed":0,"skipped":0},"coverage_global":{"lines":95.0}}'
  bash "$LIB/saga-client.sh" note-upsert "$PROJ" "baseline-latest" "context" \
    '{"schema_version":1,"outcome":"green","tests_previously_green":["src/a.test.ts"],"tests_previously_red":[]}'
}

_commit_change() {
  local msg="$1"
  (cd "$PROJ" && git add -A && git commit -q -m "$msg")
}

@test "impact.sh mapeia source -> teste co-localizado" {
  echo "src/payment.ts" > "$BATS_TEST_TMPDIR/changed"
  mkdir -p "$PROJ/src"
  touch "$PROJ/src/payment.test.ts"
  result="$(cat "$BATS_TEST_TMPDIR/changed" | bash "$LIB/impact.sh" "$PROJ")"
  echo "$result" | grep -q "src/payment.test.ts"
}

@test "impact.sh retorna o proprio arquivo quando ja e teste" {
  result="$(echo "src/foo.test.ts" | bash "$LIB/impact.sh" "$PROJ")"
  [ "$result" = "src/foo.test.ts" ]
}

@test "verify-diff sem mudancas -> pass com diff vazio" {
  run bash "$SCRIPT" --project-path "$PROJ" --scope=commit --no-persist-metrics
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.gate_decision == "pass"' >/dev/null
  echo "$output" | jq -e '.reasons | index("empty-diff") != null' >/dev/null
}

@test "verify-diff com mudanca em codigo + mock tests=green -> pass" {
  echo 'export const c = 3;' > "$PROJ/src/a.ts"
  _commit_change "change a.ts"
  export BASELINE_MOCK_TESTS=green
  export BASELINE_MOCK_LINT=clean
  export BASELINE_MOCK_COVERAGE=100
  run bash "$SCRIPT" --project-path "$PROJ" --scope=commit --no-persist-metrics
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.gate_decision == "pass"' >/dev/null
  echo "$output" | jq -e '.diff_scope.files_changed > 0' >/dev/null
}

@test "verify-diff + regressao nova -> gate=fail, exit 1" {
  # Modifica um teste que estava green e forca red
  echo 'export const c = 3;' > "$PROJ/src/a.ts"
  _commit_change "regressive"
  export BASELINE_MOCK_TESTS=red
  run bash "$SCRIPT" --project-path "$PROJ" --scope=commit --no-persist-metrics
  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.gate_decision == "fail"' >/dev/null
  echo "$output" | jq -e '.reasons | map(test("regression")) | any' >/dev/null
}

@test "verify-diff + falha pre-existente -> gate=warn, exit 2" {
  # Semeia baseline-latest com teste ja vermelho
  bash "$LIB/saga-client.sh" note-upsert "$PROJ" "baseline-latest" "context" \
    '{"schema_version":1,"outcome":"red-known","tests_previously_green":[],"tests_previously_red":["src/broken.test.ts"]}'
  echo 'x' > "$PROJ/src/a.ts"
  _commit_change "ok"
  export BASELINE_MOCK_TESTS=pre-existing-red
  run bash "$SCRIPT" --project-path "$PROJ" --scope=commit --no-persist-metrics
  [ "$status" -eq 2 ]
  echo "$output" | jq -e '.gate_decision == "warn"' >/dev/null
}

@test "verify-diff novo lint error -> fail" {
  echo 'x' > "$PROJ/src/a.ts"
  _commit_change "ok"
  export BASELINE_MOCK_TESTS=green
  export BASELINE_MOCK_LINT=errors-new
  run bash "$SCRIPT" --project-path "$PROJ" --scope=commit --no-persist-metrics
  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.gate_decision == "fail"' >/dev/null
  echo "$output" | jq -e '.results.lint.new_errors == true' >/dev/null
}

@test "verify-diff em legado-critico so roda lint; testes delegados ao CI" {
  bash "$LIB/saga-client.sh" note-upsert "$PROJ" "baseline-category" "context" \
    '{"schema_version":1,"category":"legado-critico","classified_by":"auto"}'
  echo 'x' > "$PROJ/src/a.ts"
  _commit_change "ok"
  run bash "$SCRIPT" --project-path "$PROJ" --scope=commit --no-persist-metrics
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.gate_decision == "pass"' >/dev/null
  echo "$output" | jq -e '.observations | index("category-restricts-local-execution") != null' >/dev/null
}

@test "verify-diff em env=blocked -> warn imediato, exit 2" {
  unset BASELINE_SKIP_DOCKER
  unset BASELINE_MOCK_NODE
  export BASELINE_SKIP_NODE=0
  # Forca blocked via node ausente simulado
  export BASELINE_SKIP_NODE=0
  # Alternativa: criar projeto sem node_modules e sem mock -> check-environment block
  mkdir -p "$BATS_TEST_TMPDIR/blocked-proj/src"
  cd "$BATS_TEST_TMPDIR/blocked-proj" && git init -q 2>/dev/null
  # Nao tem package.json, mas check-environment blocked so dispara com node ausente
  # Simulamos usando PATH que remove node
  skip "Estado blocked e coberto em check-environment.bats; verify-diff propaga via env_json"
}

@test "verify-diff sem baseline dispara assess implicito e completa gate" {
  # Repo sem package.json classifica como sem-infra; assess grava baseline-latest
  # e verify-diff prossegue (gate calibrado para sem-infra).
  mkdir -p "$BATS_TEST_TMPDIR/novo-proj/src"
  echo 'const a=1;' > "$BATS_TEST_TMPDIR/novo-proj/src/a.ts"
  (cd "$BATS_TEST_TMPDIR/novo-proj" && git init -q && git config user.email t@t && git config user.name t \
    && git add -A && git commit -q -m "init")
  echo 'const a=2;' > "$BATS_TEST_TMPDIR/novo-proj/src/a.ts"
  (cd "$BATS_TEST_TMPDIR/novo-proj" && git add -A && git commit -q -m "change")
  export BASELINE_MOCK_TESTS=green
  export BASELINE_MOCK_LINT=clean
  export BASELINE_MOCK_COVERAGE=100
  run bash "$SCRIPT" --project-path "$BATS_TEST_TMPDIR/novo-proj" --scope=commit --no-persist-metrics
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.gate_decision == "pass"' >/dev/null
  echo "$output" | jq -e '.baseline_comparison.baseline_source != "none"' >/dev/null
  echo "$output" | jq -e '.category_effective == "sem-infra"' >/dev/null
}

@test "verify-diff sem baseline e skip implicito -> warn com no-green-baseline-yet" {
  mkdir -p "$BATS_TEST_TMPDIR/novo-proj2/src"
  cp "$FIXTURES/nestjs-saudavel/package.json" "$BATS_TEST_TMPDIR/novo-proj2/"
  cp "$FIXTURES/nestjs-saudavel/tsconfig.json" "$BATS_TEST_TMPDIR/novo-proj2/"
  echo 'const a=1;' > "$BATS_TEST_TMPDIR/novo-proj2/src/a.ts"
  (cd "$BATS_TEST_TMPDIR/novo-proj2" && git init -q && git config user.email t@t && git config user.name t \
    && git add -A && git commit -q -m "init")
  echo 'const a=2;' > "$BATS_TEST_TMPDIR/novo-proj2/src/a.ts"
  (cd "$BATS_TEST_TMPDIR/novo-proj2" && git add -A && git commit -q -m "change")
  export BASELINE_VERIFY_DIFF_SKIP_IMPLICIT_ASSESS=1
  run bash "$SCRIPT" --project-path "$BATS_TEST_TMPDIR/novo-proj2" --scope=commit --no-persist-metrics
  unset BASELINE_VERIFY_DIFF_SKIP_IMPLICIT_ASSESS
  [ "$status" -eq 2 ]
  echo "$output" | jq -e '.gate_decision == "warn"' >/dev/null
  echo "$output" | jq -e '.reasons | index("no-green-baseline-yet") != null' >/dev/null
}

@test "verify-diff docs-only diff -> pass com observacao" {
  echo '# README' > "$PROJ/README.md"
  _commit_change "docs"
  run bash "$SCRIPT" --project-path "$PROJ" --scope=commit --no-persist-metrics
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.gate_decision == "pass"' >/dev/null
}
