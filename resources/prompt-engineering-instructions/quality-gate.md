# Quality Gate por Modulo

## Criterios obrigatorios

- Cobertura minima de referencias por modulo (>= 3 fontes, >= 1 oficial).
- Presenca de boas praticas + anti-padroes.
- Checklist operacional preenchivel.
- Secao de troubleshooting.
- Rastreabilidade para `references.md`.

## Resultado da execucao

| Modulo | Cobertura referencias | Boas praticas | Anti-padroes | Checklist | Troubleshooting | Status | Observacao |
|---|---|---|---|---|---|---|---|
| 01-fundamentos | OK | OK | OK | OK | OK | Aprovado | Sem pendencia |
| 02-structured-outputs-e-tool-use | OK | OK | OK | OK | OK | Aprovado | Sem pendencia |
| 03-rag-grounding-citations | OK | OK | OK | OK | OK | Aprovado | Revisitar benchmark de reranker |
| 04-seguranca-e-risco | OK | OK | OK | OK | OK | Aprovado | Sem pendencia |
| 05-avaliacao-e-promptops | OK | OK | OK | OK | OK | Aprovado | Definir thresholds por dominio na proxima iteracao |
| 06-playbooks-por-caso-de-uso | OK | OK | OK | OK | OK | Aprovado | Sem pendencia |

## Pendencias abertas

- `PEND-001`: calibrar thresholds de score para dominios distintos em `05-avaliacao-e-promptops`.
- `PEND-002`: validar stack de reranker para contexto de corpus interno em `03-rag-grounding-citations`.
