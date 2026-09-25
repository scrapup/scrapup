#!/usr/bin/env bats
# Testes de classify-project.sh

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/classify-project.sh"
DETECT="$BATS_TEST_DIRNAME/../../scripts/detect-runner.sh"
FIXTURES="$BATS_TEST_DIRNAME/../fixtures/projects"

setup() {
  command -v jq >/dev/null 2>&1 || skip "jq nao instalado"
}

_detect() {
  bash "$DETECT" --project-path "$1"
}

_classify_with() {
  local project_path="$1"
  local env_state="${2:-ready}"
  local docker_avail="${3:-true}"
  local detect_result
  detect_result="$(_detect "$project_path")"
  jq -nc \
    --arg p "$project_path" \
    --argjson dr "$detect_result" \
    --arg es "$env_state" \
    --argjson da "$docker_avail" \
    '{project_path: $p, detect_result: $dr, environment_state: $es, docker_available: $da}' \
    | bash "$SCRIPT"
}

@test "projeto saudavel com Jest + ESLint (sem node_modules) -> indefinido (low confidence)" {
  # Sem node_modules, dry-run e pulado; nao ha docker-compose -> indefinido por design.
  run _classify_with "$FIXTURES/nestjs-saudavel"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.category == "indefinido"' >/dev/null
  echo "$output" | jq -e '.confidence == "low"' >/dev/null
  echo "$output" | jq -e '.category_effective == null' >/dev/null
}

@test "projeto sem package.json -> sem-infra (high confidence)" {
  run _classify_with "$FIXTURES/sem-package-json"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.category == "sem-infra"' >/dev/null
  echo "$output" | jq -e '.confidence == "high"' >/dev/null
  echo "$output" | jq -e '.category_effective == "sem-infra"' >/dev/null
}

@test "projeto com docker-compose + scripts referenciando docker -> legado-docker-dependent" {
  run _classify_with "$FIXTURES/legado-docker-dependent"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.category == "legado-docker-dependent"' >/dev/null
  echo "$output" | jq -e '.signals.docker_dependency_detected == true' >/dev/null
}

@test "legado-docker-dependent com environment=partial e docker=false -> category_effective=legado-critico" {
  run _classify_with "$FIXTURES/legado-docker-dependent" partial false
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.category == "legado-docker-dependent"' >/dev/null
  echo "$output" | jq -e '.category_effective == "legado-critico"' >/dev/null
  echo "$output" | jq -e '.observations | map(test("downgraded-docker")) | any' >/dev/null
}

@test "classification-override prevalece" {
  detect_result="$(_detect "$FIXTURES/nestjs-saudavel")"
  input="$(jq -nc \
    --arg p "$FIXTURES/nestjs-saudavel" \
    --argjson dr "$detect_result" \
    '{project_path: $p, detect_result: $dr, environment_state: "ready", docker_available: true,
      classification_override: {category: "legado-estavel", reason: "decisao do time"}}')"
  run bash -c 'printf "%s" "$1" | "$2"' _ "$input" "$SCRIPT"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.category == "legado-estavel"' >/dev/null
  echo "$output" | jq -e '.signals.override_applied == true' >/dev/null
}

@test "detect_result ausente -> exit 3" {
  run bash -c 'echo {} | "$1"' _ "$SCRIPT"
  [ "$status" -eq 3 ]
}

@test "saida e JSON valido" {
  run _classify_with "$FIXTURES/sem-package-json"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.' >/dev/null
}

@test "monorepo Turborepo com docker dependency classifica corretamente" {
  # monorepo-turborepo nao tem docker-compose nem referencia docker nos scripts
  run _classify_with "$FIXTURES/monorepo-turborepo"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.signals.docker_dependency_detected == false' >/dev/null
}

@test "idempotencia: mesma entrada -> mesma saida" {
  out1="$(_classify_with "$FIXTURES/sem-package-json")"
  out2="$(_classify_with "$FIXTURES/sem-package-json")"
  [ "$out1" = "$out2" ]
}
