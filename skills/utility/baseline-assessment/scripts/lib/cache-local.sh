#!/usr/bin/env bash
# cache-local.sh — camada primaria de persistencia em disco.
#
# Estrutura: ~/.claude/plugins/local/scrapup/cache/baseline/{repo-hash}.json
# Schema:
#   { schema_version: 1, repo, workspace_scope, pending_saga_sync,
#     notes: {<title>: {content, updated_at}}, metrics_runs: [...], updated_at }
#
# Concorrencia: flock com timeout (default 30s).
# Override BASELINE_CACHE_DIR e CACHE_LOCK_TIMEOUT via env.

set -euo pipefail

: "${BASELINE_CACHE_DIR:="${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/plugins/local/scrapup}/cache/baseline"}"
CACHE_LOCK_TIMEOUT="${CACHE_LOCK_TIMEOUT:-30}"

if ! command -v jq >/dev/null 2>&1; then
  printf 'cache-local.sh: jq nao encontrado no PATH\n' >&2
  exit 3
fi

_iso_now() { date -u +'%Y-%m-%dT%H:%M:%SZ'; }

cache_dir() { printf '%s' "$BASELINE_CACHE_DIR"; }

cache_repo_hash() {
  local project_path="${1:?project_path obrigatorio}"
  local repo_name=""
  if [ -d "$project_path/.git" ]; then
    repo_name="$(cd "$project_path" && git config --get remote.origin.url 2>/dev/null || true)"
  fi
  if [ -z "$repo_name" ]; then
    repo_name="$(cd "$project_path" && pwd)"
  fi
  printf '%s' "$repo_name" | shasum -a 256 | awk '{print substr($1,1,16)}'
}

cache_path() {
  local project_path="${1:?project_path obrigatorio}"
  printf '%s/%s.json' "$BASELINE_CACHE_DIR" "$(cache_repo_hash "$project_path")"
}

_lock_path() {
  printf '%s.lock' "$(cache_path "$1")"
}

# _with_lock <project_path> <cmd> [args...]
_with_lock() {
  local project_path="$1"
  shift
  local lock_file
  lock_file="$(_lock_path "$project_path")"
  mkdir -p "$(dirname "$lock_file")"

  if command -v flock >/dev/null 2>&1; then
    (
      exec 9>"$lock_file"
      if ! flock -w "$CACHE_LOCK_TIMEOUT" 9; then
        printf 'cache-local.sh: timeout de lock\n' >&2
        exit 3
      fi
      "$@"
    )
    return $?
  else
    local mk_lock="${lock_file}.d"
    local waited=0
    until mkdir "$mk_lock" 2>/dev/null; do
      sleep 1
      waited=$((waited + 1))
      if [ "$waited" -ge "$CACHE_LOCK_TIMEOUT" ]; then
        printf 'cache-local.sh: timeout de lock (fallback)\n' >&2
        return 3
      fi
    done
    ( "$@" ); local rc=$?
    rmdir "$mk_lock" 2>/dev/null || true
    return "$rc"
  fi
}

_ensure_file() {
  local project_path="$1"
  local repo_name="${2:-}"
  local file
  file="$(cache_path "$project_path")"
  mkdir -p "$(dirname "$file")"
  if [ ! -f "$file" ]; then
    [ -z "$repo_name" ] && repo_name="$(cd "$project_path" && basename "$(pwd)")"
    jq -nc --arg repo "$repo_name" --arg now "$(_iso_now)" \
      '{schema_version:1, repo:$repo, workspace_scope:null, pending_saga_sync:false, notes:{}, metrics_runs:[], updated_at:$now}' \
      > "$file"
  fi
  printf '%s' "$file"
}

cache_init() {
  local project_path="${1:?project_path obrigatorio}"
  local repo_name="${2:-}"
  _with_lock "$project_path" _ensure_file "$project_path" "$repo_name"
}

_scoped_title() {
  local title="$1"
  local workspace="${2:-}"
  if [ -n "$workspace" ]; then
    printf 'ws:%s:%s' "$workspace" "$title"
  else
    printf '%s' "$title"
  fi
}

# --- Upsert ---

_upsert_inner() {
  local project_path="$1"
  local scoped="$2"
  local content_json="$3"
  local file
  file="$(_ensure_file "$project_path")"
  local now; now="$(_iso_now)"
  local tmp; tmp="$(mktemp)"
  jq --arg t "$scoped" \
     --argjson c "$content_json" \
     --arg now "$now" \
     '.notes[$t] = {content: $c, updated_at: $now}
      | .updated_at = $now
      | .pending_saga_sync = true' \
     "$file" > "$tmp" && mv "$tmp" "$file"
}

cache_note_upsert() {
  local project_path="${1:?project_path obrigatorio}"
  local title="${2:?title obrigatorio}"
  local content_json="${3:?content_json obrigatorio}"
  shift 3
  local workspace=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --ws) workspace="$2"; shift 2 ;;
      --ws=*) workspace="${1#*=}"; shift ;;
      *) shift ;;
    esac
  done
  local scoped; scoped="$(_scoped_title "$title" "$workspace")"
  _with_lock "$project_path" _upsert_inner "$project_path" "$scoped" "$content_json"
}

# --- Get ---

cache_note_get() {
  local project_path="${1:?project_path obrigatorio}"
  local title="${2:?title obrigatorio}"
  shift 2
  local workspace=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --ws) workspace="$2"; shift 2 ;;
      --ws=*) workspace="${1#*=}"; shift ;;
      *) shift ;;
    esac
  done
  local scoped; scoped="$(_scoped_title "$title" "$workspace")"
  local file; file="$(cache_path "$project_path")"
  if [ ! -f "$file" ]; then
    printf 'null'
    return
  fi
  jq -c --arg t "$scoped" '.notes[$t] // null' "$file"
}

# --- List ---

cache_note_list() {
  local project_path="${1:?project_path obrigatorio}"
  shift
  local workspace=""
  local pattern=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --ws) workspace="$2"; shift 2 ;;
      --ws=*) workspace="${1#*=}"; shift ;;
      --pattern) pattern="$2"; shift 2 ;;
      --pattern=*) pattern="${1#*=}"; shift ;;
      *) shift ;;
    esac
  done
  local file; file="$(cache_path "$project_path")"
  if [ ! -f "$file" ]; then
    printf '[]'
    return
  fi
  local prefix=""
  [ -n "$workspace" ] && prefix="ws:${workspace}:"
  if [ -n "$pattern" ]; then
    jq -c --arg prefix "$prefix" --arg pattern "$pattern" \
      '.notes | to_entries
       | map(select(.key | startswith($prefix)) | select(.key | test($pattern)))
       | map({title: (if $prefix == "" then .key else (.key | sub("^" + $prefix; "")) end),
              content: .value.content, updated_at: .value.updated_at})' \
      "$file"
  else
    jq -c --arg prefix "$prefix" \
      '.notes | to_entries
       | map(select(.key | startswith($prefix)))
       | map({title: (if $prefix == "" then .key else (.key | sub("^" + $prefix; "")) end),
              content: .value.content, updated_at: .value.updated_at})' \
      "$file"
  fi
}

# --- Delete ---

_delete_inner() {
  local project_path="$1"
  local scoped="$2"
  local file; file="$(cache_path "$project_path")"
  [ -f "$file" ] || return 0
  local tmp; tmp="$(mktemp)"
  jq --arg t "$scoped" --arg now "$(_iso_now)" \
    'del(.notes[$t]) | .updated_at = $now | .pending_saga_sync = true' \
    "$file" > "$tmp" && mv "$tmp" "$file"
}

cache_note_delete() {
  local project_path="${1:?project_path obrigatorio}"
  local title="${2:?title obrigatorio}"
  shift 2
  local workspace=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --ws) workspace="$2"; shift 2 ;;
      --ws=*) workspace="${1#*=}"; shift ;;
      *) shift ;;
    esac
  done
  local scoped; scoped="$(_scoped_title "$title" "$workspace")"
  _with_lock "$project_path" _delete_inner "$project_path" "$scoped"
}

# --- Metrics ---

_metrics_append_inner() {
  local project_path="$1"
  local entry_json="$2"
  local file; file="$(_ensure_file "$project_path")"
  local tmp; tmp="$(mktemp)"
  jq --argjson e "$entry_json" --arg now "$(_iso_now)" \
    '.metrics_runs = (([$e] + .metrics_runs) | .[0:50])
     | .updated_at = $now
     | .pending_saga_sync = true' \
    "$file" > "$tmp" && mv "$tmp" "$file"
}

cache_metrics_append() {
  local project_path="${1:?project_path obrigatorio}"
  local entry_json="${2:?entry obrigatorio}"
  _with_lock "$project_path" _metrics_append_inner "$project_path" "$entry_json"
}

cache_metrics_recent() {
  local project_path="${1:?project_path obrigatorio}"
  local days="${2:-7}"
  local file; file="$(cache_path "$project_path")"
  if [ ! -f "$file" ]; then
    printf '[]'
    return
  fi
  local cutoff
  cutoff="$(date -u -v-"${days}"d +'%Y-%m-%dT%H:%M:%SZ' 2>/dev/null || date -u -d "${days} days ago" +'%Y-%m-%dT%H:%M:%SZ')"
  jq -c --arg cutoff "$cutoff" \
    '.metrics_runs | map(select((.timestamp // .created_at // "") >= $cutoff))' \
    "$file"
}

# --- Sync flag ---

_mark_inner() {
  local project_path="$1"
  local value="$2"
  local file; file="$(_ensure_file "$project_path")"
  local tmp; tmp="$(mktemp)"
  jq --argjson v "$value" --arg now "$(_iso_now)" \
    '.pending_saga_sync = $v | .updated_at = $now' \
    "$file" > "$tmp" && mv "$tmp" "$file"
}

cache_mark_synced()  { _with_lock "$1" _mark_inner "$1" "false"; }
cache_mark_pending() { _with_lock "$1" _mark_inner "$1" "true"; }

cache_is_pending() {
  local project_path="${1:?}"
  local file; file="$(cache_path "$project_path")"
  [ -f "$file" ] || { printf 'false'; return; }
  jq -r '.pending_saga_sync' "$file"
}

# CLI
if [ "${BASH_SOURCE[0]:-$0}" = "${0}" ]; then
  cmd="${1:-help}"
  shift || true
  case "$cmd" in
    init)           cache_init "$@" ;;
    upsert)         cache_note_upsert "$@" ;;
    get)            cache_note_get "$@" ;;
    list)           cache_note_list "$@" ;;
    delete)         cache_note_delete "$@" ;;
    metrics-append) cache_metrics_append "$@" ;;
    metrics-recent) cache_metrics_recent "$@" ;;
    path)           cache_path "$@" ;;
    hash)           cache_repo_hash "$@" ;;
    mark-synced)    cache_mark_synced "$@" ;;
    mark-pending)   cache_mark_pending "$@" ;;
    is-pending)     cache_is_pending "$@" ;;
    help|--help|-h) sed -n '3,10p' "$0" ;;
    *)
      printf 'cache-local.sh: comando desconhecido: %s\n' "$cmd" >&2
      exit 3
      ;;
  esac
fi
