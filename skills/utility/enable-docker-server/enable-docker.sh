#!/usr/bin/env bash
set -euo pipefail

# ── Configuração ──────────────────────────────────────────────
MAX_RETRIES="${DOCKER_MAX_RETRIES:-5}"
POLL_INTERVAL="${DOCKER_POLL_INTERVAL:-30}"
INITIAL_WAIT="${DOCKER_INITIAL_WAIT:-60}"

# ── Modo de operação ─────────────────────────────────────────
# check  → retorna 0 se Docker disponível, 1 se não (sem tentar iniciar)
# start  → verifica e, se offline, inicia via rdctl start + polling
MODE="${1:-start}"

docker_online() {
  docker info >/dev/null 2>&1
}

case "$MODE" in
  check)
    if docker_online; then
      echo "DOCKER_STATUS=online"
      exit 0
    else
      echo "DOCKER_STATUS=offline"
      exit 1
    fi
    ;;

  start)
    if docker_online; then
      echo "DOCKER_STATUS=online"
      exit 0
    fi

    echo "Docker offline — executando rdctl start..."
    rdctl start 2>/dev/null || true

    echo "Aguardando ${INITIAL_WAIT}s para o Rancher Desktop iniciar..."
    sleep "$INITIAL_WAIT"

    if docker_online; then
      echo "DOCKER_STATUS=online"
      exit 0
    fi

    attempt=0
    while [ "$attempt" -lt "$MAX_RETRIES" ]; do
      attempt=$((attempt + 1))
      echo "Aguardando ${POLL_INTERVAL}s... (tentativa ${attempt}/${MAX_RETRIES})"
      sleep "$POLL_INTERVAL"

      if docker_online; then
        echo "DOCKER_STATUS=online"
        exit 0
      fi
    done

    echo "DOCKER_STATUS=offline"
    echo "Docker não iniciou após espera inicial de ${INITIAL_WAIT}s + ${MAX_RETRIES} tentativas (~$(( INITIAL_WAIT + MAX_RETRIES * POLL_INTERVAL ))s)."
    exit 1
    ;;

  *)
    echo "Uso: $0 [check|start]"
    echo "  check  — verifica se Docker está disponível (exit 0=sim, 1=não)"
    echo "  start  — verifica e inicia Rancher Desktop se necessário"
    echo ""
    echo "Variáveis de ambiente:"
    echo "  DOCKER_INITIAL_WAIT  — espera inicial após rdctl start em segundos (padrão: 60)"
    echo "  DOCKER_MAX_RETRIES   — máximo de tentativas de polling (padrão: 5)"
    echo "  DOCKER_POLL_INTERVAL — intervalo entre tentativas em segundos (padrão: 30)"
    exit 2
    ;;
esac
