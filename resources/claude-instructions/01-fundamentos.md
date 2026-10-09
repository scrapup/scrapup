# 01 - Fundamentos

## Escopo

Este capitulo estabelece a base para operar o Claude Code com consistencia no contexto Scrapforge: modos de execucao, permission modes, memoria hierarquica (CLAUDE.md), guardrails e fluxo minimo recomendado.

## Quando Usar

- Inicio de sessao para definir abordagem (exploracao read-only, Plan mode, execucao).
- Mudanca de tipo de tarefa (analise -> implementacao, implementacao -> revisao).
- Definicao de guardrails antes de usar shell, MCP ou permissoes amplas.

## Modos de Operacao

O Claude Code distingue **modo de operacao** (interativo x headless) de **permission mode** (quanto o agente pode alterar sem confirmacao).

- **Sessao interativa normal:** execucao com edicao de arquivos, comandos e validacoes, sujeita ao permission mode ativo.
- **Plan mode:** o agente planeja sem editar nada; entra/sai via `EnterPlanMode`/`ExitPlanMode`. A tecla `shift+tab` cicla entre os modos durante a sessao.
- **Exploracao read-only:** equivale ao antigo "ask" (apenas leitura/analise) — obtido limitando ferramentas ou permanecendo em Plan mode.
- **Headless/nao-interativo:** `claude -p "<prompt>"` para automacao e pipelines.

### Permission Modes

- **`default`:** pede confirmacao para acoes com efeito colateral.
- **`acceptEdits`:** aceita edicoes de arquivo automaticamente, ainda pedindo para comandos sensiveis.
- **`plan`:** equivalente ao Plan mode (planeja sem alterar workspace).
- **`bypassPermissions`:** executa sem prompts; usar somente com criterio explicito de risco.

> Mapeamento do antigo fluxo Cursor (`ask`/`plan`/`agent`): "ask/leitura" ≈ exploracao read-only ou Plan mode; "plan" ≈ Plan mode (`plan`); "agent" ≈ sessao interativa normal com `default`/`acceptEdits`.

## Pre-requisitos

1. Escopo da tarefa claro (o que deve ser alterado e o que nao deve).
2. Memoria/contexto carregado (`CLAUDE.md` hierarquico, skills relevantes).
3. Confirmacao de risco para comandos com efeito colateral.

## Memoria Hierarquica (CLAUDE.md)

O Claude Code carrega memoria persistente a partir de `CLAUDE.md` em precedencia hierarquica:

- **Enterprise:** politica gerida pela organizacao (maior precedencia).
- **User:** `~/.claude/CLAUDE.md` (preferencias do utilizador).
- **Projeto compartilhado:** `./CLAUDE.md` ou `.claude/CLAUDE.md`.
- **Projeto local:** `CLAUDE.local.md` (gitignored).

Recursos uteis:

- Imports com `@caminho` para compor memoria a partir de outros arquivos.
- Comando `/memory` para editar a memoria ativa.
- Regras com escopo de arquivo (antigos globs) -> **skills** com frontmatter `paths:` e `user-invocable: false`.

## Permissoes e Seguranca Operacional

1. Tratar dados externos com abordagem zero trust.
2. Evitar inferencias sem evidencia documental.
3. Privilegiar fontes oficiais para decisoes de processo.
4. Registrar desvios operacionais somente com decisao explicita em artefato de governanca (ticket/note).
5. Quando houver dados pessoais no contexto, validar base legal e politica interna antes de prosseguir.

## Passo a Passo Base (antes de executar)

1. Definir modo inicial:
   - exploracao read-only para levantamento e leitura;
   - Plan mode (`plan`) para estrategia e plano de execucao;
   - sessao normal (`default`/`acceptEdits`) apenas quando houver aprovacao para implementar.
2. Declarar fonte de verdade (arquivos, spec, plan, task, CLAUDE.md).
3. Validar dependencias externas (MCP, credenciais, rede) sem expor segredos.
4. Executar em lotes pequenos com validacao continua.
5. Consolidar evidencias antes de marcar conclusao.

### Decisao Rapida de Modo

| Cenario | Modo recomendado | Motivo |
|---|---|---|
| Entender contexto, sem editar nada | Exploracao read-only / Plan mode | Menor risco e foco em leitura |
| Definir abordagem com trade-offs | Plan mode (`plan`) | Permite alinhar estrategia antes de executar |
| Implementar mudanca aprovada | Sessao normal (`default`/`acceptEdits`) | Habilita edicao, shell e verificacoes |

### Guardrails de Fonte de Verdade

1. Priorizar artefatos estruturados (`spec.md`, `plan.md`, `tasks.md`) e `CLAUDE.md` quando existirem.
2. Em caso de conflito entre instrucoes, aplicar precedencia documentada em `04-governanca.md`.
3. Nao concluir tarefa sem evidencia observavel (arquivo alterado, checklist ou log de validacao).

## Exemplos Praticos

### Exemplo A - Ajuste simples em documentacao

- Comecar em exploracao read-only para mapear arquivos.
- Mudar para sessao normal (`acceptEdits`) apenas para editar o alvo.
- Validar links e rastreabilidade no final.

### Exemplo B - Mudanca com ambiguidade de escopo

- Entrar em Plan mode (`shift+tab` ate `plan`) para explicitar trade-offs.
- Confirmar direcao com o utilizador (`ExitPlanMode`).
- Migrar para sessao normal apos plano aprovado.

### Exemplo C - Alteracao com risco de seguranca operacional

- Iniciar em exploracao read-only para mapear risco e permissao necessaria.
- Validar `permissions` em `settings.json` (allow/deny/ask) antes de executar comando sensivel.
- Somente apos validacao explicita, prosseguir com `default`; reservar `bypassPermissions` para casos justificados.

## Fluxo Base Recomendado

1. Confirmar escopo da tarefa e artefatos aplicaveis.
2. Validar pre-requisitos locais (ambiente, CLAUDE.md e contexto).
3. Executar mudancas incrementalmente, com verificacao continua.
4. Consolidar evidencias de qualidade e consistencia antes de concluir.

## Anti-padroes

- Pular validacao de consistencia entre arquivos relacionados.
- Fechar tarefa sem registrar fontes usadas.
- Misturar instrucoes locais com referencias nao oficiais.
- Entrar direto em execucao (`default`/`acceptEdits`) sem esclarecer o escopo.
- Usar `bypassPermissions` como padrao sem allowlist minima e criterio de risco.

## Checklist Rapido

- [ ] O modo atual (read-only/Plan mode/execucao) e o permission mode estao coerentes com o tipo de tarefa.
- [ ] CLAUDE.md e skills aplicaveis foram considerados.
- [ ] Nao ha comandos destrutivos sem autorizacao explicita.
- [ ] Fontes oficiais estao mapeadas para as secoes alteradas.
- [ ] Evidencias de validacao foram registradas.

## Troubleshooting

| Sintoma | Causa Provavel | Acao |
|---|---|---|
| Escopo muda toda hora | Modo inadequado para momento atual | Voltar para Plan mode, consolidar escopo e retomar execucao |
| Acoes bloqueadas por permissao | Permission mode/`permissions` restritivo | Revisar `permissions` em `settings.json` e usar `/permissions`; pedir aprovacao explicita |
| Saida inconsistente entre sessoes | Contexto incompleto ou memoria conflitante | Revalidar CLAUDE.md ativo (`/memory`) e fonte canonica do trabalho |

## Cross-links

- Proximo passo operacional: [02-cli.md](./02-cli.md)
- Execucao e troubleshooting: [05-operacao.md](./05-operacao.md)

## Fontes Oficiais

- https://code.claude.com/docs/en/overview
- https://code.claude.com/docs/en/interactive-mode
- https://code.claude.com/docs/en/memory
- https://code.claude.com/docs/en/settings
