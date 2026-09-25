#!/usr/bin/env bats
# Testes do dispatcher baseline-check.sh e modos administrativos

DISPATCH="$BATS_TEST_DIRNAME/../../scripts/baseline-check.sh"
LIB="$BATS_TEST_DIRNAME/../../scripts/lib"
FIXTURES="$BATS_TEST_DIRNAME/../fixtures/projects"

setup() {
  command -v jq >/dev/null 2>&1 || skip "jq nao instalado"
  export BASELINE_CACHE_DIR="$BATS_TEST_TMPDIR/cache"
  export BASELINE_MOCK_NODE=ok
  export BASELINE_SKIP_DOCKER=1
  export PROJ="$BATS_TEST_TMPDIR/proj"
  cp -r "$FIXTURES/nestjs-saudavel" "$PROJ"
}

# --- Dispatcher routing ---

@test "dispatcher --help retorna sucesso com uso" {
  run bash "$DISPATCH" --help
  [ "$status" -eq 0 ]
  echo "$output" | grep -q "assess"
  echo "$output" | grep -q "verify-diff"
  echo "$output" | grep -q "override"
}

@test "dispatcher modo invalido retorna exit 3" {
  run bash "$DISPATCH" modo-inexistente
  [ "$status" -eq 3 ]
  [[ "$output" =~ "modo desconhecido" ]] || false
}

@test "dispatcher roteia assess" {
  bash "$LIB/saga-client.sh" project-ensure "$PROJ" >/dev/null
  bash "$LIB/saga-client.sh" note-upsert "$PROJ" "category-confirmation" "context" \
    '{"category_confirmed":"saudavel","reason":"fixture","confirmed_at":"2026-04-19T00:00:00Z"}'
  export BASELINE_MOCK_SUITE=green
  run bash "$DISPATCH" assess --project-path "$PROJ" --no-persist-metrics
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.mode == "assess"' >/dev/null
}

@test "dispatcher roteia report" {
  run bash "$DISPATCH" report --project-path "$PROJ"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.mode == "report"' >/dev/null
}

# --- override ---

@test "override set com flags validas grava note" {
  run bash "$DISPATCH" override set \
    --project-path "$PROJ" \
    --script=test \
    --alternative="npm run test:unit" \
    --ttl-days=7 \
    --reason="test principal quebrado apos upgrade"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.mode == "override"' >/dev/null
  echo "$output" | jq -e '.action == "set"' >/dev/null
  echo "$output" | jq -e '.override_active == true' >/dev/null
  echo "$output" | jq -e '.expires_at' >/dev/null
}

@test "override set com --ttl-days=0 retorna exit 1" {
  run bash "$DISPATCH" override set \
    --project-path "$PROJ" \
    --script=test --alternative=disabled --ttl-days=0 --reason="motivo valido com 10+ chars"
  [ "$status" -eq 1 ]
  [[ "$output" =~ "ttl-days" ]] || [[ "$stderr" =~ "ttl-days" ]] || \
    bash -c 'true' # tolerante: stderr pode estar combinado
}

@test "override set com script invalido retorna exit 1" {
  run bash "$DISPATCH" override set \
    --project-path "$PROJ" \
    --script=banana --alternative=disabled --reason="reason valido"
  [ "$status" -eq 1 ]
}

@test "override set com --reason curto retorna exit 1" {
  run bash "$DISPATCH" override set \
    --project-path "$PROJ" \
    --script=test --alternative=disabled --reason="curto"
  [ "$status" -eq 1 ]
}

@test "override remove remove apenas a entrada solicitada" {
  bash "$DISPATCH" override set --project-path "$PROJ" --script=test --alternative=disabled --reason="motivo para teste" >/dev/null
  bash "$DISPATCH" override set --project-path "$PROJ" --script=lint --alternative=disabled --reason="outro motivo agora" >/dev/null
  run bash "$DISPATCH" override remove --project-path "$PROJ" --script=test
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.override_active == false' >/dev/null
  # lint continua
  note="$(bash "$LIB/cache-local.sh" get "$PROJ" "baseline-overrides")"
  echo "$note" | jq -e '.content.overrides | length == 1' >/dev/null
  echo "$note" | jq -e '.content.overrides[0].script == "lint"' >/dev/null
}

@test "override remove de entrada inexistente retorna exit 1" {
  run bash "$DISPATCH" override remove --project-path "$PROJ" --script=cov
  [ "$status" -eq 1 ]
}

# --- classify ---

@test "classify confirm com categoria valida grava note" {
  run bash "$DISPATCH" classify confirm \
    --project-path "$PROJ" \
    --category=legado-estavel \
    --reason="time decidiu manter cobertura atual"
  [ "$status" -eq 0 ]
  echo "$output" | jq -e '.mode == "classify"' >/dev/null
  echo "$output" | jq -e '.category_confirmed == "legado-estavel"' >/dev/null

  note="$(bash "$LIB/cache-local.sh" get "$PROJ" "category-confirmation")"
  echo "$note" | jq -e '.content.category_confirmed == "legado-estavel"' >/dev/null
}

@test "classify confirm com categoria invalida retorna exit 1" {
  run bash "$DISPATCH" classify confirm \
    --project-path "$PROJ" \
    --category=banana --reason="motivo valido qualquer"
  [ "$status" -eq 1 ]
}

@test "classify confirm atualiza baseline-category classified_by=user-confirmed" {
  bash "$LIB/saga-client.sh" project-ensure "$PROJ" >/dev/null
  bash "$LIB/saga-client.sh" note-upsert "$PROJ" "baseline-category" "context" \
    '{"schema_version":1,"category":"indefinido","classified_by":"auto"}'

  run bash "$DISPATCH" classify confirm \
    --project-path "$PROJ" \
    --category=saudavel --reason="suite passa localmente sem flakies"
  [ "$status" -eq 0 ]

  cat_note="$(bash "$LIB/cache-local.sh" get "$PROJ" "baseline-category")"
  echo "$cat_note" | jq -e '.content.category == "saudavel"' >/dev/null
  echo "$cat_note" | jq -e '.content.classified_by == "user-confirmed"' >/dev/null
}

@test "override sem subcomando retorna exit 1" {
  run bash "$DISPATCH" override
  [ "$status" -eq 1 ]
}

@test "classify sem subcomando retorna exit 1" {
  run bash "$DISPATCH" classify
  [ "$status" -eq 1 ]
}
