#!/usr/bin/env bash
# manifest-hash.sh — helper compartilhado para calcular manifest_hash
#
# Funcao publica:
#   compute_manifest_hash <project_path> [workspace_path]
#     Emite em stdout a string "sha256:<hex>" (RN-10).
#     Em monorepo, se workspace_path for fornecido, calcula hash por workspace
#     (package.json do workspace + configs do workspace + configs de raiz que
#     afetam o grafo do monorepo).
#
# Dependencias: jq, shasum
# Contrato: deterministico para a mesma entrada.

set -euo pipefail

_mh_json_canonical() {
  # Serializa JSON de forma canonica via jq: chaves ordenadas, sem espaco.
  # Se input vazio, emite "null". Se invalido, emite "null".
  if [ -z "$1" ] || [ "$1" = "null" ]; then
    printf 'null'
    return
  fi
  printf '%s' "$1" | jq -cS '.' 2>/dev/null || printf 'null'
}

_mh_read_if_exists() {
  # Emite conteudo do arquivo se existir; caso contrario "ABSENT".
  local path="$1"
  if [ -f "$path" ]; then
    cat "$path"
  else
    printf 'ABSENT'
  fi
}

_mh_first_existing_config() {
  # Dado um diretorio e uma lista de globs, emite o conteudo do primeiro match
  # ou "ABSENT". Uso: _mh_first_existing_config "$dir" "jest.config.js" "jest.config.ts" ...
  local dir="$1"
  shift
  local pattern
  for pattern in "$@"; do
    # shellcheck disable=SC2086
    for candidate in $dir/$pattern; do
      if [ -f "$candidate" ]; then
        cat "$candidate"
        return
      fi
    done
  done
  printf 'ABSENT'
}

compute_manifest_hash() {
  local project_path="${1:-.}"
  local workspace_path="${2:-}"

  local target_dir="$project_path"
  if [ -n "$workspace_path" ]; then
    target_dir="$project_path/$workspace_path"
  fi

  local package_json="$target_dir/package.json"
  local scripts_block=""
  local deps_block=""

  if [ -f "$package_json" ]; then
    scripts_block="$(jq '.scripts // {}' "$package_json" 2>/dev/null || printf '{}')"
    deps_block="$(jq '.devDependencies // {}' "$package_json" 2>/dev/null || printf '{}')"
  fi

  local scripts_canonical
  scripts_canonical="$(_mh_json_canonical "$scripts_block")"
  local deps_canonical
  deps_canonical="$(_mh_json_canonical "$deps_block")"

  local nvmrc
  nvmrc="$(_mh_read_if_exists "$target_dir/.nvmrc")"
  if [ "$nvmrc" = "ABSENT" ] && [ -n "$workspace_path" ]; then
    # Em monorepo, .nvmrc da raiz tambem afeta.
    nvmrc="$(_mh_read_if_exists "$project_path/.nvmrc")"
  fi

  local monorepo_configs=""
  for cfg in nx.json turbo.json pnpm-workspace.yaml; do
    local content
    content="$(_mh_read_if_exists "$project_path/$cfg")"
    monorepo_configs+="[$cfg]${content}"
  done

  local runner_config
  runner_config="$(_mh_first_existing_config "$target_dir" \
    'jest.config.js' 'jest.config.ts' 'jest.config.mjs' 'jest.config.cjs' 'jest.config.json' \
    'vitest.config.js' 'vitest.config.ts' 'vitest.config.mjs' 'vitest.config.cjs' \
    '.mocharc.json' '.mocharc.js' '.mocharc.yml' '.mocharc.yaml' '.mocharc.cjs')"

  local linter_config
  linter_config="$(_mh_first_existing_config "$target_dir" \
    'eslint.config.js' 'eslint.config.mjs' 'eslint.config.cjs' 'eslint.config.ts' \
    '.eslintrc.js' '.eslintrc.cjs' '.eslintrc.json' '.eslintrc.yml' '.eslintrc.yaml' '.eslintrc' \
    'biome.json' 'biome.jsonc')"

  {
    printf '[scripts]%s\n' "$scripts_canonical"
    printf '[devDependencies]%s\n' "$deps_canonical"
    printf '[monorepo-configs]%s\n' "$monorepo_configs"
    printf '[runner-config]%s\n' "$runner_config"
    printf '[linter-config]%s\n' "$linter_config"
    printf '[nvmrc]%s\n' "$nvmrc"
  } | shasum -a 256 | awk '{printf "sha256:%s", $1}'
}

# Permite execucao direta para testes: ./manifest-hash.sh <path> [workspace]
if [ "${BASH_SOURCE[0]:-$0}" = "${0}" ]; then
  compute_manifest_hash "$@"
  printf '\n'
fi
