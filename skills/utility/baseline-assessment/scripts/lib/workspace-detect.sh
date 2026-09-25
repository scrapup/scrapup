#!/usr/bin/env bash
# workspace-detect.sh — detecta monorepo e emite informacao de workspaces.
#
# Uso:
#   workspace-detect.sh <project_path>
#
# Saida (stdout JSON):
#   {"is_monorepo": bool, "tool": "nx|turbo|pnpm|workspaces|null",
#    "workspaces": [...]}

set -euo pipefail

project_path="${1:-.}"

command -v jq >/dev/null 2>&1 || { printf 'workspace-detect.sh: jq ausente\n' >&2; exit 3; }

is_monorepo=false
tool="null"
workspaces='[]'

if [ -f "$project_path/package.json" ]; then
  type="$(jq -r '(.workspaces // empty) | type' "$project_path/package.json" 2>/dev/null || printf '')"
  if [ "$type" = "array" ]; then
    is_monorepo=true
    tool="workspaces"
    workspaces="$(jq -c '.workspaces // []' "$project_path/package.json")"
  elif [ "$type" = "object" ]; then
    is_monorepo=true
    tool="workspaces"
    workspaces="$(jq -c '.workspaces.packages // []' "$project_path/package.json")"
  fi
fi

if [ -f "$project_path/nx.json" ]; then
  is_monorepo=true
  tool="nx"
fi

if [ -f "$project_path/turbo.json" ]; then
  is_monorepo=true
  tool="turbo"
fi

if [ -f "$project_path/pnpm-workspace.yaml" ]; then
  is_monorepo=true
  tool="pnpm"
  local_ws="$(awk '/^packages:/{flag=1; next} /^[^ -]/{flag=0} flag && /^ *-/{gsub(/^ *- */,""); gsub(/["\x27]/,""); print}' "$project_path/pnpm-workspace.yaml" | jq -R -s -c 'split("\n") | map(select(length > 0))')"
  if [ -n "$local_ws" ] && [ "$local_ws" != "[]" ]; then
    workspaces="$local_ws"
  fi
fi

jq -nc \
  --argjson is_monorepo "$is_monorepo" \
  --arg tool "$tool" \
  --argjson workspaces "$workspaces" \
  '{is_monorepo: $is_monorepo, tool: (if $tool == "null" then null else $tool end), workspaces: $workspaces}'
