#!/usr/bin/env bash
# detect-runner.sh — descobre ferramental Node/TS do projeto alvo.
#
# Uso:
#   detect-runner.sh [--project-path <path>] [--workspace <workspace-path>]
#
# Saida (stdout, JSON):
#   {
#     "runner": "jest|vitest|mocha|playwright|none",
#     "linter": "eslint|biome|none",
#     "build": "<comando ou null>",
#     "typecheck": "<comando ou null>",
#     "cov_script": "<nome do script ou null>",
#     "scripts": {"test": ..., "lint": ..., "build": ..., "typecheck": ..., "cov": ...},
#     "monorepo": {"is_monorepo": bool, "tool": "nx|turbo|pnpm|workspaces|null", "workspaces": [...]},
#     "manifest_hash": "sha256:...",
#     "observations": [...]
#   }
#
# Regras:
# - Nunca executa scripts do projeto (apenas leitura)
# - Sem package.json -> runner=none, observations=["no-package-json"], exit 0
# - jq ausente -> exit 3 (erro nao tratavel)
# - Dois runners declarados -> prioriza o do script "test", lista ambos em observations
# - Config malformado -> registra em observations e continua

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib/manifest-hash.sh
. "$SCRIPT_DIR/lib/manifest-hash.sh"

PROJECT_PATH="."
WORKSPACE_PATH=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-path)
      PROJECT_PATH="$2"
      shift 2
      ;;
    --project-path=*)
      PROJECT_PATH="${1#*=}"
      shift
      ;;
    --workspace)
      WORKSPACE_PATH="$2"
      shift 2
      ;;
    --workspace=*)
      WORKSPACE_PATH="${1#*=}"
      shift
      ;;
    --help|-h)
      sed -n '2,20p' "$0"
      exit 0
      ;;
    *)
      printf 'detect-runner.sh: flag desconhecida: %s\n' "$1" >&2
      exit 3
      ;;
  esac
done

if ! command -v jq >/dev/null 2>&1; then
  printf 'detect-runner.sh: jq nao encontrado no PATH\n' >&2
  exit 3
fi

TARGET_DIR="$PROJECT_PATH"
if [ -n "$WORKSPACE_PATH" ]; then
  TARGET_DIR="$PROJECT_PATH/$WORKSPACE_PATH"
fi

PACKAGE_JSON="$TARGET_DIR/package.json"
OBSERVATIONS_JSON='[]'

_add_obs() {
  OBSERVATIONS_JSON="$(printf '%s' "$OBSERVATIONS_JSON" | jq -c --arg v "$1" '. + [$v]')"
}

_no_package_json_output() {
  local manifest_hash
  manifest_hash="$(compute_manifest_hash "$PROJECT_PATH" "$WORKSPACE_PATH")"
  jq -nc \
    --arg runner "none" \
    --arg linter "none" \
    --arg hash "$manifest_hash" \
    --argjson obs "$OBSERVATIONS_JSON" \
    '{
      runner: $runner,
      linter: $linter,
      build: null,
      typecheck: null,
      cov_script: null,
      scripts: {test: null, lint: null, build: null, typecheck: null, cov: null},
      monorepo: {is_monorepo: false, tool: null, workspaces: []},
      manifest_hash: $hash,
      observations: ($obs + ["no-package-json"])
    }'
}

if [ ! -f "$PACKAGE_JSON" ]; then
  _no_package_json_output
  exit 0
fi

# Extrai scripts relevantes (nulo quando ausente).
# For the test script, prefer .scripts.test but fall back to test:e2e / test:unit / test:integration
# to support Playwright and other frameworks that use namespaced script keys.
script_test="$(jq -r '.scripts.test // empty' "$PACKAGE_JSON" 2>/dev/null || printf '')"
if [ -z "$script_test" ]; then
  test_e2e_key="$(jq -r '.scripts | to_entries | map(select(.key | test("^test:e2e$|^test:integration$|^test:unit$"))) | (first.key // empty)' "$PACKAGE_JSON" 2>/dev/null || printf '')"
  if [ -n "$test_e2e_key" ]; then
    script_test="$(jq -r --arg k "$test_e2e_key" '.scripts[$k] // empty' "$PACKAGE_JSON")"
    _add_obs "test-script-from-key:${test_e2e_key}"
  fi
fi
script_lint="$(jq -r '.scripts.lint // empty' "$PACKAGE_JSON" 2>/dev/null || printf '')"
script_build="$(jq -r '.scripts.build // empty' "$PACKAGE_JSON" 2>/dev/null || printf '')"
script_typecheck="$(jq -r '.scripts.typecheck // .scripts["type-check"] // empty' "$PACKAGE_JSON" 2>/dev/null || printf '')"
cov_key="$(jq -r '.scripts | to_entries | map(select(.key | test("^test:cov$|^test:coverage$|^cov$|^coverage$"))) | (first.key // empty)' "$PACKAGE_JSON" 2>/dev/null || printf '')"
script_cov=""
if [ -n "$cov_key" ]; then
  script_cov="$(jq -r --arg k "$cov_key" '.scripts[$k] // empty' "$PACKAGE_JSON")"
fi

# Detecta runner por devDependencies + configs + script test.
has_jest_dep="$(jq -r '(.devDependencies.jest // .dependencies.jest // empty)' "$PACKAGE_JSON")"
has_vitest_dep="$(jq -r '(.devDependencies.vitest // .dependencies.vitest // empty)' "$PACKAGE_JSON")"
has_mocha_dep="$(jq -r '(.devDependencies.mocha // .dependencies.mocha // empty)' "$PACKAGE_JSON")"
has_playwright_dep="$(jq -r '(.devDependencies["@playwright/test"] // .dependencies["@playwright/test"] // empty)' "$PACKAGE_JSON")"

_config_present() {
  local dir="$1"
  shift
  for pattern in "$@"; do
    # shellcheck disable=SC2086
    for candidate in $dir/$pattern; do
      [ -f "$candidate" ] && return 0
    done
  done
  return 1
}

jest_config_present=false
_config_present "$TARGET_DIR" 'jest.config.js' 'jest.config.ts' 'jest.config.mjs' 'jest.config.cjs' 'jest.config.json' && jest_config_present=true

vitest_config_present=false
_config_present "$TARGET_DIR" 'vitest.config.js' 'vitest.config.ts' 'vitest.config.mjs' 'vitest.config.cjs' && vitest_config_present=true

mocha_config_present=false
_config_present "$TARGET_DIR" '.mocharc.json' '.mocharc.js' '.mocharc.yml' '.mocharc.yaml' '.mocharc.cjs' && mocha_config_present=true

playwright_config_present=false
_config_present "$TARGET_DIR" 'playwright.config.js' 'playwright.config.ts' 'playwright.config.mjs' && playwright_config_present=true

RUNNERS_FOUND=()
[ -n "$has_jest_dep" ] || [ "$jest_config_present" = true ] && RUNNERS_FOUND+=("jest")
[ -n "$has_vitest_dep" ] || [ "$vitest_config_present" = true ] && RUNNERS_FOUND+=("vitest")
[ -n "$has_mocha_dep" ] || [ "$mocha_config_present" = true ] && RUNNERS_FOUND+=("mocha")
[ -n "$has_playwright_dep" ] || [ "$playwright_config_present" = true ] && RUNNERS_FOUND+=("playwright")

# Deduplicar
_uniq() {
  local seen=""
  local r=()
  for x in "$@"; do
    case " $seen " in
      *" $x "*) : ;;
      *) r+=("$x"); seen="$seen $x" ;;
    esac
  done
  printf '%s\n' "${r[@]}"
}

if [ "${#RUNNERS_FOUND[@]}" -gt 0 ]; then
  # shellcheck disable=SC2207
  RUNNERS_FOUND=( $(_uniq "${RUNNERS_FOUND[@]}") )
fi

RUNNER="none"
if [ "${#RUNNERS_FOUND[@]}" -eq 1 ]; then
  RUNNER="${RUNNERS_FOUND[0]}"
elif [ "${#RUNNERS_FOUND[@]}" -gt 1 ]; then
  _add_obs "multiple-runners-detected: ${RUNNERS_FOUND[*]}"
  # Prioriza o runner mencionado no script test
  for candidate in "${RUNNERS_FOUND[@]}"; do
    case "$script_test" in
      *"$candidate"*) RUNNER="$candidate"; break ;;
    esac
  done
  # Se nao encontrou no script test, prioridade padrao: jest > vitest > mocha > playwright
  if [ "$RUNNER" = "none" ]; then
    for candidate in jest vitest mocha playwright; do
      for found in "${RUNNERS_FOUND[@]}"; do
        [ "$candidate" = "$found" ] && RUNNER="$candidate" && break 2
      done
    done
  fi
fi

# Detecta linter.
has_eslint_dep="$(jq -r '(.devDependencies.eslint // .dependencies.eslint // empty)' "$PACKAGE_JSON")"
has_biome_dep="$(jq -r '(.devDependencies["@biomejs/biome"] // .dependencies["@biomejs/biome"] // empty)' "$PACKAGE_JSON")"

eslint_config_present=false
_config_present "$TARGET_DIR" \
  'eslint.config.js' 'eslint.config.mjs' 'eslint.config.cjs' 'eslint.config.ts' \
  '.eslintrc.js' '.eslintrc.cjs' '.eslintrc.json' '.eslintrc.yml' '.eslintrc.yaml' '.eslintrc' \
  && eslint_config_present=true

biome_config_present=false
_config_present "$TARGET_DIR" 'biome.json' 'biome.jsonc' && biome_config_present=true

LINTER="none"
if { [ -n "$has_eslint_dep" ] || [ "$eslint_config_present" = true ]; } && \
   { [ -n "$has_biome_dep" ] || [ "$biome_config_present" = true ]; }; then
  # Prioriza o que esta no script lint
  case "$script_lint" in
    *eslint*) LINTER="eslint" ;;
    *biome*) LINTER="biome" ;;
    *) LINTER="eslint" ;;
  esac
  _add_obs "multiple-linters-detected"
elif [ -n "$has_eslint_dep" ] || [ "$eslint_config_present" = true ]; then
  LINTER="eslint"
elif [ -n "$has_biome_dep" ] || [ "$biome_config_present" = true ]; then
  LINTER="biome"
fi

# build / typecheck fallback
BUILD_CMD="null"
if [ -n "$script_build" ]; then
  BUILD_CMD="$script_build"
fi

TYPECHECK_CMD="null"
if [ -n "$script_typecheck" ]; then
  TYPECHECK_CMD="$script_typecheck"
else
  # Fallback: tsconfig presente sugere tsc --noEmit
  if [ -f "$TARGET_DIR/tsconfig.json" ]; then
    TYPECHECK_CMD="tsc --noEmit"
  fi
fi

# Monorepo
IS_MONOREPO=false
MONOREPO_TOOL="null"
WORKSPACES_JSON='[]'

has_workspaces_field="$(jq -r '(.workspaces // empty) | type' "$PACKAGE_JSON" 2>/dev/null || printf '')"
if [ "$has_workspaces_field" = "array" ]; then
  IS_MONOREPO=true
  MONOREPO_TOOL="workspaces"
  WORKSPACES_JSON="$(jq -c '.workspaces' "$PACKAGE_JSON")"
elif [ "$has_workspaces_field" = "object" ]; then
  IS_MONOREPO=true
  MONOREPO_TOOL="workspaces"
  WORKSPACES_JSON="$(jq -c '.workspaces.packages // []' "$PACKAGE_JSON")"
fi

if [ -f "$PROJECT_PATH/nx.json" ]; then
  IS_MONOREPO=true
  MONOREPO_TOOL="nx"
fi

if [ -f "$PROJECT_PATH/turbo.json" ]; then
  IS_MONOREPO=true
  MONOREPO_TOOL="turbo"
fi

if [ -f "$PROJECT_PATH/pnpm-workspace.yaml" ]; then
  IS_MONOREPO=true
  MONOREPO_TOOL="pnpm"
  # Parser rudimentar de pnpm-workspace.yaml (captura valores de packages:)
  local_ws="$(awk '/^packages:/{flag=1; next} /^[^ -]/{flag=0} flag && /^ *-/{gsub(/^ *- */,""); gsub(/["\x27]/,""); print}' "$PROJECT_PATH/pnpm-workspace.yaml" | jq -R -s -c 'split("\n") | map(select(length > 0))')"
  if [ -n "$local_ws" ] && [ "$local_ws" != "[]" ]; then
    WORKSPACES_JSON="$local_ws"
  fi
fi

# Validate workspaces_malformed scenarios
if [ "$has_workspaces_field" = "array" ] && [ "$WORKSPACES_JSON" = "[]" ]; then
  _add_obs "monorepo-declaration-invalid"
  IS_MONOREPO=false
  MONOREPO_TOOL="null"
fi

MANIFEST_HASH="$(compute_manifest_hash "$PROJECT_PATH" "$WORKSPACE_PATH")"

# Emissao JSON final.
jq -nc \
  --arg runner "$RUNNER" \
  --arg linter "$LINTER" \
  --arg build "$BUILD_CMD" \
  --arg typecheck "$TYPECHECK_CMD" \
  --arg cov_script "$cov_key" \
  --arg script_test "$script_test" \
  --arg script_lint "$script_lint" \
  --arg script_build "$script_build" \
  --arg script_typecheck "$script_typecheck" \
  --arg script_cov "$script_cov" \
  --argjson is_monorepo "$IS_MONOREPO" \
  --arg monorepo_tool "$MONOREPO_TOOL" \
  --argjson workspaces "$WORKSPACES_JSON" \
  --arg manifest_hash "$MANIFEST_HASH" \
  --argjson observations "$OBSERVATIONS_JSON" \
  '{
    runner: $runner,
    linter: $linter,
    build: (if $build == "null" then null else $build end),
    typecheck: (if $typecheck == "null" then null else $typecheck end),
    cov_script: (if $cov_script == "" then null else $cov_script end),
    scripts: {
      test: (if $script_test == "" then null else $script_test end),
      lint: (if $script_lint == "" then null else $script_lint end),
      build: (if $script_build == "" then null else $script_build end),
      typecheck: (if $script_typecheck == "" then null else $script_typecheck end),
      cov: (if $script_cov == "" then null else $script_cov end)
    },
    monorepo: {
      is_monorepo: $is_monorepo,
      tool: (if $monorepo_tool == "null" then null else $monorepo_tool end),
      workspaces: $workspaces
    },
    manifest_hash: $manifest_hash,
    observations: $observations
  }'
