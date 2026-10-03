# References Matrix (Official Sources)

Matriz de rastreabilidade entre secoes/subsecoes do manual e fontes oficiais do Claude Code.

## Inventario Oficial por Dominio

| Dominio | Fonte oficial | Officiality | Notas |
|---|---|---|---|
| fundamentos | https://code.claude.com/docs/en/overview | official | Hub principal e taxonomia de docs |
| modos-interativos | https://code.claude.com/docs/en/interactive-mode | official | Plan mode, permission modes e atalhos |
| memoria | https://code.claude.com/docs/en/memory | official | CLAUDE.md hierarquico, imports e `/memory` |
| cli-reference | https://code.claude.com/docs/en/cli-reference | official | Flags e subcomandos da CLI `claude` |
| headless | https://code.claude.com/docs/en/headless | official | Execucao nao interativa `-p` e output-format |
| mcp-core | https://code.claude.com/docs/en/mcp | official | Configuracao, escopos, auth e troubleshooting |
| agent-sdk | https://docs.claude.com/en/api/agent-sdk/overview | official | Integracao programatica (TypeScript/Python) |
| skills | https://code.claude.com/docs/en/skills | official | Formato `SKILL.md`, frontmatter e ciclo de skills |
| commands | https://code.claude.com/docs/en/slash-commands | official | Slash commands e relacionamento com skills |
| sub-agents | https://code.claude.com/docs/en/sub-agents | official | Subagents, despacho e frontmatter |
| plugins | https://code.claude.com/docs/en/plugins | official | Estrutura, marketplace e governanca de plugin |
| plugins-reference | https://code.claude.com/docs/en/plugins-reference | official | Referencia de componentes e `${CLAUDE_PLUGIN_ROOT}` |
| settings | https://code.claude.com/docs/en/settings | official | Hierarquia, permissions e statusLine |
| hooks | https://code.claude.com/docs/en/hooks | official | Eventos e enforcement deterministico |
| costs | https://code.claude.com/docs/en/costs | official | Custo e operacao headless/background |

## Verificacao Oficial da Rodada

| Tema | URL validada | Evidencia objetiva extraida | Verificado em |
|---|---|---|---|
| CLI reference | https://code.claude.com/docs/en/cli-reference | Flags criticas: `--model`, `--permission-mode`, `--output-format`, `--allowedTools`, `--continue`/`--resume` | 2026-06-10 |
| Headless | https://code.claude.com/docs/en/headless | `claude -p` e formatos `text|json|stream-json` | 2026-06-10 |
| Interactive mode | https://code.claude.com/docs/en/interactive-mode | Plan mode (`shift+tab`), permission modes e atalhos | 2026-06-10 |
| MCP | https://code.claude.com/docs/en/mcp | Escopos (`.mcp.json`/`settings`/`claude mcp add`), transports e `mcp__<server>__<tool>` | 2026-06-10 |
| Agent SDK | https://docs.claude.com/en/api/agent-sdk/overview | Orquestracao programatica (substitui papel do ACP) | 2026-06-10 |
| Memory | https://code.claude.com/docs/en/memory | CLAUDE.md hierarquico, imports `@` e `/memory` | 2026-06-10 |
| Settings | https://code.claude.com/docs/en/settings | Precedencia enterprise > CLI > projeto local > projeto > user e `permissions` | 2026-06-10 |

## Matriz Editorial (Topico -> Secao Canonica)

| Topico | Secao canonica | Arquivo | Cross-reference obrigatoria |
|---|---|---|---|
| Modos, permission modes, CLAUDE.md e seguranca | Fundamentos | `01-fundamentos.md` | `02-cli.md`, `05-operacao.md` |
| Execucao pratica via terminal | CLI | `02-cli.md` | `01-fundamentos.md`, `03-mcp-sdk.md` |
| Integracoes externas, MCP e Agent SDK | MCP/SDK | `03-mcp-sdk.md` | `02-cli.md`, `04-governanca.md` |
| Memoria, skills, subagents, commands, plugins, permissoes e hooks | Governanca | `04-governanca.md` | `03-mcp-sdk.md`, `05-operacao.md` |
| Playbooks, validacao e resposta a falhas | Operacao | `05-operacao.md` | `01-fundamentos.md`, `04-governanca.md` |

## Rastreabilidade por Subsecao

| Arquivo | Subsecao alvo | Fonte oficial | Evidencia aplicada | Data de revisao |
|---|---|---|---|---|
| `01-fundamentos.md` | Modos de operacao e permission modes | https://code.claude.com/docs/en/interactive-mode | Plan mode, `shift+tab` e modos `default/acceptEdits/plan/bypassPermissions` | 2026-06-10 |
| `01-fundamentos.md` | Memoria hierarquica (CLAUDE.md) | https://code.claude.com/docs/en/memory | Niveis enterprise/user/projeto/local, imports `@` e `/memory` | 2026-06-10 |
| `01-fundamentos.md` | Escopo de permissoes seguro | https://code.claude.com/docs/en/settings | `permissions` (allow/deny/ask) e menor privilegio | 2026-06-10 |
| `02-cli.md` | Inicializacao de sessao e modos | https://code.claude.com/docs/en/cli-reference | Fluxo interativo, `-p`, `--continue`/`--resume` | 2026-06-10 |
| `02-cli.md` | Parametros criticos e saida estruturada | https://code.claude.com/docs/en/headless | Flags `--model`/`--permission-mode`/`--output-format`/`--allowedTools` | 2026-06-10 |
| `02-cli.md` | Operacao MCP por CLI | https://code.claude.com/docs/en/mcp | `claude mcp list/get/add/remove` | 2026-06-10 |
| `03-mcp-sdk.md` | Modelo de configuracao MCP | https://code.claude.com/docs/en/mcp | Escopos `.mcp.json`/`settings`/`claude mcp add` e transports | 2026-06-10 |
| `03-mcp-sdk.md` | MCP em plugins e tools `mcp__*` | https://code.claude.com/docs/en/plugins-reference | `${CLAUDE_PLUGIN_ROOT}` e nomeacao `mcp__<server>__<tool>` | 2026-06-10 |
| `03-mcp-sdk.md` | Integracao programatica (Agent SDK) | https://docs.claude.com/en/api/agent-sdk/overview | Substituto do ACP; orquestracao TypeScript/Python | 2026-06-10 |
| `04-governanca.md` | Memoria e precedencia de settings | https://code.claude.com/docs/en/settings | Precedencia enterprise > CLI > projeto local > projeto > user | 2026-06-10 |
| `04-governanca.md` | Skills como workflow reutilizavel | https://code.claude.com/docs/en/skills | Estrutura do `SKILL.md`, frontmatter `paths`/`user-invocable` e invocacao | 2026-06-10 |
| `04-governanca.md` | Commands e relacao com skills | https://code.claude.com/docs/en/slash-commands | `$ARGUMENTS`/`$1` e unificacao com skills | 2026-06-10 |
| `04-governanca.md` | Subagents e despacho | https://code.claude.com/docs/en/sub-agents | Frontmatter `tools`/`permissionMode`/`mcpServers` e `@agent-<nome>` | 2026-06-10 |
| `04-governanca.md` | Plugins e composicao de componentes | https://code.claude.com/docs/en/plugins | Bundle de skills/commands/subagents/MCP/hooks | 2026-06-10 |
| `04-governanca.md` | Hooks e enforcement deterministico | https://code.claude.com/docs/en/hooks | Eventos PreToolUse/PostToolUse/UserPromptSubmit/SessionStart/Stop/PreCompact | 2026-06-10 |
| `05-operacao.md` | Playbook de atualizacao do manual | https://code.claude.com/docs/en/overview | Fluxo padrao e qualidade editorial | 2026-06-10 |
| `05-operacao.md` | Gate de permission modes e permissoes | https://code.claude.com/docs/en/settings | Checklist de verificacao de `permissions` e `/permissions` | 2026-06-10 |
| `05-operacao.md` | Background, headless e routines | https://code.claude.com/docs/en/headless | Headless `-p`, `/schedule`, `/loop` e background tasks | 2026-06-10 |

## Trilhas de Pesquisa (US-06 / TF-R-*)

| Tarefa | Tema de pesquisa | Resultado principal |
|---|---|---|
| `TF-R-01` | Modos, permission modes, memoria e seguranca | Definido baseline de uso por modo + limites de permissoes |
| `TF-R-02` | CLI pratica (sessoes, output, headless, resume) | Padronizado bloco de comandos operacionais e diagnostico |
| `TF-R-03` | MCP/Agent SDK (setup, escopos, auth, CLI) | Consolidado troubleshooting minimo e postura de credenciais |
| `TF-R-04` | Governanca (CLAUDE.md, skills, commands, subagents, plugins, hooks) | Clarificada precedencia e criterios de uso por artefato |
| `TF-R-05` | Operacao e controles de qualidade | Definido gate de consistencia e politica de falhas |

## Cobertura Atual

- Todos os capitulos (`01..05`) possuem fontes oficiais rastreaveis por subsecao.
- Todas as trilhas de pesquisa possuem URL oficial e evidencia aplicada.
- Regra editorial: qualquer secao nova deve incluir entrada nesta matriz antes de ser considerada pronta.

## Lacunas e Proximos Topicos

| Modulo | Lacuna identificada | Sugestao de proximo topico | Prioridade sugerida |
|---|---|---|---|
| `01-fundamentos.md` | Falta rotina de alinhamento para tarefas multi-repo | Checklist de scoping com `--add-dir` multi-diretorio | Media |
| `02-cli.md` | Falta padrao para saidas `stream-json` em scripts | Guia de parsing resiliente para automacao | Alta |
| `03-mcp-sdk.md` | Falta quadro de erros por transporte (stdio vs http/sse) | Matriz de troubleshooting por tipo de servidor | Alta |
| `04-governanca.md` | Falta fluxo de governanca para mudanca de precedencia de settings | Runbook de conflitos enterprise/projeto/user | Media |
| `05-operacao.md` | Falta playbook de "rollback documental" robusto | Procedimento de reversao segura com evidencias | Media |
