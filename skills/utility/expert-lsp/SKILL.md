---
name: expert-lsp
description: "Skill canonica de regras de integracao para navegacao e edicao semantica de codigo via LSP em projetos JavaScript/TypeScript. Use quando precisar localizar simbolos, encontrar referencias/quem chama, mapear impacto preciso (quais testes rodar), editar em nivel de simbolo (replace/insert/rename), obter diagnosticos do language server, ou substituir grep/leitura de arquivo inteiro por analise semantica. O catalogo de tools e o binding do MCP vivem no command /scrapup:serena (server mcp-serena). Consumida por scrapup-forge, test-driven-agentic-development e multi-spec-review."
user-invocable: true
metadata:
  obsidian_identifier: scrapup:expert-lsp
---

# Expert LSP — Regras de Navegação e Edição Semântica de Código

## Camadas (separação de responsabilidade)

| Camada | Artefato | Responsabilidade |
|--------|----------|------------------|
| MCP | `mcp-serena` (`.mcp.json`) | Define o server |
| Command | `/scrapup:serena` (`commands/serena.md`) | Padroniza o MCP e o **catálogo de tools** (`mcp__plugin_scrapup_mcp-serena__*`) |
| **Expert (esta skill)** | `expert-lsp` | **Regras de integração:** quando usar, JS/TS, fluxo, integração com o ecossistema, fallback, anti-padrões |

A skill é nomeada pelo **protocolo (LSP)**, não pelo produto: se o backend mudar, troca-se o
command/MCP (`serena`) e estas regras sobrevivem. O catálogo concreto de tools **não** é duplicado
aqui — vive no command `/scrapup:serena`.

## Objetivo

Ser a **fonte única de regras** para análise semântica de código (símbolos, referências, call
hierarchy, diagnósticos) e edição em nível de símbolo via language server, em vez de `grep`/leitura
de arquivo inteiro. Foco primário: **JavaScript e TypeScript**.

## Quando usar (gatilho canônico)

Acionar **antes** de recorrer a `grep`/`rg` ou leitura de arquivo inteiro sempre que a tarefa
envolva entender ou alterar código JS/TS:

- Localizar definição/declaração de função, classe, método, tipo.
- Descobrir **quem usa/chama** um símbolo — impacto, refactor seguro.
- Encontrar implementações de uma interface/abstração.
- Ler só o **esqueleto** de um arquivo antes de mergulhar.
- Editar em nível de símbolo sem reescrever o arquivo (replace/insert/rename).
- Obter diagnósticos do language server num arquivo.

Não usar para: arquivos não-código (markdown, JSON de config), repositórios sem language server
suportado, ou quando uma busca textual literal já basta.

## Pré-condição obrigatória: projeto ativo

Operações semânticas exigem um **projeto ativo** no server. Garantir antes de qualquer tool:

1. Com `--project-from-cwd`, o server auto-detecta pelo `.git`/`.serena/project.yml` do cwd.
2. Se nenhum projeto estiver ativo ou for o errado, ativar pelo path/nome do repo (ativação de projeto).
3. Em repo novo ao backend, o primeiro acesso indexa via language server (latência inicial); operações seguintes são rápidas.
4. Confirmar estado de projeto/linguagem ativos em caso de dúvida (inspeção de configuração).

> Os nomes de tool citados nesta skill são **ilustrativos** (referenciados por papel funcional). O catálogo completo de tools e os **nomes exatos** vivem no command `/scrapup:serena` — fonte canônica de invocação.

## Receitas canônicas (JS/TS)

Procedimentos reutilizáveis que outras skills **referenciam** em vez de reimplementar. Tools via command `/scrapup:serena`.

### R1 — Localizar / entender código (navegar por símbolos)

1. `get_symbols_overview` no arquivo → esqueleto (símbolos top-level), sem ler o arquivo inteiro.
2. `find_symbol` pelo nome/name-path → ir ao símbolo-alvo.
3. `find_declaration` → definição (go-to-definition) quando o ponto de partida é um uso.
4. `find_implementations` → quando o alvo é interface/abstração e você precisa das implementações concretas.

### R2 — Descobrir referências / análise de impacto (quem usa)

Para cada **símbolo público alterado** (função, classe, método, tipo exportado):

1. `find_referencing_symbols` no símbolo → referenciadores reais (resolve re-exports/barrel files, ignora homônimos).
2. Encadear `find_referencing_symbols` nos referenciadores para capturar os **transitivos**. Critério de parada: encadear até **não surgirem novos referenciadores fora dos já visitados**, com teto de **3 hops**.
3. Filtrar os arquivos referenciadores por globs de teste do projeto (`*.spec.ts`, `*.e2e-spec.ts`, `*.test.js`, …) quando o objetivo for o conjunto de testes impactados.

**Saída:** lista de **paths de arquivo de teste impactados**, deduplicada (cada path uma única vez, mesmo alcançado por múltiplos caminhos).

Vantagem sobre `rg`/grep por nome: elimina falsos positivos (homônimos) e falsos negativos (re-exports/barrel → transitivos perdidos).

### R3 — Editar em nível de símbolo

1. `replace_symbol_body` → substituir o corpo de um símbolo sem reescrever o arquivo.
2. `insert_after_symbol` / `insert_before_symbol` → inserir relativo à definição.
3. `rename_symbol` → renomear em todo o codebase (refactoring do language server), nunca find-and-replace textual.

### R4 — Diagnóstico pós-edição

`get_diagnostics_for_file` no arquivo alterado → erros/warnings do language server (ex.: quebra de tipo) imediatamente após a mudança.

## Integração com o ecossistema

- **/scrapup:test-driven-agentic-development (IMPACT):** aplicar a **receita R2** como Método 0
  da descoberta de testes; **R1** no IMPLEMENT (localizar causa-raiz) e **R4** após editar. O TDAD
  decide a política (quando rodar, mapeamento de prioridade, fallback para `rg`/convenção); o **como**
  é desta skill.
- **/scrapup:scrapup-forge:** **R1** para carregar só o símbolo relevante ao validar
  tipos/interfaces e resolver placeholders; **R3** (`replace_symbol_body`) na resolução de conflitos
  de merge.
- **/scrapup:multi-spec-review:** a integração é **no pré-pack** (scripts `msr-*.sh`), não no
  prompt dos reviewers — eles permanecem sem exploração (RN-11). Grafo/refs pré-computados podem
  ser injetados no pack de forma determinística.
- **/scrapup:brainstorming:** **insumo de exploração opcional** no passo "Explore project
  context" de brainstorm brownfield JS/TS — **R1** (forma do símbolo-alvo) e **R2** (dependentes /
  blast radius) para fundamentar as 2-3 abordagens. Não é etapa obrigatória nem meio de execução;
  greenfield/conceitual dispensa o LSP e a indisponibilidade do MCP não bloqueia o brainstorm.
- **/scrapup:mimic-loop:** subagents despachados herdam o uso semântico via TDAD/forge.

## Indisponibilidade do MCP e fallback

Distinguir **dois casos** — o tratamento é diferente:

**Caso A — fallback automático (sem perguntar):** a linguagem não é suportada pelo language server,
ou o repo legitimamente não tem servidor aplicável. Aqui o LSP não se aplica. Declarar e cair para
`rg`/`Read`.

**Caso B — MCP `mcp-serena` não responsivo (deveria funcionar):** erro de conexão, timeout, server
caído, ou o projeto não ativa num repo JS/TS onde o LSP deveria operar. **Não seguir silenciosamente
sem o MCP.** Antes de qualquer fallback:

1. Reportar o sintoma factual (qual tool, qual erro).
2. **Perguntar ao utilizador** qual ação tomar, oferecendo opções:
   - tentar reconectar/reiniciar o `mcp-serena` (ex.: `/reload-plugins` ou reativar o projeto);
   - prosseguir nesta tarefa com fallback `rg`/`Read` (degradação aceita, com a perda de precisão declarada);
   - abortar a tarefa.
3. Só prosseguir **após a resposta**. A escolha vale para a tarefa corrente; reavaliar se o sintoma reaparecer.

Nunca tratar o Caso B como Caso A: cair para `rg` por conta própria quando o MCP só está
temporariamente indisponível esconde uma falha de ambiente e degrada a precisão sem o utilizador saber.

## Regras obrigatórias

1. Ativar o projeto correto antes de qualquer tool semântica.
2. Preferir tools semânticas a `grep`/leitura integral quando o alvo é um símbolo em JS/TS.
3. Refactor de nome via `rename_symbol`, não find-and-replace textual.
4. Edição via `replace_symbol_body`/`insert_*` em vez de reescrever o arquivo.
5. Fallback conforme a secção "Indisponibilidade do MCP e fallback": Caso A automático; **Caso B exige
   consultar o utilizador antes de seguir sem o MCP**. Nunca falhar — nem degradar — silenciosamente.
6. Não usar `execute_shell_command` do Serena para rodar testes/build; isso pertence ao gate da
   /scrapup:baseline-assessment e às tools nativas.

## Anti-padrões

- Rodar `rg "import.*Service"` para impacto quando `find_referencing_symbols` está disponível.
- Ler arquivo inteiro só para localizar uma função (`get_symbols_overview` + `find_symbol` bastam).
- Editar via string-match frágil onde `replace_symbol_body` faz a edição cirúrgica.
- Operar tools semânticas sem projeto ativo (resultados vazios/errados).
