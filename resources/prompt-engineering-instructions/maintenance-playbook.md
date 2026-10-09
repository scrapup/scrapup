# Rotina de Revisao e Manutencao Continua

## Ciclo minimo

- Revisao mensal completa de todos os modulos.
- Revisao extraordinaria em ate 2 dias uteis para mudanca critica de seguranca/governanca.
- Atualizacao de modulo critico em ate 5 dias uteis apos mudanca relevante de fonte.

## Ownership por modulo

| Modulo | Owner | SLA de atualizacao | Backup |
|---|---|---|---|
| 01-fundamentos | PromptOps Lead | 5 dias uteis | Tech Writer |
| 02-structured-outputs-e-tool-use | AI Platform Engineer | 5 dias uteis | PromptOps Lead |
| 03-rag-grounding-citations | Retrieval Owner | 5 dias uteis | AI Platform Engineer |
| 04-seguranca-e-risco | Security Champion | 2 dias uteis (criticos) | AI Platform Engineer |
| 05-avaliacao-e-promptops | PromptOps Lead | 5 dias uteis | QA AI Specialist |
| 06-playbooks-por-caso-de-uso | Product AI Engineer | 5 dias uteis | PromptOps Lead |

## Gatilhos de revisao extraordinaria

- Mudanca major em API/modelo de provedor.
- Novo guidance de seguranca (OWASP/NIST/provedor).
- Queda relevante em metricas de qualidade de prompt/evals.
- Incidente operacional relacionado a uso incorreto de prompts.

## Changelog padrao por modulo

```md
## YYYY-MM-DD - vX.Y.Z
- Mudanca:
- Motivo:
- Evidencia:
- Impacto esperado:
- Owner:
```

## Processo operacional

1. Abrir issue de revisao no backlog documental.
2. Atualizar modulo alvo e `references.md`.
3. Executar `quality-gate.md` para o modulo.
4. Registrar changelog no proprio modulo.
5. Publicar handoff com status.
