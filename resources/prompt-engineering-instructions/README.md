# Prompt Engineering Instructions

Manual modular para aplicacao de Prompt Engineering e Context Engineering com base em evidencias externas rastreaveis.

## Ordem de leitura recomendada

1. `01-fundamentos.md`
2. `02-structured-outputs-e-tool-use.md`
3. `03-rag-grounding-citations.md`
4. `04-seguranca-e-risco.md`
5. `05-avaliacao-e-promptops.md`
6. `06-playbooks-por-caso-de-uso.md`
7. `references.md`
8. `editorial-contract.md`
9. `quality-gate.md`
10. `maintenance-playbook.md`

## Objetivo editorial

- Reduzir variabilidade na escrita de prompts e no desenho de contratos de tool-use.
- Garantir rastreabilidade por secao via `references.md`.
- Registrar conflitos entre fontes e explicitar mitigacoes.

## Modulos

| Modulo | Objetivo |
|---|---|
| 01-fundamentos | Definir fundamentos, criterios de qualidade e baseline de prompts |
| 02-structured-outputs-e-tool-use | Padronizar contratos, schema validation e chamadas de ferramentas |
| 03-rag-grounding-citations | Controlar retrieval, grounding e citacao verificavel |
| 04-seguranca-e-risco | Mitigar prompt injection, jailbreak e exfiltracao |
| 05-avaliacao-e-promptops | Operar ciclo de avaliacao continua e governanca |
| 06-playbooks-por-caso-de-uso | Aplicar padroes em fluxos comuns (suporte, coding, extracao, resumo) |

## Regras de uso

- Toda recomendacao principal deve apontar para evidencia em `references.md`.
- Recomendacoes sem evidencia entram apenas como nota experimental.
- Modulo sem checklist, anti-padroes e troubleshooting nao pode ser marcado como pronto.
