# 05 - Operacao

## Escopo

Playbooks praticos para execucao e troubleshooting do manual e do command de atualizacao.

## Quando Usar

- Atualizacao completa ou parcial do manual.
- Triagem de falhas de consistencia documental.
- Validacao final de prontidao antes de concluir entrega.

## Playbook 1: Atualizacao Completa do Manual

1. Conferir escopo da alteracao e capitulos afetados.
2. Atualizar conteudo do capitulo canonico.
3. Atualizar `references.md` com fontes oficiais e data de revisao.
4. Validar links internos e cross-links.
5. Consolidar checklist final de qualidade documental.

### Criticos do Playbook 1

- Validar origem oficial por subsecao alterada.
- Evitar atualizacao parcial silenciosa de termos transversais.
- Registrar pendencias objetivas em caso de bloqueio.

## Playbook 2: Atualizacao Parcial por Secao

1. Selecionar secao alvo.
2. Revisar consistencia com os capitulos relacionados.
3. Atualizar referencias da secao.
4. Executar validacao documental localizada.

### Criticos do Playbook 2

- Garantir que cross-links nao ficaram quebrados.
- Se houver mudanca de conceito global, promover para escopo completo.

## Playbook 3: Governanca de Permission Modes e Permissoes

1. Verificar `settings.json` ativo (user `~/.claude/settings.json`, projeto `.claude/settings.json`, local `.claude/settings.local.json`).
2. Confirmar `defaultMode` e a chave `permissions` (`allow`/`deny`/`ask`).
3. Revisar `allow`/`deny` (incluindo tools MCP `mcp__<server>__<tool>` e comandos shell) com criterio de menor privilegio.
4. Ao usar `acceptEdits`/`bypassPermissions`, validar que comandos sensiveis permanecem em `deny` ou `ask`.
5. Inspecionar em sessao com `/permissions` e registrar evidencias de decisao de risco.

## Playbook 4: Rollback Documental Seguro

1. Identificar o conjunto minimo de arquivos impactados pela regressao.
2. Reverter somente o bloco problematico, preservando alteracoes validas da rodada.
3. Revalidar links internos e `references.md` apos rollback.
4. Registrar motivo, escopo e status no artefato de evidencias local.
5. Planejar tarefa de correcao incremental para evitar reintroducao do problema.

## Execucao Background e Headless

- **Headless:** `claude -p "<prompt>" --output-format json` para automacao scriptavel.
- **Background tasks:** tarefas em segundo plano para execucoes longas sem bloquear a sessao.
- **Cloud agents / routines agendadas:** `/schedule` (cron) para execucoes recorrentes; substitui o conceito de Automations/Background do Cursor.
- **Loops recorrentes:** `/loop` para repetir um prompt/command em intervalos.

> Nota de portabilidade: o **Canvas** do Cursor nao tem equivalente direto no Claude Code; usar artefatos de arquivo + evidencias versionadas no lugar.

## Troubleshooting do Manual e do Command

| Sintoma | Causa Provavel | Acao Recomendada |
|---|---|---|
| Link interno quebrado | Renomeacao sem atualizacao do indice | Corrigir link em README e capitulo relacionado |
| Secao sem fonte oficial | Conteudo novo sem rastreabilidade | Atualizar `references.md` e fontes da secao |
| Conteudo duplicado em capitulos | Falta de secao canonica | Consolidar no capitulo principal e manter cross-link |
| Command incompleto | Checklist nao incorporado | Atualizar command com pipeline e criterios de bloqueio |
| Divergencia de nomenclatura | Mudanca parcial em artefatos estruturais | Rodar reconciliacao em README/bootstrap/diagrama |
| Contexto perdido entre execucoes | Compactacao automatica ou falta de `--continue`/`--resume` | Usar `/context` e `/clear` com criterio; retomar com `--continue`/`--resume` |

## Fora de Escopo

Este manual cobre operacao documental do Claude Code/Scrapforge. Investigacao de runtime de aplicacoes (logs de producao, traces, metricas de servicos) deve seguir as skills dedicadas do ecossistema, como `saga-session`.

## Verificacao Final

- Todas as secoes com fonte oficial.
- Todos os links internos navegaveis.
- Nome do command consistente nos artefatos estruturais.
- Evidencias de validacao registradas.
- Lacunas remanescentes registradas com prioridade sugerida.

## Anti-padroes

- Fechar tarefa sem atualizar `references.md`.
- Marcar sucesso com checklist bloqueante incompleto.
- Tratar erro de estrutura como item cosmetico.

## Escalacao

- Bloqueio critico: parar conclusao e registrar pendencia objetiva.
- Item menor: registrar para melhoria continua sem ocultar o desvio.
- Nunca incluir segredos/tokens em evidencias de troubleshooting.
- Em divergencia de governanca, aplicar precedencia e solicitar decisao explicita do utilizador.

## Checklist de Prontidao Operacional

- [ ] Atualizacao mapeada em capitulo canonico.
- [ ] Rastreabilidade oficial atualizada por subsecao.
- [ ] Links internos e cross-links validados.
- [ ] Impacto em governanca avaliado (README/bootstrap/diagrama).
- [ ] Evidencia final registrada com status (sucesso/bloqueado).

## Cross-links

- Base conceitual de execucao: [01-fundamentos.md](./01-fundamentos.md)
- Regras e responsabilidades de consistencia: [04-governanca.md](./04-governanca.md)

## Fontes Oficiais

- https://code.claude.com/docs/en/overview
- https://code.claude.com/docs/en/headless
- https://code.claude.com/docs/en/settings
- https://code.claude.com/docs/en/costs
- https://docs.claude.com/en/docs/claude-code/overview
