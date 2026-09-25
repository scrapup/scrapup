#!/usr/bin/env bash
# classify-project.sh — classifica projeto Node/TS em uma das 5 categorias
# operacionais (saudavel, legado-estavel, legado-docker-dependent, legado-critico,
# sem-infra) ou indefinido quando ha sinais contraditorios.
#
# Uso:
#   echo '<input_json>' | classify-project.sh
#   classify-project.sh --detect-result-file <path> --environment-state ready --docker-available true
#
# Entrada (stdin JSON ou flags equivalentes):
#   {
#     "project_path": ".",
#     "detect_result": { ...saida de detect-runner.sh... },
#     "environment_state": "ready|partial|blocked",
#     "docker_available": true|false,
#     "classification_override": null | { "category": "...", "reason": "..." }
#   }
#
# Saida (stdout JSON):
#   {
#     "category": "saudavel|legado-estavel|legado-docker-dependent|legado-critico|sem-infra|indefinido",
#     "category_effective": "<idem, sem indefinido>|null",
#     "confidence": "high|medium|low",
#     "signals": {...},
#     "observations": [...]
#   }
#
# Regras principais:
# - RN-01: exatamente 5 categorias + indefinido durante triagem
# - RN-05: classificacao por sondagem nao-invasiva (dry-run do runner)
# - RN-06: sinais contraditorios -> indefinido com evidencia
# - RN-20: nao reclassificar sem evidencia (caller controla cache)
# - RN-25: category_effective ajustado quando environment_state=partial

set -euo pipefail

if ! command -v jq >/dev/null 2>&1; then
  printf 'classify-project.sh: jq nao encontrado no PATH\n' >&2
  exit 3
fi

PROJECT_PATH="."
ENVIRONMENT_STATE=""
DOCKER_AVAILABLE=""
DETECT_RESULT=""
CLASSIFICATION_OVERRIDE="null"
INPUT_JSON=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-path)     PROJECT_PATH="$2"; shift 2 ;;
    --project-path=*)   PROJECT_PATH="${1#*=}"; shift ;;
    --detect-result-file) DETECT_RESULT="$(cat "$2")"; shift 2 ;;
    --environment-state) ENVIRONMENT_STATE="$2"; shift 2 ;;
    --docker-available)  DOCKER_AVAILABLE="$2"; shift 2 ;;
    --classification-override-file) CLASSIFICATION_OVERRIDE="$(cat "$2")"; shift 2 ;;
    --help|-h)
      sed -n '2,30p' "$0"
      exit 0
      ;;
    *)
      printf 'classify-project.sh: flag desconhecida: %s\n' "$1" >&2
      exit 3
      ;;
  esac
done

# Se stdin tem conteudo JSON, usa como fonte principal.
if [ ! -t 0 ]; then
  INPUT_JSON="$(cat || true)"
fi

if [ -n "$INPUT_JSON" ]; then
  PROJECT_PATH="$(printf '%s' "$INPUT_JSON" | jq -r '.project_path // "."')"
  DETECT_RESULT="$(printf '%s' "$INPUT_JSON" | jq -c '.detect_result // null')"
  ENVIRONMENT_STATE="$(printf '%s' "$INPUT_JSON" | jq -r 'if has("environment_state") then .environment_state else "ready" end')"
  DOCKER_AVAILABLE="$(printf '%s' "$INPUT_JSON" | jq -r 'if has("docker_available") then .docker_available else true end')"
  CLASSIFICATION_OVERRIDE="$(printf '%s' "$INPUT_JSON" | jq -c '.classification_override // null')"
fi

# Valores default quando nao informados.
[ -z "$ENVIRONMENT_STATE" ] && ENVIRONMENT_STATE="ready"
[ -z "$DOCKER_AVAILABLE" ] && DOCKER_AVAILABLE="true"

if [ -z "$DETECT_RESULT" ] || [ "$DETECT_RESULT" = "null" ]; then
  printf 'classify-project.sh: detect_result ausente na entrada\n' >&2
  exit 3
fi

# Extrai sinais do detect_result.
RUNNER="$(printf '%s' "$DETECT_RESULT" | jq -r '.runner // "none"')"
LINTER="$(printf '%s' "$DETECT_RESULT" | jq -r '.linter // "none"')"
SCRIPT_TEST="$(printf '%s' "$DETECT_RESULT" | jq -r '.scripts.test // ""')"
OBSERVATIONS_IN="$(printf '%s' "$DETECT_RESULT" | jq -c '.observations // []')"

OBSERVATIONS_JSON="$OBSERVATIONS_IN"
_add_obs() {
  OBSERVATIONS_JSON="$(printf '%s' "$OBSERVATIONS_JSON" | jq -c --arg v "$1" '. + [$v]')"
}

# Dependencia de Docker: heuristica dupla
# (a) docker-compose.yml presente
# (b) scripts de teste referenciam "docker compose" ou "docker-compose"
DOCKER_COMPOSE_PRESENT=false
if [ -f "$PROJECT_PATH/docker-compose.yml" ] || [ -f "$PROJECT_PATH/docker-compose.yaml" ] || [ -f "$PROJECT_PATH/compose.yml" ] || [ -f "$PROJECT_PATH/compose.yaml" ]; then
  DOCKER_COMPOSE_PRESENT=true
fi

SCRIPTS_REFERENCE_DOCKER=false
if [ -f "$PROJECT_PATH/package.json" ]; then
  if jq -r '.scripts // {} | to_entries[] | .value' "$PROJECT_PATH/package.json" 2>/dev/null \
    | grep -Eq '(docker compose|docker-compose|docker run)'; then
    SCRIPTS_REFERENCE_DOCKER=true
  fi
fi

DOCKER_DEPENDENCY_DETECTED=false
if [ "$DOCKER_COMPOSE_PRESENT" = true ] && [ "$SCRIPTS_REFERENCE_DOCKER" = true ]; then
  DOCKER_DEPENDENCY_DETECTED=true
elif [ "$DOCKER_COMPOSE_PRESENT" = true ] && [ "$SCRIPTS_REFERENCE_DOCKER" = false ]; then
  _add_obs "docker-compose-present-without-script-reference"
fi

# Sondagem seca do runner (modo seco, sem executar a suite).
# Como este e um ambiente shell puro, "dry-run" e um comando que lista testes.
# Nao invoca npm (evita side-effects do pre-install) — apenas detecta se o
# runner esta instalado localmente via node_modules/.bin.
RUNNER_DRY_RUN="skipped"
TESTS_LISTABLE=0
LISTER_BIN=""

# Extrai flags do script test apos o binario do runner (ex.: jest --selectProjects unit).
_jest_extra_args_from_script() {
  local script="$1"
  if [[ "$script" =~ ^jest([[:space:]]|$) ]]; then
    local rest="${script#jest}"
    rest="${rest# }"
    printf '%s' "$rest"
  fi
}

case "$RUNNER" in
  jest)
    if [ -x "$PROJECT_PATH/node_modules/.bin/jest" ]; then
      LISTER_BIN="$PROJECT_PATH/node_modules/.bin/jest"
      JEST_EXTRA="$(_jest_extra_args_from_script "$SCRIPT_TEST")"
      if out="$(cd "$PROJECT_PATH" && "$LISTER_BIN" --listTests $JEST_EXTRA 2>/dev/null)"; then
        RUNNER_DRY_RUN="ok"
        TESTS_LISTABLE="$(printf '%s' "$out" | grep -c . || printf '0')"
      else
        RUNNER_DRY_RUN="failed"
      fi
    else
      RUNNER_DRY_RUN="binary-missing"
      _add_obs "runner-binary-absent: jest nao encontrado em node_modules/.bin"
    fi
    ;;
  vitest)
    if [ -x "$PROJECT_PATH/node_modules/.bin/vitest" ]; then
      LISTER_BIN="$PROJECT_PATH/node_modules/.bin/vitest"
      if out="$(cd "$PROJECT_PATH" && "$LISTER_BIN" list --run 2>/dev/null)"; then
        RUNNER_DRY_RUN="ok"
        TESTS_LISTABLE="$(printf '%s' "$out" | grep -c . || printf '0')"
      else
        RUNNER_DRY_RUN="failed"
      fi
    else
      RUNNER_DRY_RUN="binary-missing"
      _add_obs "runner-binary-absent: vitest nao encontrado em node_modules/.bin"
    fi
    ;;
  mocha)
    if [ -x "$PROJECT_PATH/node_modules/.bin/mocha" ]; then
      LISTER_BIN="$PROJECT_PATH/node_modules/.bin/mocha"
      if out="$(cd "$PROJECT_PATH" && "$LISTER_BIN" --dry-run 2>/dev/null)"; then
        RUNNER_DRY_RUN="ok"
        TESTS_LISTABLE="$(printf '%s' "$out" | grep -c . || printf '0')"
      else
        RUNNER_DRY_RUN="failed"
      fi
    else
      RUNNER_DRY_RUN="binary-missing"
      _add_obs "runner-binary-absent: mocha nao encontrado em node_modules/.bin"
    fi
    ;;
  none)
    RUNNER_DRY_RUN="no-runner"
    ;;
  *)
    RUNNER_DRY_RUN="unknown-runner"
    _add_obs "runner-unknown: $RUNNER"
    ;;
esac

LINTER_PRESENT=false
[ "$LINTER" != "none" ] && LINTER_PRESENT=true

OVERRIDE_APPLIED=false
OVERRIDE_CATEGORY=""
if [ "$CLASSIFICATION_OVERRIDE" != "null" ] && [ -n "$CLASSIFICATION_OVERRIDE" ]; then
  OVERRIDE_CATEGORY="$(printf '%s' "$CLASSIFICATION_OVERRIDE" | jq -r '.category // empty')"
  if [ -n "$OVERRIDE_CATEGORY" ]; then
    OVERRIDE_APPLIED=true
  fi
fi

# ----- Matriz de decisao -----
CATEGORY=""
CONFIDENCE="medium"

if [ "$OVERRIDE_APPLIED" = true ]; then
  CATEGORY="$OVERRIDE_CATEGORY"
  CONFIDENCE="high"
  _add_obs "category-from-override"
elif [ "$RUNNER" = "none" ] && [ "$LINTER" = "none" ]; then
  CATEGORY="sem-infra"
  CONFIDENCE="high"
elif [ "$RUNNER" = "none" ] && [ "$LINTER" != "none" ]; then
  # Projeto tem linter mas nao tem runner: sinal ambiguo.
  # Caso typical: projeto de docs/configs Node com eslint mas sem testes.
  CATEGORY="sem-infra"
  CONFIDENCE="medium"
  _add_obs "runner-absent-linter-present"
elif [ "$RUNNER_DRY_RUN" = "failed" ]; then
  # Runner instalado mas config quebrada: CI remoto sera o gate.
  CATEGORY="legado-critico"
  CONFIDENCE="high"
  _add_obs "runner-dry-run-failed"
elif [ "$RUNNER_DRY_RUN" = "binary-missing" ]; then
  # Runner declarado no package.json mas node_modules nao instalado.
  # Apenas sinaliza — caller decide (assess-core fara npm install antes).
  if [ "$DOCKER_DEPENDENCY_DETECTED" = true ]; then
    CATEGORY="legado-docker-dependent"
  else
    CATEGORY="indefinido"
  fi
  CONFIDENCE="low"
  _add_obs "node_modules-ausente-dry-run-pulado"
elif [ "$DOCKER_DEPENDENCY_DETECTED" = true ]; then
  CATEGORY="legado-docker-dependent"
  CONFIDENCE="high"
elif [ "$RUNNER_DRY_RUN" = "ok" ]; then
  # Runner funciona. Distincao saudavel vs legado-estavel exige sinais
  # adicionais que so aparecem apos execucao da suite. Por default,
  # classifica como saudavel; assess-core pode rebaixar para legado-estavel
  # se observar flakies, lentidao ou falhas recorrentes apos a suite.
  if [ "$LINTER_PRESENT" = true ]; then
    CATEGORY="saudavel"
    CONFIDENCE="medium"
  else
    CATEGORY="legado-estavel"
    CONFIDENCE="medium"
    _add_obs "sem-linter-mas-com-runner"
  fi
elif [ "$RUNNER_DRY_RUN" = "skipped" ] || [ "$RUNNER_DRY_RUN" = "no-runner" ]; then
  # Runner declarado mas nao conseguiu testar.
  if [ "$DOCKER_DEPENDENCY_DETECTED" = true ]; then
    CATEGORY="legado-docker-dependent"
    CONFIDENCE="medium"
  else
    CATEGORY="indefinido"
    CONFIDENCE="low"
    _add_obs "runner-declarado-sem-sondagem"
  fi
else
  CATEGORY="indefinido"
  CONFIDENCE="low"
  _add_obs "sinais-insuficientes"
fi

# ----- Calculo de category_effective (RN-25, RN-27) -----
CATEGORY_EFFECTIVE=""
if [ "$CATEGORY" = "indefinido" ]; then
  CATEGORY_EFFECTIVE="null"
else
  CATEGORY_EFFECTIVE="$CATEGORY"
  # Ajuste quando environment_state=partial e categoria depende de infra indisponivel.
  if [ "$CATEGORY" = "legado-docker-dependent" ] && \
     [ "$ENVIRONMENT_STATE" = "partial" ] && \
     [ "$DOCKER_AVAILABLE" = "false" ]; then
    CATEGORY_EFFECTIVE="legado-critico"
    _add_obs "category-effective-downgraded-docker-unavailable"
  fi
fi

# ----- Emissao JSON -----
TESTS_LISTABLE_INT="$(printf '%s' "$TESTS_LISTABLE" | tr -d '[:space:]')"
[ -z "$TESTS_LISTABLE_INT" ] && TESTS_LISTABLE_INT=0

jq -nc \
  --arg category "$CATEGORY" \
  --arg category_effective "$CATEGORY_EFFECTIVE" \
  --arg confidence "$CONFIDENCE" \
  --arg runner_dry_run "$RUNNER_DRY_RUN" \
  --argjson docker_dep "$DOCKER_DEPENDENCY_DETECTED" \
  --argjson docker_available "$DOCKER_AVAILABLE" \
  --argjson tests_listable "$TESTS_LISTABLE_INT" \
  --argjson linter_present "$LINTER_PRESENT" \
  --argjson override_applied "$OVERRIDE_APPLIED" \
  --argjson observations "$OBSERVATIONS_JSON" \
  '{
    category: $category,
    category_effective: (if $category_effective == "null" then null else $category_effective end),
    confidence: $confidence,
    signals: {
      runner_dry_run: $runner_dry_run,
      docker_dependency_detected: $docker_dep,
      docker_available: $docker_available,
      tests_listable: $tests_listable,
      linter_present: $linter_present,
      override_applied: $override_applied
    },
    observations: $observations
  }'
