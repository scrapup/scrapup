# 02 - CLI

## Escopo

Guia operacional de uso da CLI `claude` para execucoes interativas e nao interativas (headless).

## Quando Usar

- Executar tarefas direto no terminal sem abrir fluxo completo na UI.
- Automatizar analises/reviews em pipelines locais com `-p` (print/headless).
- Retomar sessoes anteriores com contexto persistido.

## Comandos Principais

- `claude` inicia sessao interativa.
- `claude "<prompt>"` inicia sessao com objetivo inicial.
- `claude -p "<prompt>"` executa modo nao interativo (print/headless).
- `claude --continue` retoma a sessao mais recente.
- `claude --resume` retoma uma sessao anterior selecionavel.
- `claude --agent <nome>` inicia com um subagent especifico.

## Pre-requisitos

1. CLI instalada e autenticada.
2. Diretorio de trabalho correto; usar `--add-dir` para incluir pastas adicionais.
3. Permission mode compativel com o objetivo (`--permission-mode`).

## Parametros Criticos

- `--model opus|sonnet|haiku|fable` para definir modelo de execucao.
- `--permission-mode default|acceptEdits|plan|bypassPermissions` para controlar permissoes.
- `--allowedTools` / `--disallowedTools` para restringir o conjunto de ferramentas.
- `--add-dir` para expandir o escopo de diretorios.
- `--output-format text|json|stream-json` para padronizar saida em automacoes.
- `--continue` / `--resume` para continuidade de contexto.

### Matriz de Parametros por Objetivo

| Objetivo | Parametros recomendados | Observacao |
|---|---|---|
| Execucao scriptavel | `-p`, `--output-format json` | Facilita parsing e auditoria |
| Exploracao segura | `--permission-mode plan` ou `--allowedTools` restrito | Sem alteracoes locais |
| Planejamento guiado | `--permission-mode plan` | Ativa Plan mode antes de codar |
| Retomar contexto | `--continue` / `--resume` | Continua execucao com contexto da sessao |

## Limites Operacionais

- Em modo de leitura/Plan mode, nao executar alteracoes locais.
- Evitar comandos destrutivos sem autorizacao explicita.
- Validar diretorio de trabalho (e `--add-dir`) antes de rodar comandos de larga escala.

## Passo a Passo Operacional

1. Diagnostico inicial:
   - `claude --resume` (se precisar retomar contexto)
   - `claude mcp list` (se for usar MCP)
2. Escolher modo:
   - exploracao/plan: `claude --permission-mode plan`
   - execucao: `claude` ou `claude --permission-mode acceptEdits`
3. Para automacao local:
   - `claude -p "<prompt>" --output-format json`
4. Para MCP na CLI:
   - `claude mcp list`
   - `claude mcp get <server>`
5. Consolidar saida e registrar evidencias.

## Exemplos Praticos

### Exemplo A - Revisao nao interativa em JSON

```bash
claude -p "review these markdown changes for gaps" --output-format json
```

### Exemplo B - Sessao de planejamento

```bash
claude --permission-mode plan "propor backlog para detalhar manual de operacao"
```

### Exemplo C - Operar MCP pela CLI

```bash
claude mcp list
claude mcp get github
claude mcp add github --transport http --url https://api.githubcopilot.com/mcp
```

### Exemplo D - Execucao headless com stream-json

```bash
claude -p "listar riscos de deploy no repositorio atual" \
  --output-format stream-json
```

### Exemplo E - Retomar sessao para tarefa longa

```bash
claude --continue "executar auditoria documental e devolver checklist de gaps"
```

### Exemplo F - Despacho de subagent

```bash
claude --agent reviewer-claude "revisar consistencia do manual"
```

## Checklist Rapido de CLI

1. Confirmar permission mode (`default`/`acceptEdits`/`plan`/`bypassPermissions`) antes de iniciar.
2. Definir prompt com objetivo e escopo claro.
3. Revisar resultado e registrar evidencias quando aplicavel.
4. Se houver MCP, validar status do servidor (`claude mcp list`) antes do prompt principal.

## Anti-padroes

- Usar `--permission-mode bypassPermissions` como padrao sem necessidade real.
- Rodar `-p` com prompts ambiguos em automacoes.
- Ignorar `--add-dir` quando arquivos relevantes estao fora do diretorio atual.
- Liberar `--allowedTools` amplo sem validar previamente o conjunto necessario.

## Troubleshooting

| Sintoma | Causa Provavel | Acao |
|---|---|---|
| `claude` nao encontra contexto esperado | Diretorio errado / falta `--add-dir` | Incluir pasta com `--add-dir` ou iniciar na raiz correta |
| Comando bloqueado | Permission mode restritivo | Ajustar `--permission-mode` com criterio e usar `/permissions` |
| Saida dificil de parsear em script | Formato padrao texto | Usar `--output-format json` ou `stream-json` |
| MCP nao aparece no fluxo | Servidor desabilitado/auth pendente | `claude mcp list` + reautenticar/reconfigurar `.mcp.json` |

## Cross-links

- Conceitos basicos e seguranca: [01-fundamentos.md](./01-fundamentos.md)
- Integracoes externas e autenticacao: [03-mcp-sdk.md](./03-mcp-sdk.md)

## Fontes Oficiais

- https://code.claude.com/docs/en/cli-reference
- https://code.claude.com/docs/en/headless
- https://code.claude.com/docs/en/interactive-mode
- https://code.claude.com/docs/en/mcp
