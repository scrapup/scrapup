#!/usr/bin/env bash
# baseline-check.sh — dispatcher unico da skill baseline-assessment.
#
# Modos operacionais:  assess, verify-diff, report
# Modos administrativos: override (set|remove), classify (confirm)
#
# Exit codes conforme plan.md 4.6:
#   assess: 0 em {cached,green,red-known,no-execution}; 1 em {blocked,blocked-classification}; 3 erro
#   verify-diff: 0 pass; 1 fail; 2 warn; 3 erro
#   report: 0 sempre (3 erro nao tratavel)
#   override/classify: 0 sucesso; 1 validacao rejeitada; 3 erro

set -euo pipefail

DISPATCH_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_print_usage() {
  cat <<'EOF'
baseline-check.sh <mode> [flags]

Modos operacionais:
  assess       [--project-path <p>] [--workspace <ws>] [--force] [--timeout-seconds <n>]
               Avaliacao completa: readiness + descoberta + classificacao + execucao
               da suite + persistencia de baseline-current/baseline-latest.

  verify-diff  [--project-path <p>] [--workspace <ws>] [--scope=staged|commit|push]
               [--base <ref>]
               Verificacao incremental sobre o diff; aplica principio
               "nao regride o baseline". Default --scope=commit; --workspace
               default auto-detect (ver plan.md 4.1.1).

  report       [--project-path <p>] [--workspace <ws>]
               Leitura pura do estado persistido. Nao executa nada.
               Recomputa category_effective na hora.

Modos administrativos:
  override set    --script=<test|lint|build|typecheck|cov>
                  --alternative=<comando|disabled>
                  --reason=<motivo>
                  [--ttl-days=<1..30>] (default 7)
                  [--project-path <p>] [--workspace <ws>]

  override remove --script=<s> [--project-path <p>] [--workspace <ws>]

  classify confirm --category=<saudavel|legado-estavel|legado-docker-dependent|legado-critico|sem-infra>
                   --reason=<motivo>
                   [--project-path <p>] [--workspace <ws>]

Variaveis de ambiente:
  BASELINE_CACHE_DIR            caminho do cache (default ~/.claude/plugins/local/scrapup/cache/baseline)
  CACHE_LOCK_TIMEOUT            timeout do flock em segundos (default 30)
  BASELINE_PLUGIN_DIR           caminho do plugin scrapup (default ~/.claude/plugins/local/scrapup)
  BASELINE_SKIP_DOCKER=1        pula verificacao de Docker
  BASELINE_SKIP_NODE=1          pula verificacao de Node
  BASELINE_MOCK_DOCKER=ok|fail|skip    mock de enable-docker-server (testes)
  BASELINE_MOCK_NODE=ok|fail|skip      mock de setup-node-env (testes)
  BASELINE_MOCK_SUITE=green|red|timeout mock da execucao da suite (assess)
  BASELINE_MOCK_TESTS=green|red|flaky|pre-existing-red  mock do verify-diff
  BASELINE_MOCK_LINT=clean|errors-new|errors-existing
  BASELINE_MOCK_COVERAGE=100|80|null
EOF
}

MODE="${1:-}"
shift || true

# Limpeza de locks em SIGINT
trap 'find "${BASELINE_CACHE_DIR:-${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/plugins/local/scrapup}/cache/baseline}" -name "*.lock.d" -maxdepth 2 -type d -exec rmdir {} + 2>/dev/null || true' INT TERM

case "$MODE" in
  assess)
    exec bash "$DISPATCH_DIR/assess-core.sh" "$@"
    ;;

  verify-diff)
    exec bash "$DISPATCH_DIR/verify-diff.sh" "$@"
    ;;

  report)
    exec bash "$DISPATCH_DIR/report.sh" "$@"
    ;;

  override)
    SUBCMD="${1:-}"
    if [ -z "$SUBCMD" ]; then
      printf 'baseline-check.sh override: subcomando obrigatorio (set|remove)\n' >&2
      _print_usage >&2
      exit 1
    fi
    shift
    exec bash "$DISPATCH_DIR/override.sh" "$SUBCMD" "$@"
    ;;

  classify)
    SUBCMD="${1:-}"
    if [ -z "$SUBCMD" ]; then
      printf 'baseline-check.sh classify: subcomando obrigatorio (confirm)\n' >&2
      _print_usage >&2
      exit 1
    fi
    shift
    exec bash "$DISPATCH_DIR/classify.sh" "$SUBCMD" "$@"
    ;;

  ""|--help|-h|help)
    _print_usage
    exit 0
    ;;

  *)
    printf 'baseline-check.sh: modo desconhecido: %s\n\n' "$MODE" >&2
    _print_usage >&2
    exit 3
    ;;
esac
