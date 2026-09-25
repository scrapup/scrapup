#!/usr/bin/env bats
# Testes de cache-local.sh, saga-client.sh e report.sh

LIB_DIR="$BATS_TEST_DIRNAME/../../scripts/lib"
REPORT="$BATS_TEST_DIRNAME/../../scripts/report.sh"

setup() {
  command -v jq >/dev/null 2>&1 || skip "jq nao instalado"
  export BASELINE_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
  export FIXTURE="$BATS_TEST_TMPDIR/proj"
  mkdir -p "$FIXTURE"
}

@test "cache_init cria arquivo de cache" {
  run bash "$LIB_DIR/cache-local.sh" init "$FIXTURE" "my-repo"
  [ "$status" -eq 0 ]
  file="$(bash "$LIB_DIR/cache-local.sh" path "$FIXTURE")"
  [ -f "$file" ]
  jq -e '.schema_version == 1' "$file" >/dev/null
  jq -e '.repo == "my-repo"' "$file" >/dev/null
}

@test "cache_note_upsert grava e get retorna o conteudo" {
  bash "$LIB_DIR/cache-local.sh" init "$FIXTURE" "repo"
  bash "$LIB_DIR/cache-local.sh" upsert "$FIXTURE" "baseline-category" '{"category":"saudavel","schema_version":1}'
  result="$(bash "$LIB_DIR/cache-local.sh" get "$FIXTURE" "baseline-category")"
  echo "$result" | jq -e '.content.category == "saudavel"' >/dev/null
  echo "$result" | jq -e '.updated_at' >/dev/null
}

@test "cache_note_list lista notes" {
  bash "$LIB_DIR/cache-local.sh" init "$FIXTURE" "repo"
  bash "$LIB_DIR/cache-local.sh" upsert "$FIXTURE" "baseline-current" '{"tests_count":{"total":10}}'
  bash "$LIB_DIR/cache-local.sh" upsert "$FIXTURE" "baseline-latest" '{"tests_count":{"total":12}}'
  result="$(bash "$LIB_DIR/cache-local.sh" list "$FIXTURE")"
  echo "$result" | jq -e 'length == 2' >/dev/null
  echo "$result" | jq -e 'map(.title) | index("baseline-current") != null' >/dev/null
}

@test "cache suporta workspace (monorepo prefixa ws:)" {
  bash "$LIB_DIR/cache-local.sh" init "$FIXTURE" "repo"
  bash "$LIB_DIR/cache-local.sh" upsert "$FIXTURE" "baseline-category" '{"category":"saudavel"}' --ws "apps/api"
  bash "$LIB_DIR/cache-local.sh" upsert "$FIXTURE" "baseline-category" '{"category":"legado-estavel"}' --ws "apps/web"
  api="$(bash "$LIB_DIR/cache-local.sh" get "$FIXTURE" "baseline-category" --ws "apps/api")"
  echo "$api" | jq -e '.content.category == "saudavel"' >/dev/null
  web="$(bash "$LIB_DIR/cache-local.sh" get "$FIXTURE" "baseline-category" --ws "apps/web")"
  echo "$web" | jq -e '.content.category == "legado-estavel"' >/dev/null
  raiz="$(bash "$LIB_DIR/cache-local.sh" get "$FIXTURE" "baseline-category")"
  [ "$raiz" = "null" ]
}

@test "cache_note_delete remove note" {
  bash "$LIB_DIR/cache-local.sh" init "$FIXTURE" "repo"
  bash "$LIB_DIR/cache-local.sh" upsert "$FIXTURE" "temp" '{"x":1}'
  bash "$LIB_DIR/cache-local.sh" delete "$FIXTURE" "temp"
  result="$(bash "$LIB_DIR/cache-local.sh" get "$FIXTURE" "temp")"
  [ "$result" = "null" ]
}

@test "upsert marca pending_saga_sync=true" {
  bash "$LIB_DIR/cache-local.sh" init "$FIXTURE" "repo"
  bash "$LIB_DIR/cache-local.sh" upsert "$FIXTURE" "note-a" '{}'
  pending="$(bash "$LIB_DIR/cache-local.sh" is-pending "$FIXTURE")"
  [ "$pending" = "true" ]
}

@test "mark-synced zera o flag pending" {
  bash "$LIB_DIR/cache-local.sh" init "$FIXTURE" "repo"
  bash "$LIB_DIR/cache-local.sh" upsert "$FIXTURE" "note-b" '{}'
  bash "$LIB_DIR/cache-local.sh" mark-synced "$FIXTURE"
  pending="$(bash "$LIB_DIR/cache-local.sh" is-pending "$FIXTURE")"
  [ "$pending" = "false" ]
}

@test "saga_project_name deriva nome do diretorio quando sem git" {
  mkdir -p "$BATS_TEST_TMPDIR/my-repo"
  name="$(bash "$LIB_DIR/saga-client.sh" project-name "$BATS_TEST_TMPDIR/my-repo")"
  [ "$name" = "test-config:my-repo" ]
}

@test "saga_note_search acha por query textual" {
  bash "$LIB_DIR/saga-client.sh" project-ensure "$FIXTURE" >/dev/null
  bash "$LIB_DIR/saga-client.sh" note-upsert "$FIXTURE" "test-scripts" "context" \
    '{"runner":"jest","scripts":{"test":"jest"}}'
  result="$(bash "$LIB_DIR/saga-client.sh" note-search "$FIXTURE" "jest")"
  echo "$result" | jq -e 'length == 1' >/dev/null
  echo "$result" | jq -e '.[0].title == "test-scripts"' >/dev/null
}

@test "report retorna null para campos quando nao ha dados" {
  mkdir -p "$BATS_TEST_TMPDIR/empty-repo"
  run bash "$REPORT" --project-path "$BATS_TEST_TMPDIR/empty-repo"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.mode == "report"' >/dev/null
  echo "$output" | jq -e '.category == null' >/dev/null
  echo "$output" | jq -e '.baseline_current == null' >/dev/null
}

@test "report recomputa category_effective: legado-docker + partial + docker=false -> legado-critico" {
  bash "$LIB_DIR/saga-client.sh" project-ensure "$FIXTURE" >/dev/null
  bash "$LIB_DIR/saga-client.sh" note-upsert "$FIXTURE" "environment-state" "context" \
    '{"state":"partial","docker_available":false}'
  bash "$LIB_DIR/saga-client.sh" note-upsert "$FIXTURE" "baseline-category" "context" \
    '{"category":"legado-docker-dependent"}'
  run bash "$REPORT" --project-path "$FIXTURE"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.category == "legado-docker-dependent"' >/dev/null
  echo "$output" | jq -e '.category_effective == "legado-critico"' >/dev/null
}

@test "report filtra overrides ativos por expires_at" {
  bash "$LIB_DIR/saga-client.sh" project-ensure "$FIXTURE" >/dev/null
  future="$(date -u -v+7d +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '+7 days' +'%Y-%m-%dT%H:%M:%SZ')"
  past="$(date -u -v-1d +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d '-1 days' +'%Y-%m-%dT%H:%M:%SZ')"
  content="$(jq -nc --arg f "$future" --arg p "$past" \
    '{overrides:[{script:"test",alternative:"npm run test:unit",expires_at:$f,reason:"ok"},{script:"lint",alternative:"disabled",expires_at:$p,reason:"old"}]}')"
  bash "$LIB_DIR/saga-client.sh" note-upsert "$FIXTURE" "baseline-overrides" "context" "$content"
  run bash "$REPORT" --project-path "$FIXTURE"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.overrides_active | length == 1' >/dev/null
  echo "$output" | jq -e '.overrides_active[0].script == "test"' >/dev/null
}

@test "report saida e JSON valido" {
  bash "$LIB_DIR/saga-client.sh" project-ensure "$FIXTURE" >/dev/null
  run bash "$REPORT" --project-path "$FIXTURE"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.' >/dev/null
}
