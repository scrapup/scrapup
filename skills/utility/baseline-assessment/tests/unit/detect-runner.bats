#!/usr/bin/env bats
# Testes unitarios de detect-runner.sh
# Executar: bats tests/unit/detect-runner.bats

SCRIPT="$BATS_TEST_DIRNAME/../../scripts/detect-runner.sh"
FIXTURES="$BATS_TEST_DIRNAME/../fixtures/projects"

setup() {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq nao instalado"
  fi
}

@test "detecta Jest em projeto NestJS saudavel" {
  run bash "$SCRIPT" --project-path "$FIXTURES/nestjs-saudavel"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.runner == "jest"' >/dev/null
  echo "$output" | jq -e '.linter == "eslint"' >/dev/null
  echo "$output" | jq -e '.scripts.test == "jest"' >/dev/null
  echo "$output" | jq -e '.scripts.cov == "jest --coverage"' >/dev/null
  echo "$output" | jq -e '.typecheck == "tsc --noEmit"' >/dev/null
}

@test "detecta Vitest com Biome" {
  run bash "$SCRIPT" --project-path "$FIXTURES/vitest-saudavel"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.runner == "vitest"' >/dev/null
  echo "$output" | jq -e '.linter == "biome"' >/dev/null
}

@test "sem package.json retorna runner=none sem falhar" {
  run bash "$SCRIPT" --project-path "$FIXTURES/sem-package-json"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.runner == "none"' >/dev/null
  echo "$output" | jq -e '.observations | index("no-package-json") != null' >/dev/null
}

@test "dois runners: prioriza o do script test (vitest)" {
  run bash "$SCRIPT" --project-path "$FIXTURES/dois-runners"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.runner == "vitest"' >/dev/null
  echo "$output" | jq -e '.observations | map(test("multiple-runners-detected")) | any' >/dev/null
}

@test "detecta monorepo Turborepo" {
  run bash "$SCRIPT" --project-path "$FIXTURES/monorepo-turborepo"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.monorepo.is_monorepo == true' >/dev/null
  echo "$output" | jq -e '.monorepo.tool == "turbo"' >/dev/null
  echo "$output" | jq -e '.monorepo.workspaces | length > 0' >/dev/null
}

@test "detecta monorepo pnpm-workspaces" {
  run bash "$SCRIPT" --project-path "$FIXTURES/monorepo-pnpm"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.monorepo.is_monorepo == true' >/dev/null
  echo "$output" | jq -e '.monorepo.tool == "pnpm"' >/dev/null
  echo "$output" | jq -e '.monorepo.workspaces | length > 0' >/dev/null
}

@test "manifest_hash e determinista" {
  run bash "$SCRIPT" --project-path "$FIXTURES/nestjs-saudavel"
  first="$output"
  run bash "$SCRIPT" --project-path "$FIXTURES/nestjs-saudavel"
  second="$output"
  [ "$(echo "$first" | jq -r .manifest_hash)" = "$(echo "$second" | jq -r .manifest_hash)" ]
}

@test "manifest_hash muda quando scripts mudam" {
  run bash "$SCRIPT" --project-path "$FIXTURES/nestjs-saudavel"
  hash_a="$(echo "$output" | jq -r .manifest_hash)"
  run bash "$SCRIPT" --project-path "$FIXTURES/vitest-saudavel"
  hash_b="$(echo "$output" | jq -r .manifest_hash)"
  [ "$hash_a" != "$hash_b" ]
}

@test "flag desconhecida retorna exit 3" {
  run bash "$SCRIPT" --invalido valor
  [ "$status" -eq 3 ]
}

@test "saida e JSON valido" {
  run bash "$SCRIPT" --project-path "$FIXTURES/nestjs-saudavel"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.' >/dev/null
}
