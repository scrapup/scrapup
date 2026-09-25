#!/usr/bin/env bash
#
# getNextUserStoryId.sh
# ---------------------
# Gerador sequencial GLOBAL de IDs de User Story para a skill
# blueprint. O contador e persistido em
#   ./resources/blueprint.config.json
# e e incrementado a cada chamada, garantindo que IDs sejam unicos e
# crescentes independentemente do projeto ou da execucao.
#
# Uso:
#   ./getNextUserStoryId.sh            # consome e devolve o proximo ID
#   ./getNextUserStoryId.sh --peek     # mostra o proximo ID sem consumir
#   ./getNextUserStoryId.sh --current  # mostra o ultimo ID emitido
#   ./getNextUserStoryId.sh --help     # ajuda
#
# Saida (stdout): apenas o numero inteiro do ID (sem prefixo "US-").
# Erros vao para stderr. Exit code != 0 em qualquer falha.
#
# Formato esperado do config (uma unica chave inteira):
#   {
#       "LATEST_USER_STORY_ID": 0
#   }
#
# Notas:
# - Bootstrap automatico: se o config nao existir, e criado com 0.
# - Escrita atomica: mktemp + mv no mesmo filesystem.
# - Sem dependencia de jq. Le com grep, reescreve o JSON inteiro.
# - Compatível com bash 3.2+ (macOS default) e bash 4+/5+.

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
CONFIG_PATH="${SCRIPT_DIR}/resources/blueprint.config.json"
CONFIG_DIR="$( dirname "${CONFIG_PATH}" )"
CONFIG_KEY="LATEST_USER_STORY_ID"

print_help() {
    cat <<EOF
getNextUserStoryId.sh - Gerador sequencial global de IDs de User Story.

Uso:
  $(basename "$0")            Consome e devolve o proximo ID (incrementa o contador)
  $(basename "$0") --peek     Mostra o proximo ID sem consumir
  $(basename "$0") --current  Mostra o ultimo ID emitido
  $(basename "$0") --help     Esta mensagem

Config: ${CONFIG_PATH}
EOF
}

ensure_config() {
    mkdir -p "${CONFIG_DIR}"
    if [[ ! -f "${CONFIG_PATH}" ]]; then
        printf '{\n    "%s": 0\n}\n' "${CONFIG_KEY}" > "${CONFIG_PATH}"
    fi
}

read_current() {
    local raw
    raw="$(grep -oE "\"${CONFIG_KEY}\"[[:space:]]*:[[:space:]]*-?[0-9]+" "${CONFIG_PATH}" || true)"
    if [[ -z "${raw}" ]]; then
        echo "Erro: chave '${CONFIG_KEY}' nao encontrada em ${CONFIG_PATH}" >&2
        exit 1
    fi
    local value
    value="$(printf '%s' "${raw}" | grep -oE '\-?[0-9]+$')"
    if ! [[ "${value}" =~ ^-?[0-9]+$ ]]; then
        echo "Erro: valor de '${CONFIG_KEY}' nao e um inteiro valido: '${value}'" >&2
        exit 1
    fi
    printf '%s' "${value}"
}

write_value() {
    local new_value="$1"
    local tmp
    tmp="$(mktemp "${CONFIG_PATH}.XXXXXX")"
    printf '{\n    "%s": %d\n}\n' "${CONFIG_KEY}" "${new_value}" > "${tmp}"
    chmod 644 "${tmp}"
    mv "${tmp}" "${CONFIG_PATH}"
}

mode="consume"
if [[ $# -gt 0 ]]; then
    case "$1" in
        --peek)    mode="peek" ;;
        --current) mode="current" ;;
        --help|-h) print_help; exit 0 ;;
        *)
            echo "Erro: argumento desconhecido '$1'." >&2
            echo "Use --help para ver as opcoes." >&2
            exit 2
            ;;
    esac
fi

ensure_config
current="$(read_current)"

case "${mode}" in
    current)
        echo "${current}"
        ;;
    peek)
        echo $((current + 1))
        ;;
    consume)
        next=$((current + 1))
        write_value "${next}"
        echo "${next}"
        ;;
esac
