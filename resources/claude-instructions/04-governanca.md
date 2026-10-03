# 04 - Governanca

## Escopo

Padronizar o uso de CLAUDE.md (memoria), skills, subagents, commands, plugins, permissoes e hooks no ecossistema Scrapforge para manter consistencia e auditabilidade.

## Quando Usar

- Criar/editar memoria (CLAUDE.md), skills e commands.
- Revisar consistencia estrutural apos mudancas em fluxos do plugin.
- Definir precedencia de instrucoes e permissoes quando houver conflito.

## Estruturas de Governanca

- **CLAUDE.md (memoria hierarquica):** diretrizes persistentes (enterprise, user `~/.claude/CLAUDE.md`, projeto `./CLAUDE.md` ou `.claude/CLAUDE.md`, local `CLAUDE.local.md`). Imports com `@caminho`; edicao via `/memory`.
- **Skills (`SKILL.md`):** procedimentos reutilizaveis orientados a contexto, em `~/.claude/skills/<nome>/`, `.claude/skills/` ou em plugin `skills/`. Frontmatter: `name`, `description`, `allowed-tools`, `model`, `disable-model-invocation`, `user-invocable`, `paths`. Invocacao por `/<nome>`; scripts/templates via `${CLAUDE_SKILL_DIR}`.
- **Subagents (`agents/`):** execucao isolada para analise/implementacao, em `~/.claude/agents/<nome>.md`, `.claude/agents/` ou plugin `agents/`. Frontmatter: `name`, `description`, `tools`, `model`, `permissionMode`, `skills`, `mcpServers`. Despacho via Agent tool (`subagent_type`), `@agent-<nome>` ou `claude --agent <nome>`.
- **Commands (`/nome`):** pontos de entrada operacionais em `.claude/commands/<nome>.md` ou plugin `commands/`. Suportam `$ARGUMENTS`, `$1`...; hoje unificados com skills.
- **Plugins:** agregam CLAUDE.md, skills, subagents, commands, MCP e hooks; geridos via `/plugin` e marketplaces.

## Precedencia e Decisao

A precedencia de settings/instrucoes (do mais forte ao mais fraco):

1. **Enterprise** (politica gerida pela organizacao).
2. **Linha de comando** (flags da invocacao `claude`).
3. **Projeto local** (`.claude/settings.local.json`, `CLAUDE.local.md`).
4. **Projeto compartilhado** (`.claude/settings.json`, `./CLAUDE.md`).
5. **User** (`~/.claude/settings.json`, `~/.claude/CLAUDE.md`).

Skills e commands entram por relevancia (descoberta pelo modelo) ou invocacao explicita (`/<nome>`).

### Nota sobre memoria e escopo de arquivo

- Regras com escopo de arquivo (antigos globs) -> skills com frontmatter `paths:` e `user-invocable: false`.
- CLAUDE.md aninhado em subpastas refina o escopo local.
- Quando memoria e skills coexistirem, manter coerencia sem duplicar textos longos.

## Criterio de Escolha: CLAUDE.md vs Skill vs Command

| Artefato | Use quando | Evite quando |
|---|---|---|
| CLAUDE.md (memoria) | Diretriz recorrente e curta, sempre ativa | Workflow longo multi-etapas |
| Skill | Procedimento detalhado e repetivel | Restricao simples de estilo |
| Command | Atalho operacional acionado sob demanda | Regra sempre ativa |

## Responsabilidades

1. Manter nomenclatura consistente entre artefatos.
2. Garantir que mudancas em command/skill/subagent atualizem catalogos e diagramas quando houver impacto.
3. Preservar rastreabilidade de fontes oficiais no manual.
4. Evitar duplicidade semantica entre secoes.

## Passo a Passo de Mudanca Governada

1. Identificar artefato principal da mudanca (`CLAUDE.md`, `skill`, `command`, `subagent`, `plugin`).
2. Verificar impactos transversais:
   - catalogos (`README`, bootstrap, diagramas);
   - dependencias de skill;
   - comandos/subagents relacionados.
3. Atualizar artefato principal.
4. Sincronizar artefatos dependentes.
5. Validar consistencia de naming, links e gatilhos (`description`, `paths`).

### Matriz de Sincronizacao Minima

| Mudanca principal | Sincronizacoes obrigatorias |
|---|---|
| Nova diretriz em `CLAUDE.md` | `README` (se catalogada), referencias internas e exemplos |
| Nova `skill` | Catalogo da skill, cadeia de dependencia e `description`/`paths` |
| Novo `command` | `README`, bootstrap e diagramas de modulo quando aplicavel |
| Novo `subagent` | Catalogo de agents, `tools`/`permissionMode`/`mcpServers` e notas de governanca |
| Atualizacao de plugin | Skills/commands/subagents/MCP/hooks associados e notas de governanca |

## Hooks

Automatizacoes deterministicas configuradas em `settings.json` (chave `hooks`) ou `hooks/hooks.json` (plugin). Eventos disponiveis:

- `PreToolUse`, `PostToolUse`
- `UserPromptSubmit`
- `SessionStart`, `Stop`, `SubagentStop`
- `Notification`, `PreCompact`

Usar hooks para enforcement deterministico (lint, bloqueio de comandos, registro de evidencias), nunca para logica que dependa do julgamento do modelo.

## Permissoes

- Configuradas em `settings.json`, chave `permissions: { allow: [], deny: [], ask: [] }` e `defaultMode`.
- Modos: `default`, `acceptEdits`, `plan`, `bypassPermissions`.
- Comando `/permissions` para inspecionar/ajustar em sessao.
- Aplicar menor privilegio; tools MCP entram como `mcp__<server>__<tool>`.

## Limites Operacionais

- Nao criar command sem descrever objetivo e instrucoes operacionais.
- Nao alterar CLAUDE.md/skill sem avaliar impacto em README/bootstrap/diagrama.
- Nao publicar orientacao critica sem referencia oficial.

## Anti-padroes

- Duplicar instrucoes identicas em CLAUDE.md e skill sem secao canonica.
- Introduzir command sem refletir o nome nos catalogos.
- Usar memoria gigante para substituir skill procedural.

## Checklist de Consistencia

- Nome do command consistente entre `commands/`, `README.md` e memoria aplicavel.
- Cadeias de dependencias documentadas quando houver mudanca de fluxo.
- Referencias cruzadas funcionando entre capitulos do manual.
- Fontes oficiais associadas para secoes criticas de governanca.
- Sem duplicidade de instrucao entre CLAUDE.md/skill/command sem secao canonica.

## Troubleshooting

| Sintoma | Causa Provavel | Acao |
|---|---|---|
| Conflito entre instrucoes | Precedencia nao definida | Aplicar ordem Enterprise > CLI > Projeto local > Projeto compartilhado > User e registrar decisao |
| Command nao aparece em catalogo | Falha de doc-sync | Atualizar README/bootstrap/diagrama e revalidar |
| Skill nao e acionada quando esperado | Gatilho fraco/descricao vaga | Refinar `description`/`paths` e exemplos de uso |
| Permissao nao aplicada | Setting em escopo de menor precedencia | Revisar hierarquia e usar `/permissions` |

## Cross-links

- Integracoes e autenticacao: [03-mcp-sdk.md](./03-mcp-sdk.md)
- Playbooks e verificacao final: [05-operacao.md](./05-operacao.md)

## Fontes Oficiais

- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/skills
- https://code.claude.com/docs/en/sub-agents
- https://code.claude.com/docs/en/slash-commands
- https://code.claude.com/docs/en/plugins
- https://code.claude.com/docs/en/settings
- https://code.claude.com/docs/en/hooks
