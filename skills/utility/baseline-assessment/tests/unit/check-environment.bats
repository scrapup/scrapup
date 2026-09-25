#!/usr/bin/env bats
# Testes de check-environment.sh

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/check-environment.sh"
FIXTURES="$BATS_TEST_DIRNAME/../fixtures/projects"

setup() {
  command -v jq >/dev/null 2>&1 || skip "jq nao instalado"
  unset BASELINE_MOCK_DOCKER BASELINE_MOCK_NODE BASELINE_MOCK_SUITE BASELINE_MOCK_TESTS \
    BASELINE_SKIP_DOCKER BASELINE_SKIP_NODE BASELINE_VERIFY_DIFF_SKIP_IMPLICIT_ASSESS
  export BASELINE_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
}

@test "projeto sem Docker + mock node ok -> state=ready" {
  export BASELINE_MOCK_NODE=ok
  run bash "$SCRIPT" --project-path "$FIXTURES/vitest-saudavel" --skip-docker
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.state == "ready"' >/dev/null
  echo "$output" | jq -e '.docker_required == false' >/dev/null
  echo "$output" | jq -e '.node_version == "20.11.1"' >/dev/null
}

@test "projeto com Docker + mock docker fail -> state=partial" {
  export BASELINE_MOCK_NODE=ok
  export BASELINE_MOCK_DOCKER=fail
  run bash "$SCRIPT" --project-path "$FIXTURES/legado-docker-dependent"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.state == "partial"' >/dev/null
  echo "$output" | jq -e '.docker_required == true' >/dev/null
  echo "$output" | jq -e '.docker_available == false' >/dev/null
  echo "$output" | jq -e '.observations | map(test("docker-start-failed")) | any' >/dev/null
}

@test "mock node fail -> state=partial (npm_install false)" {
  export BASELINE_MOCK_DOCKER=ok
  export BASELINE_MOCK_NODE=fail
  run bash "$SCRIPT" --project-path "$FIXTURES/nestjs-saudavel" --skip-docker
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.state == "partial"' >/dev/null
  echo "$output" | jq -e '.npm_install_ok == false' >/dev/null
}

@test "persiste environment-state como note" {
  export BASELINE_MOCK_NODE=ok
  run bash "$SCRIPT" --project-path "$FIXTURES/vitest-saudavel" --skip-docker
  [ "$status" -eq 0 ]
  LIB="$BATS_TEST_DIRNAME/../../scripts/lib"
  note="$(bash "$LIB/cache-local.sh" get "$FIXTURES/vitest-saudavel" "environment-state")"
  echo "$note" | jq -e '.content.state == "ready"' >/dev/null
}

@test "nao persiste NPM_TOKEN na note" {
  export BASELINE_MOCK_NODE=ok
  export NPM_TOKEN="segredo-nao-deve-vazar"
  run bash "$SCRIPT" --project-path "$FIXTURES/vitest-saudavel" --skip-docker
  [ "$status" -eq 0 ]
  LIB="$BATS_TEST_DIRNAME/../../scripts/lib"
  note="$(bash "$LIB/cache-local.sh" get "$FIXTURES/vitest-saudavel" "environment-state")"
  ! echo "$note" | grep -q "segredo-nao-deve-vazar"
  echo "$note" | jq -e '.content.npm_token_present == true' >/dev/null
}

@test "projeto sem Docker nao invoca enable-docker-server" {
  export BASELINE_MOCK_NODE=ok
  run bash "$SCRIPT" --project-path "$FIXTURES/vitest-saudavel"
  [ "$status" -eq 0 ]
  ! echo "$output" | jq -e '.delegated_to | index("enable-docker-server")' >/dev/null
}

@test "projeto com Docker dep invoca delegation" {
  export BASELINE_MOCK_NODE=ok
  export BASELINE_MOCK_DOCKER=ok
  run bash "$SCRIPT" --project-path "$FIXTURES/legado-docker-dependent"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.delegated_to | map(test("enable-docker-server")) | any' >/dev/null
}
