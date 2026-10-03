# 03 - MCP e Agent SDK

## Escopo

Guia de configuracao e operacao para MCP (Model Context Protocol) no Claude Code, cobrindo configuracao, escopos, autenticacao e erros comuns. Cobre tambem integracao programatica via **Claude Agent SDK**.

> Nota de portabilidade: o **ACP nao existe no Claude Code**. O protocolo de ferramentas e o **MCP**; para embutir/automatizar o agente em outro software, o mecanismo equivalente mais proximo e o **Claude Agent SDK** (TypeScript/Python).

## Quando Usar

- Integrar o agente a ferramentas externas (GitHub, observabilidade, backlog, etc.).
- Diagnosticar ferramentas MCP indisponiveis, sem auth ou sem tools.
- Operar MCP por CLI (`claude mcp ...`) em fluxos repetiveis.
- Construir integracoes programaticas/agentes embutidos via Agent SDK.

## Conceitos Essenciais

- **MCP (Model Context Protocol):** integra o agente a ferramentas externas. Tools expostas aparecem como `mcp__<server>__<tool>`.
- **Claude Agent SDK:** biblioteca (TypeScript/Python) para orquestrar o agente programaticamente; substitui conceitualmente o papel de "camada de capacidades" que o ACP teria no Cursor.
- **`.mcp.json`:** arquivo de configuracao dos servidores MCP (escopo projeto/plugin). Tambem configuravel em `~/.claude/settings.json` (chave `mcpServers`) ou via `claude mcp add`.

## Pre-requisitos

1. Escolher escopo de configuracao:
   - projeto: `.mcp.json` na raiz do projeto;
   - usuario: `~/.claude/settings.json` (chave `mcpServers`);
   - local: via `claude mcp add` (registra no escopo selecionado);
   - plugin: `.mcp.json` do plugin, usando `${CLAUDE_PLUGIN_ROOT}`.
2. Definir transporte: `stdio` (command+args+env), `http` (url+headers) ou `sse`.
3. Definir estrategia de segredo (env/headers) sem versionar credenciais.

## Configuracao Basica

1. Definir servidor em `.mcp.json` (projeto/plugin) ou `~/.claude/settings.json` (`mcpServers`), ou usar `claude mcp add`.
2. Declarar `command`/`args` para servidores `stdio` (local) ou `url` para `http`/`sse` (remoto).
3. Incluir variaveis/headers de autenticacao quando exigido.

### Exemplo de configuracao local (stdio)

```json
{
  "mcpServers": {
    "my-local-server": {
      "command": "npx",
      "args": ["-y", "my-mcp-server"],
      "env": {
        "API_KEY": "${API_KEY}"
      }
    }
  }
}
```

### Exemplo de configuracao remota (HTTP/SSE)

```json
{
  "mcpServers": {
    "my-remote-server": {
      "type": "http",
      "url": "https://mcp.example.com/mcp",
      "headers": {
        "Authorization": "Bearer ${TOKEN}"
      }
    }
  }
}
```

### Exemplo em plugin

```json
{
  "mcpServers": {
    "plugin-server": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/mcp/server.js"]
    }
  }
}
```

### Seguranca de Credenciais (obrigatorio)

- Nunca commitar tokens, API keys ou headers de autenticacao em `.mcp.json` versionado.
- Preferir variaveis de ambiente (`env`) e armazenamento seguro aprovado pelo time.
- Revisar diff e historico local antes de concluir mudancas de configuracao.

## Autenticacao

- Preferir autenticacao suportada oficialmente para cada servidor (OAuth quando disponivel para `http`/`sse`).
- Armazenar segredos fora do codigo-fonte; usar `env` no `stdio` e `headers` no `http`.
- Seguir principio do menor privilegio para tokens e chaves.
- Em caso de dados pessoais, validar aderencia a politica interna e acionar DPO/juridico quando aplicavel.

### Checklist de Auth MCP

- [ ] Confirmar se servidor usa OAuth, token estatico ou credencial via `env`.
- [ ] Restringir escopo do token ao conjunto minimo de tools necessario.
- [ ] Evitar armazenar segredo em arquivo versionado.
- [ ] Registrar no troubleshooting qual metodo de auth foi aplicado.

## Operacao via CLI

1. `claude mcp list` para status dos servidores.
2. `claude mcp get <server>` para conhecer a configuracao do servidor.
3. `claude mcp add <server> ...` para registrar um servidor (transports `--transport stdio|http|sse`).
4. `claude mcp remove <server>` para controle operacional.

## Escopos de Configuracao (ponto critico)

- **User (`~/.claude/settings.json`):** disponivel em todos os projetos do utilizador.
- **Project (`.mcp.json`):** compartilhado e versionado com o time — nunca colocar segredos diretos aqui.
- **Local:** preferencias da maquina, fora do versionamento.
- Tools de qualquer servidor sao referenciaveis como `mcp__<server>__<tool>` em `allowedTools`/`permissions`.

### Comparativo de Transporte

| Transporte | Quando usar | Risco principal | Mitigacao |
|---|---|---|---|
| `stdio` | Servidor local com processo controlado | Dependencia de ambiente e segredos locais | Isolar `env` e validar logs sem expor credenciais |
| `http`/`sse` | Servidor remoto gerenciado | Falha de rede/auth em runtime | Healthcheck, retry e header seguro |

## Integracao Programatica (Claude Agent SDK)

Quando o objetivo for embutir o agente em outro software (e nao apenas usar a CLI), o caminho oficial e o **Claude Agent SDK**:

- Disponivel em **TypeScript** e **Python**.
- Permite orquestrar prompts, ferramentas (incluindo MCP) e permissoes de forma programatica.
- E o substituto conceitual do que seria a "camada ACP" — no Claude Code nao ha ACP; integracao de capacidades e feita via MCP (ferramentas) + Agent SDK (orquestracao).

## Troubleshooting Comum

| Sintoma | Causa Provavel | Acao Recomendada |
|---|---|---|
| Ferramenta MCP indisponivel | Servidor nao iniciou ou auth invalida | Revisar `.mcp.json`/`settings.json`, credenciais e logs de inicializacao (saida do processo MCP/CLI) |
| Lista de tools vazia | Escopo/permissoes insuficientes | Validar credenciais e configuracao do servidor |
| Erros intermitentes de conexao | Endpoint remoto instavel | Repetir teste, validar rede e timeout do servidor |
| Config nao aparece entre escopos | Definida em escopo diferente (user/project/local) | Padronizar escopo e revalidar com `claude mcp list`/`claude mcp get` |
| Tool MCP bloqueada por permissao | `mcp__<server>__<tool>` fora de `allow` | Ajustar `permissions`/`--allowedTools` para o tool especifico |

## Anti-padroes

- Misturar no mesmo arquivo credenciais reais e placeholders sem criterio.
- Versionar segredos em `.mcp.json` de projeto.
- Usar token com privilegios excessivos quando uma permissao minima resolve.
- Tentar debugar MCP sem capturar erro, servidor, tentativa e resultado.

### Sinal Minimo para Diagnostico MCP

Antes de alterar novamente a configuracao, capturar:

1. erro objetivo observado;
2. servidor MCP afetado;
3. trecho relevante da saida de inicializacao (sem segredos);
4. tentativa de correcao ja aplicada.

## Checklist Rapido

- [ ] Configuracao MCP definida no escopo correto (user/project/local/plugin).
- [ ] Segredos fora de git (via `env`/`headers`) e com menor privilegio.
- [ ] Servidor autenticado e tools listadas (`claude mcp list`).
- [ ] Evidencias de troubleshooting registradas sem dados sensiveis.
- [ ] Para remoto, escolha de transporte (`http`/`sse` vs `stdio`) justificada.

## Cross-links

- Operacao por terminal e modos: [02-cli.md](./02-cli.md)
- Padroes de conduta e consistencia: [04-governanca.md](./04-governanca.md)

## Fontes Oficiais

- https://code.claude.com/docs/en/mcp
- https://code.claude.com/docs/en/settings
- https://code.claude.com/docs/en/plugins-reference
- https://docs.claude.com/en/api/agent-sdk/overview
