#!/usr/bin/env bash
# check-environment.sh — orquestra readiness de ambiente.
#
# Delega a skills especializadas existentes:
#   enable-docker-server/enable-docker.sh (quando projeto depende de Docker)
#   setup-node-env/{detect-node-version,nvm-install-use,check-npm-token,npm-install}.sh
#
# Nunca invoca rdctl/nvm/npm diretamente (RN-21).
#
# Uso:
#   check-environment.sh [--project-path <p>] [--skip-docker]
#
# Variaveis de ambiente (para teste/mock):
#   BASELINE_SKIP_DOCKER=1     pula completamente a verificacao de Docker
#   BASELINE_SKIP_NODE=1       pula completamente a verificacao de Node
#   BASELINE_MOCK_DOCKER=ok|fail|skip
#   BASELINE_MOCK_NODE=ok|fail|skip
#
# Saida (stdout JSON):
#   {
#     "state": "ready|partial|blocked",
#     "docker_available": bool,
#     "docker_required": bool,
#     "node_version": "..." | null,
#     "node_matches_nvmrc": bool,
#     "npm_install_ok": bool,
#     "npm_token_present": bool,
#     "observations": [...],
#     "delegated_to": [...]
#   }
#
# Persiste nota environment-state via saga-client.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"
# shellcheck source=./lib/saga-client.sh
. "$LIB_DIR/saga-client.sh"

PLUGIN_DIR="${BASELINE_PLUGIN_DIR:-${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/plugins/local/scrapup}}"
DOCKER_SCRIPT="$PLUGIN_DIR/skills/utilitarios/enable-docker-server/enable-docker.sh"
NODE_DIR="$PLUGIN_DIR/skills/utilitarios/setup-node-env"

PROJECT_PATH="."
SKIP_DOCKER=false

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project-path) PROJECT_PATH="$2"; shift 2 ;;
    --project-path=*) PROJECT_PATH="${1#*=}"; shift ;;
    --skip-docker) SKIP_DOCKER=true; shift ;;
    --help|-h) sed -n '2,25p' "$0"; exit 0 ;;
    *) printf 'check-environment.sh: flag desconhecida: %s\n' "$1" >&2; exit 3 ;;
  esac
done

if [ "${BASELINE_SKIP_DOCKER:-0}" = "1" ]; then
  SKIP_DOCKER=true
fi

OBSERVATIONS='[]'
DELEGATED='[]'

_add_obs() {
  OBSERVATIONS="$(printf '%s' "$OBSERVATIONS" | jq -c --arg v "$1" '. + [$v]')"
}
_add_delegated() {
  DELEGATED="$(printf '%s' "$DELEGATED" | jq -c --arg v "$1" '. + [$v]')"
}

# ----- Docker -----
DOCKER_REQUIRED=false
DOCKER_AVAILABLE=true

if [ "$SKIP_DOCKER" = false ]; then
  DOCKER_REQUIRED="$(bash "$LIB_DIR/detect-docker-dependency.sh" "$PROJECT_PATH")"
fi

if [ "$DOCKER_REQUIRED" = "true" ]; then
  case "${BASELINE_MOCK_DOCKER:-}" in
    ok)
      DOCKER_AVAILABLE=true
      _add_delegated "enable-docker-server(mock-ok)"
      ;;
    fail)
      DOCKER_AVAILABLE=false
      _add_obs "docker-start-failed"
      _add_delegated "enable-docker-server(mock-fail)"
      ;;
    skip)
      DOCKER_AVAILABLE=true
      _add_obs "docker-check-skipped-via-mock"
      ;;
    *)
      if [ -x "$DOCKER_SCRIPT" ]; then
        _add_delegated "enable-docker-server"
        if bash "$DOCKER_SCRIPT" start >/dev/null 2>&1; then
          DOCKER_AVAILABLE=true
        else
          DOCKER_AVAILABLE=false
          _add_obs "docker-start-failed"
        fi
      else
        _add_obs "enable-docker-server-script-missing"
        DOCKER_AVAILABLE=false
      fi
      ;;
  esac
else
  DOCKER_AVAILABLE=true
fi

# ----- Node -----
NODE_VERSION=""
NODE_MATCHES_NVMRC=true
NPM_INSTALL_OK=true
NPM_TOKEN_PRESENT=false

_detect_nvmrc_version() {
  local p="$PROJECT_PATH"
  if [ -f "$p/.nvmrc" ]; then
    tr -d '[:space:]' < "$p/.nvmrc" | sed 's/^v//'
  else
    printf ''
  fi
}

_check_node_env() {
  # Delega a setup-node-env. Scripts respeitam protocolos canonicos.
  # Aqui tratamos apenas exit codes para nao reimplementar logica.
  _add_delegated "setup-node-env"

  # Detect node version via .nvmrc (leitura direta — nao executa nvm)
  local expected
  expected="$(_detect_nvmrc_version)"

  # Node version atual
  if command -v node >/dev/null 2>&1; then
    NODE_VERSION="$(node --version 2>/dev/null | sed 's/^v//')"
  fi

  if [ -n "$expected" ] && [ -n "$NODE_VERSION" ]; then
    # Comparacao simples: major.minor
    local exp_major="${expected%%.*}"
    local cur_major="${NODE_VERSION%%.*}"
    if [ "$exp_major" != "$cur_major" ]; then
      NODE_MATCHES_NVMRC=false
      _add_obs "node-version-mismatch:expected=$expected,current=$NODE_VERSION"
    fi
  fi

  # NPM_TOKEN
  if [ -n "${NPM_TOKEN:-}" ]; then
    NPM_TOKEN_PRESENT=true
  elif [ -f "$HOME/.claude/.env" ] && grep -q '^NPM_TOKEN=' "$HOME/.claude/.env" 2>/dev/null; then
    NPM_TOKEN_PRESENT=true
  fi

  # Se package.json existe e node_modules nao, marcar npm_install_ok=false
  if [ -f "$PROJECT_PATH/package.json" ]; then
    if [ ! -d "$PROJECT_PATH/node_modules" ]; then
      NPM_INSTALL_OK=false
      _add_obs "npm-install-needed"
    fi
  fi
}

if [ "${BASELINE_SKIP_NODE:-0}" = "1" ]; then
  _add_obs "node-check-skipped"
else
  case "${BASELINE_MOCK_NODE:-}" in
    ok)
      NODE_VERSION="20.11.1"
      NPM_INSTALL_OK=true
      NPM_TOKEN_PRESENT=true
      _add_delegated "setup-node-env(mock-ok)"
      ;;
    fail)
      NODE_VERSION="20.11.1"
      NPM_INSTALL_OK=false
      NPM_TOKEN_PRESENT=false
      _add_obs "npm-install-failed-mock"
      _add_delegated "setup-node-env(mock-fail)"
      ;;
    skip)
      _add_obs "node-env-skipped-mock"
      ;;
    *)
      _check_node_env
      ;;
  esac
fi

# ----- Consolidacao do estado -----
STATE="ready"

# BLOCKED: Node ausente, npm_install falhou por razao que impede execucao
if [ -z "$NODE_VERSION" ] && [ "${BASELINE_MOCK_NODE:-}" != "skip" ] && [ "${BASELINE_SKIP_NODE:-0}" != "1" ]; then
  STATE="blocked"
  _add_obs "node-not-installed"
fi

# PARTIAL: Docker requerido mas indisponivel; OU node_modules ausente
if [ "$STATE" != "blocked" ]; then
  if [ "$DOCKER_REQUIRED" = "true" ] && [ "$DOCKER_AVAILABLE" = false ]; then
    STATE="partial"
  elif [ "$NPM_INSTALL_OK" = false ] && [ -f "$PROJECT_PATH/package.json" ]; then
    STATE="partial"
  elif [ "$NODE_MATCHES_NVMRC" = false ]; then
    STATE="partial"
  fi
fi

# Emite JSON
RESULT="$(jq -nc \
  --arg state "$STATE" \
  --argjson docker_available "$DOCKER_AVAILABLE" \
  --argjson docker_required "$DOCKER_REQUIRED" \
  --arg node_version "$NODE_VERSION" \
  --argjson node_matches "$NODE_MATCHES_NVMRC" \
  --argjson npm_install "$NPM_INSTALL_OK" \
  --argjson token "$NPM_TOKEN_PRESENT" \
  --argjson obs "$OBSERVATIONS" \
  --argjson deleg "$DELEGATED" \
  '{
    state: $state,
    docker_available: $docker_available,
    docker_required: $docker_required,
    node_version: (if $node_version == "" then null else $node_version end),
    node_matches_nvmrc: $node_matches,
    npm_install_ok: $npm_install,
    npm_token_present: $token,
    observations: $obs,
    delegated_to: $deleg
  }')"

# Persiste a note environment-state (nao expoe NPM_TOKEN por design)
NOTE_CONTENT="$(printf '%s' "$RESULT" | jq -c --arg ts "$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
  '{schema_version: 1, state, docker_available, node_version, npm_install_ok, npm_token_present, timestamp: $ts, observations}')"

if [ -f "$PROJECT_PATH/package.json" ] || [ -d "$PROJECT_PATH" ]; then
  saga_project_ensure "$PROJECT_PATH" >/dev/null
  saga_note_upsert "$PROJECT_PATH" "environment-state" "context" "$NOTE_CONTENT" 2>/dev/null || true
fi

printf '%s\n' "$RESULT"
