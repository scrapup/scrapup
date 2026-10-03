# Manual de Instruções do Claude Code

Manual operacional consolidado para uso do Claude Code no ecossistema Scrapforge.

## Objetivo

- Centralizar orientacoes praticas de operacao.
- Manter rastreabilidade explicita para documentacao oficial.
- Reduzir ambiguidade em fluxos recorrentes.

## Estrutura do Manual

1. [Fundamentos](./01-fundamentos.md)
2. [CLI](./02-cli.md)
3. [MCP e Agent SDK](./03-mcp-sdk.md)
4. [Governanca](./04-governanca.md)
5. [Operacao](./05-operacao.md)
6. [Referencias Oficiais](./references.md)

## Como Usar

1. Comece por `01-fundamentos.md` para alinhar conceitos, modos de operacao e CLAUDE.md.
2. Siga para o capitulo especifico do seu objetivo (CLI, MCP/Agent SDK, governanca ou operacao).
3. Valide a origem das orientacoes em `references.md` antes de aplicar mudancas sensiveis.

## Fluxo de Contribuicao (Pesquisa + Implementacao)

Use este fluxo para evoluir o manual sem perder rastreabilidade:

1. **Pesquisa tematica (TF-R-*)**
   - Levantar apenas fontes oficiais por tema.
   - Mapear lacunas por modulo.
   - Registrar backlog incremental no `saga-session`.
2. **Implementacao no modulo (TF-I-*)**
   - Atualizar capitulo alvo com secoes operacionais padrao:
     - `Quando usar`
     - `Pre-requisitos`
     - `Passo a passo`
     - `Exemplos praticos`
     - `Anti-padroes`
     - `Checklist`
     - `Troubleshooting`
     - `Links oficiais`
3. **Rastreabilidade**
   - Atualizar `references.md` por **subsecao** alterada.
4. **Evidencia**
   - Registrar execucao em `docs/specs/claude-best-practices/evidencias-execucao-local.md`.

### Sequencia Recomendada por Modulo

1. Executar `TF-R-*` do modulo (pesquisa oficial e lacunas).
2. Executar `TF-I-*` do mesmo modulo (conteudo operacional).
3. Atualizar `references.md` por subsecao alterada.
4. Registrar note no `saga-session` com lacunas e proximos topicos.

### Template Minimo de Contribuicao

Use este formato para cada rodada:

- **Modulo:** `01..05`
- **TF-R executada:** tema pesquisado + links oficiais
- **TF-I executada:** secoes alteradas + exemplos adicionados
- **Rastreabilidade:** entradas novas em `references.md`
- **Backlog incremental:** lacunas + prioridade sugerida

## Regras de Curadoria

- Usar apenas fontes oficiais do Claude Code.
- Nao duplicar regras entre capitulos; preferir secao canonica + cross-link.
- Atualizar `references.md` sempre que um capitulo receber novo conteudo.
- Cada tarefa deve gerar backlog incremental no `saga-session` para temas futuros.

## Revisao

- Ultima revisao: 2026-06-10
- Responsavel editorial: Scrapforge
