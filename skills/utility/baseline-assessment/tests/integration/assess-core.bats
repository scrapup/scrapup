#!/usr/bin/env bats
# Testes de assess-core.sh

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/assess-core.sh"
LIB="$BATS_TEST_DIRNAME/../../scripts/lib"
FIXTURES="$BATS_TEST_DIRNAME/../fixtures/projects"

setup() {
  command -v jq >/dev/null 2>&1 || skip "jq nao instalado"
  export BASELINE_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
  export BASELINE_MOCK_NODE=ok
  export BASELINE_SKIP_DOCKER=1

  # Copia fixture para area temporaria para isolar estado.
  export FIX="$BATS_TEST_TMPDIR/proj-nestjs"
  cp -r "$FIXTURES/nestjs-saudavel" "$FIX"

  # Semeia category-confirmation para destravar classify=indefinido (falta de
  # node_modules). Nao afeta testes que validam classificacao automatica em
  # outros fixtures.
  bash "$LIB/saga-client.sh" project-ensure "$FIX" >/dev/null
  bash "$LIB/saga-client.sh" note-upsert "$FIX" "category-confirmation" "context" \
    '{"category_confirmed":"saudavel","reason":"fixture","confirmed_at":"2026-04-19T00:00:00Z"}'
}

@test "assess com mock=green -> status=green e baseline-current + baseline-latest persistidos" {
  export BASELINE_MOCK_SUITE=green
  run bash "$SCRIPT" --project-path "$FIX" --no-persist-metrics
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "green"' >/dev/null
  echo "$output" | jq -e '.baseline_current != null' >/dev/null
  echo "$output" | jq -e '.baseline_latest != null' >/dev/null
  echo "$output" | jq -e '.baseline_latest.outcome == "green"' >/dev/null
  echo "$output" | jq -e '.baseline_latest.coverage_global.lines == 92.4' >/dev/null

  current="$(bash "$LIB/cache-local.sh" get "$FIX" "baseline-current")"
  [ "$current" != "null" ]
  latest="$(bash "$LIB/cache-local.sh" get "$FIX" "baseline-latest")"
  [ "$latest" != "null" ]
}

@test "assess com mock=red -> status=red-known; baseline-current NAO atualizado" {
  export BASELINE_MOCK_SUITE=red
  run bash "$SCRIPT" --project-path "$FIX" --no-persist-metrics
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "red-known"' >/dev/null
  echo "$output" | jq -e '.baseline_latest.outcome == "red-known"' >/dev/null
  echo "$output" | jq -e '.baseline_latest.tests_previously_red | length > 0' >/dev/null
}

@test "assess em projeto sem package.json -> sem-infra, status=no-execution" {
  run bash "$SCRIPT" --project-path "$FIXTURES/sem-package-json" --no-persist-metrics --skip-suite
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "no-execution"' >/dev/null
  echo "$output" | jq -e '.category == "sem-infra"' >/dev/null
}

@test "assess classificacao indefinida -> blocked-classification + exit 1" {
  # Fixture sem override: node_modules ausente -> classify=indefinido
  FIX_NOVERR="$BATS_TEST_TMPDIR/proj-indef"
  cp -r "$FIXTURES/nestjs-saudavel" "$FIX_NOVERR"
  run bash "$SCRIPT" --project-path "$FIX_NOVERR" --no-persist-metrics --skip-suite
  [ "$status" -eq 1 ]
  echo "$output" | jq -e '.status == "blocked-classification"' >/dev/null
  echo "$output" | jq -e '.category == "indefinido"' >/dev/null
  echo "$output" | jq -e '.category_effective == null' >/dev/null
}

@test "assess cache-hit em segunda execucao com mesmo hash" {
  export BASELINE_MOCK_SUITE=green
  run bash "$SCRIPT" --project-path "$FIX" --no-persist-metrics
  [ "$status" -eq 0 ]
  run bash "$SCRIPT" --project-path "$FIX" --no-persist-metrics --skip-suite
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "cached"' >/dev/null
}

@test "assess --force ignora cache" {
  export BASELINE_MOCK_SUITE=green
  run bash "$SCRIPT" --project-path "$FIX" --no-persist-metrics
  [ "$status" -eq 0 ]
  run bash "$SCRIPT" --project-path "$FIX" --no-persist-metrics --force
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.status == "green"' >/dev/null
}

@test "assess em docker-dependent com docker off -> category_effective=legado-critico" {
  unset BASELINE_SKIP_DOCKER
  export BASELINE_MOCK_DOCKER=fail
  FIX_DOCK="$BATS_TEST_TMPDIR/proj-docker"
  cp -r "$FIXTURES/legado-docker-dependent" "$FIX_DOCK"
  run bash "$SCRIPT" --project-path "$FIX_DOCK" --no-persist-metrics --skip-suite
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.category == "legado-docker-dependent"' >/dev/null
  echo "$output" | jq -e '.category_effective == "legado-critico"' >/dev/null
  echo "$output" | jq -e '.environment_state == "partial"' >/dev/null
}

@test "category_effective nunca e persistida em baseline-category (RN-27)" {
  export BASELINE_MOCK_SUITE=green
  run bash "$SCRIPT" --project-path "$FIX" --no-persist-metrics
  [ "$status" -eq 0 ]
  note="$(bash "$LIB/cache-local.sh" get "$FIX" "baseline-category")"
  echo "$note" | jq -e '.content | has("category_effective") | not' >/dev/null
}

@test "assess emite JSON com campos do contrato plan.md 4.2" {
  export BASELINE_MOCK_SUITE=green
  run bash "$SCRIPT" --project-path "$FIX" --no-persist-metrics
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.mode == "assess"' >/dev/null
  echo "$output" | jq -e '.status' >/dev/null
  echo "$output" | jq -e '.environment_state' >/dev/null
  echo "$output" | jq -e 'has("category")' >/dev/null
  echo "$output" | jq -e 'has("category_effective")' >/dev/null
  echo "$output" | jq -e 'has("baseline_current")' >/dev/null
  echo "$output" | jq -e 'has("baseline_latest")' >/dev/null
  echo "$output" | jq -e 'has("observations")' >/dev/null
}
