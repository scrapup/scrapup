#!/usr/bin/env bash
# impact.sh — descobre arquivos de teste potencialmente impactados por uma
# lista de arquivos alterados.
#
# Heuristica por convencao (alinhada com TDAD IMPACT):
#   src/foo/bar.ts -> src/foo/bar.test.ts | src/foo/bar.spec.ts
#                     tests/foo/bar.test.ts | tests/foo/bar.spec.ts
#                     __tests__/foo/bar.test.ts
#   Para arquivos ja de teste (.test.*|.spec.*), retorna o proprio arquivo.
#
# Uso:
#   impact.sh <project_path> < <lista-de-arquivos-por-linha>
#   echo -e "src/a.ts\nsrc/b.ts" | impact.sh .
#
# Saida (stdout, um arquivo por linha, deduplicado).

set -euo pipefail

project_path="${1:-.}"

declare -a impacted=()

_is_test_file() {
  case "$1" in
    *.test.ts|*.test.tsx|*.test.js|*.test.jsx|*.spec.ts|*.spec.tsx|*.spec.js|*.spec.jsx)
      return 0 ;;
    *) return 1 ;;
  esac
}

_add_if_exists() {
  local path="$1"
  if [ -f "$project_path/$path" ]; then
    impacted+=("$path")
  fi
}

while IFS= read -r file || [ -n "$file" ]; do
  [ -z "$file" ] && continue

  if _is_test_file "$file"; then
    impacted+=("$file")
    continue
  fi

  # Extrai dir e base do arquivo.
  dir="$(dirname "$file")"
  base="$(basename "$file")"
  stem="${base%.*}"

  # Variantes de teste na mesma pasta
  for suffix in test spec; do
    for ext in ts tsx js jsx; do
      _add_if_exists "$dir/${stem}.${suffix}.${ext}"
    done
  done

  # Variantes em tests/ e __tests__/ espelhando a estrutura
  rel_dir="${dir#src/}"
  rel_dir="${rel_dir#./}"
  for test_root in "tests" "__tests__" "test"; do
    for suffix in test spec; do
      for ext in ts tsx js jsx; do
        _add_if_exists "$test_root/${rel_dir}/${stem}.${suffix}.${ext}"
      done
    done
  done
done

# Deduplicar + emitir
if [ "${#impacted[@]}" -gt 0 ]; then
  printf '%s\n' "${impacted[@]}" | sort -u
fi
