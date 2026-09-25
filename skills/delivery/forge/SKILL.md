---
name: scrapup-forge
description: Use quando o utilizador pedir para executar tarefa, execute task, implementar historia, executar US, executar TF, rodar tarefa SDD, implementar task do backlog, ou qualquer solicitacao de implementacao de codigo com ou sem artefatos SDD
metadata:
  obsidian_identifier: scrapup:scrapup-forge
---

# Execute Task

Execute tarefas (TF-XX-YY) e user stories (US-XX) cobrindo o ciclo completo: pre-requisitos de ambiente, leitura de artefatos, setup de branch, implementacao com TDAD via subagents, commit autonomo, validacao, self-review, PR Draft, monitoramento de CI e abertura da PR. Dirija perguntas e pedidos de confirmacao ao **utilizador** — a pessoa que solicitou a execucao no Claude Code; para a definicao completa desse papel, ver a skill /scrapup:perfil-utilizador.

Trate **este SKILL.md como a fonte canonica do fluxo**. As secoes **0 a 10** mapeiam as particoes homonimas do diagrama [`scrapup-forge-flow.puml`](scrapup-forge-flow.puml) (e [`scrapup-forge-flow.png`](scrapup-forge-flow.png) derivado). Em caso de divergencia, o SKILL.md prevalece.

> **Manutencao do diagrama:** o `.puml`/`.png` sao derivados do SKILL.md. Apos alterar este fluxo, regenere o diagrama a partir do SKILL.md (o utilizador inspeciona o `.png`, propoe mudancas, estas sao aplicadas aqui e so entao o `.puml`/`.png` sao regenerados) — ver skill /scrapup:regra-scrapup-doc-sync.

## Idioma

Todo o output desta skill — relatorios de progresso, status ao utilizador, sumarios de execucao e comunicacao — deve ser redigido em **Portugues do Brasil (PT-BR)**. Termos tecnicos consagrados em ingles (endpoint, deploy, commit, merge, branch, pipeline, build, cache, middleware, DTO, hook, draft, thread, sprint, backlog) devem ser mantidos na forma original.

<EXTREMELY-IMPORTANT>
Se uma skill referenciada neste documento se aplica ao que voce esta fazendo, voce DEVE ler e seguir a skill.

SE UMA SKILL SE APLICA, VOCE NAO TEM ESCOLHA. DEVE USA-LA.

Cada secao deste documento (0 a 10 + Verificacao Final) e inegociavel. Executar ou escalar ao utilizador. Marcar como completa sem executar e violacao.

Isto nao e negociavel. Nao e opcional. Voce nao pode racionalizar para escapar disto.

### Padroes de racionalizacao conhecidos

Se algum destes pensamentos ocorrer, PARE — voce esta racionalizando:

| Pensamento | Realidade |
|---|---|
| "O escopo e pequeno, nao precisa de self-review" | multi-spec-review e mandatorio independente do escopo. Escopo pequeno = execucao rapida, nao skip |
| "CI local passou, nao preciso verificar remoto" | pre-push hook NAO substitui checks do GitHub (Sonar, Actions). Secao 10 exige polling remoto |
| "O bot ja revisou, nao preciso do multi-spec-review" | Review de bot nao substitui as 9 specs. Sao perspectivas complementares, nao intercambiaveis |
| "Ja fiz verificacoes inline durante implementacao" | Verificacoes inline nao substituem o multi-spec-review formal da secao 8 |
| "Vou pular esta secao e voltar depois" | Nao existe "voltar depois". Cada secao e gate para a proxima |
</EXTREMELY-IMPORTANT>

## Skills Referenciadas

Ler e seguir **obrigatoriamente** quando o contexto exigir. Nunca pular.

| Skill | Quando acionar |
|---|---|
| /scrapup:test-driven-agentic-development | Toda implementacao de codigo de producao. Seguir o ciclo canonico da skill: IMPLEMENT → IMPACT → VERIFY → CORRECT → COBERTURA → SUBMIT |
| /scrapup:mimic-loop | Execucao de TFs (subagents com contexto limpo), loops que nao convergem, sinais e guardrails |
| /scrapup:dispatching-parallel-agents | TFs independentes na US |
| /scrapup:multi-spec-review | Self-review secao 8 — review consolidado com 9 agents em paralelo, antes da PR |
| /scrapup:verification-before-completion | Antes de afirmar conclusao: pos-validacao, pre-PR Open, final |
| /scrapup:commit-message | Geracao de mensagem de commit |
| /scrapup:brainstorming | Invocado pela skill /scrapup:scrapup-blueprint durante producao de artefatos (secao 2) |
| /scrapup:scrapup-blueprint | Leitura de artefatos, formato de single-tasks.md, **producao de artefatos quando nao ha SDD previo** |
| /scrapup:expert-postman | Validacao funcional de APIs |
| /scrapup:expert-pull-request | Criacao da PR Draft |
| /scrapup:cnv | Tom de comunicacao em textos para destinatarios (PR, comentarios) |
| /scrapup:expert-clickup | Criar tarefa no ClickUp quando link ausente |
| /scrapup:systematic-debugging | Bug ou comportamento inesperado durante implementacao |
| /scrapup:saga-session | Rastreamento de progresso via mcp-saga (SQLite): criar projeto, tasks, atualizar status, notes, comments |
| /scrapup:baseline-assessment | Fonte unica de readiness (secao 0) e gate incremental via `verify-diff` ao fim de cada TF. Orquestra por dentro enable-docker-server e setup-node-env; nao chamar essas skills diretamente na forge |
| /scrapup:using-git-worktrees | Setup de worktrees isolados para TFs paralelas (secao 5) |

## Permissoes e MCP

Todos os comandos Shell desta skill devem usar `required_permissions: ["all"]` (rdctl, docker, nvm, npm, git, plantuml, testes).

Ao iniciar, solicitar pre-autorizacao apenas dos MCP servers que esta skill efetivamente usa: `mcp-github` (command `/scrapup:github` — PR, polling de CI), `mcp-sonar` (scan local pre-push e Sonar do CI), `mcp-clickup` (skill `/scrapup:expert-clickup` — link de tarefa), `mcp-postman` (command `/scrapup:postman` — validacao funcional de API), `mcp-serena` (command `/scrapup:serena`, skill `/scrapup:expert-lsp` — navegacao/edicao semantica em repo JS/TS), `mcp-saga` (estado de execucao). **Nao** pre-autorizar o conector Slack: nenhum passo da forge consome Slack; comunicacao externa e delegada a skill propria (`/scrapup:expert-slack`) fora do escopo desta orquestracao.

## Politica de Selecao de Tools

| Contexto | Tool primaria | Fallback |
|---|---|---|
| Navegacao/edicao de codigo em repo **JS/TS** (localizar simbolo, referencias, impacto de teste, edicao por simbolo) | LSP via skill /scrapup:expert-lsp (command `/scrapup:serena`) | `rg` (ripgrep) + leitura de arquivo **somente** se o MCP `mcp-serena` estiver indisponivel — consultar o utilizador antes de seguir sem o LSP em repo JS/TS (regra da skill /scrapup:expert-lsp) |
| Navegacao/edicao em repo **nao-JS/TS** | `rg` (ripgrep) + leitura direcionada | leitura de arquivo |
| Analise estatica de qualidade | `mcp-sonar` (`analyze_code_snippet`) | pular scan local; CI cobre (secao 5, passo 3.1) |
| Operacoes GitHub | command `/scrapup:github` (MCP) | nunca CLI `gh` |

## Limites de iteracao por fase

Tabela unica e canonica. Cada limite reflete o custo e o risco da fase: ciclos de correcao automatica toleram poucas tentativas antes de escalar ao utilizador (evita loop infinito gastando contexto); o loop de validacao pos-commit e mais alto por ser o ponto onde a maioria das correcoes de qualidade converge. Os pontos no corpo referenciam esta tabela.

| Fase | Limite | Ao esgotar | Ref. secao |
|---|---|---|---|
| Resolucao de conflito de merge (re-verificar testes) | 3 ciclos | Escalar ao utilizador com contexto completo | 5 |
| Loop de validacao pos-commit por TF | 10 ciclos | Informar criterios nao satisfeitos; prosseguir so com autorizacao + `note_save` override | 5 (passo 4) |
| Gate incremental `verify-diff` (regressao) | sem teto fixo — corrige por regressao detectada | exit 1 persistente vira item do loop de validacao (10 ciclos) | 5 (passo 5) |
| Consolidacao US (subagents de consolidacao limpos) | 3 tentativas | Informar utilizador e aguardar orientacao | 6 |
| Re-review multi-spec-review apos correcao | 2 ciclos | Informar utilizador e aguardar orientacao | 8 |
| Correcao de CI remoto | 3 tentativas | Informar utilizador; abertura de PR so com autorizacao + `note_save` override | 10 |

---

## 0. Pre-requisitos de Ambiente e Baseline do Projeto

Delegar **integralmente** a skill /scrapup:baseline-assessment, que orquestra por dentro /scrapup:enable-docker-server e /scrapup:setup-node-env e ainda executa descoberta de ferramental, classificacao em 5 categorias operacionais e persistencia de baseline.

**Dispatcher (path canonico):** em todos os comandos abaixo, usar `bash` e ancorar ao plugin com `BASELINE_PLUGIN_DIR` (igual a `baseline-assessment/SKILL.md`):

```bash
BASELINE_PLUGIN_DIR="${BASELINE_PLUGIN_DIR:-$HOME/.claude/plugins/local/scrapup}"
bash "$BASELINE_PLUGIN_DIR/skills/utilitarios/baseline-assessment/scripts/baseline-check.sh" assess --project-path "${REPO_ROOT:-.}"
```

`REPO_ROOT` e a raiz do repositorio alvo (cwd do trabalho ou variavel explicita).

Interpretar a saida JSON:

| Campo | Uso na forge |
|---|---|
| `environment_state` | `ready` → prosseguir; `partial` → prosseguir com ajustes (categoria efetiva ja reduzida); `blocked` → aguardar orientacao do utilizador e nao iniciar execucao |
| `category` e `category_effective` | Calibra o restante do fluxo (ex.: `legado-critico` ou `sem-infra` → nao invocar `verify-diff` ao fim de cada TF) |
| `status` | `blocked-classification` → invocar `classify confirm` no mesmo dispatcher (`bash .../scripts/baseline-check.sh classify confirm ...`) com o utilizador antes de prosseguir |
| `scripts`, `runner`, `linter`, `overrides_active` | Consumidos por subagents de TF via `report` para executar testes corretos |
| `baseline_current`, `baseline_latest` | Referencia para `verify-diff` ao fim de cada TF |

Esta secao substitui a verificacao inline anterior de Docker (/scrapup:enable-docker-server), Node/nvm/`NPM_TOKEN`/`npm install` (/scrapup:setup-node-env) e detecao/execucao do baseline de testes (ver tambem secao 4.1). A forge nunca invoca `rdctl`, `nvm` ou `npm` diretamente; a skill /scrapup:baseline-assessment e a unica orquestradora desses pre-requisitos. **Contrato de saida completo** (campos, semantica de `status`/`gate_decision`, exit codes) na secao **Contratos de saida** da skill /scrapup:baseline-assessment (`skills/utilitarios/baseline-assessment/SKILL.md`) — fonte canonica; os campos consumidos pela forge estao inline na tabela acima e na secao 4.1.

---

## 1. Identificar Tarefa

- Se o utilizador especificou `TF-XX-YY` ou `US-XX`: extrair identificador
- Se nao especificou: perguntar "Qual tarefa (TF-XX-YY) ou user story (US-XX) voce quer executar?"

**Modos de execucao:**

| Identificador | Modo | Comportamento |
|---|---|---|
| `TF-XX-YY` | Tarefa unica | 1 TF, 1 commit principal + eventuais commits de correcao (validacao/self-review/CI), 1 PR |
| `US-XX` | User Story | N TFs na mesma branch, 1 commit por TF, 1 PR para a US |

---

## 2. Localizar / Produzir Artefatos

Alinhado a particao **2** do [`scrapup-forge-flow.puml`](scrapup-forge-flow.puml).

### Busca

Buscar `spec.md`, `plan.md`, `tasks.md`, `single-tasks.md` no workspace inteiro (qualquer localizacao). Nao assumir `docs/specs/**/`. Consultar `mcp-saga` (project_list + tracker_dashboard) por projeto existente para retomar progresso anterior.

Se **artefatos SDD nao forem encontrados** na busca: solicitar caminho ao utilizador (outro repo ou diretorio externo) e ler do caminho informado.

### Artefatos SDD disponiveis (backlog resolvivel)

Quando existir pelo menos um artefato de backlog (`tasks.md` e/ou `single-tasks.md`) acessiveis apos a busca/caminho:

1. Verificar se o identificador (TF ou US) existe em **`tasks.md` ou `single-tasks.md`**
   - **Regra de precedencia:** se ambos existem e o identificador aparece em ambos, `tasks.md` prevalece (fluxo completo > incremental). Se o identificador aparece apenas num: usar esse artefato
2. Se **encontrado:** prosseguir — **caminho SDD** com `tasks.md` (fluxo completo scrapup-blueprint) ou `single-tasks.md` (fluxo incremental scrapup-blueprint)
3. Se **nao encontrado:** informar que o identificador nao esta em `tasks.md` / `single-tasks.md` e oferecer opcoes:
   - (a) Corrigir o identificador ou fornecer novo
   - (b) Se utilizador solicitar producao de novos artefatos: delegar para skill /scrapup:scrapup-blueprint — secao **Producao de Artefatos (sem SDD previo)** (nao saltar automaticamente para brainstorming — apenas quando o utilizador solicitar explicitamente)

### Sem artefatos SDD disponiveis (produzir artefatos)

Ramal **else** do diagrama: quando **nao** ha conjunto utilizavel de artefatos SDD no workspace (apos busca e eventual caminho).

**Delegar para skill /scrapup:scrapup-blueprint** — secao **Producao de Artefatos (sem SDD previo)**. A skill /scrapup:scrapup-blueprint conduz todo o processo de producao de documentacao com o utilizador: brainstorming, analise de workspace, refinamento, triagem de impacto, e producao do artefato adequado (`single-tasks.md` ou fluxo completo `spec.md` + `plan.md` + `tasks.md`).

Ao retornar da skill /scrapup:scrapup-blueprint: verificar que artefatos foram produzidos e aprovados pelo utilizador.

### Selecao de escopo pos-producao

Quando o utilizador nao especificou TF/US na secao 1 (ex: "implementar autenticacao JWT") e a skill /scrapup:scrapup-blueprint produziu artefatos novos, o identificador de execucao e determinado pelo tipo de artefato produzido:

| Artefato produzido | Comportamento |
|---|---|
| `single-tasks.md` (≤5 TFs) | Executar **todas** as TFs definidas — o utilizador participou da producao, o escopo e pequeno e auto-contido. Modo de execucao = US implicita (N TFs, 1 branch, 1 PR) |
| `spec.md` + `plan.md` + `tasks.md` (US + N TFs) | Usar `AskUserQuestion` para perguntar ao utilizador qual User Story executar. O utilizador escolhe e o fluxo prossegue com o identificador selecionado |

Se o utilizador **ja havia especificado** TF/US na secao 1: ignorar esta subsecao — o identificador ja existe.

Apos selecao, prosseguir para a secao 3.

---

## 3. Leitura e Validacao de Artefatos

Alinhado a particao **3** do [`scrapup-forge-flow.puml`](scrapup-forge-flow.puml).

### Leitura paralela

Ler todos os artefatos que existirem no projeto (nao falhar se algum nao existir):

| Artefato | Informacao extraida |
|---|---|
| `tasks.md` | Tarefa/US, sequenciamento, Definition of Done, prompt prescritivo |
| `plan.md` | Contexto arquitetural, contratos (OpenAPI/AsyncAPI), diagramas, DTOs |
| `spec.md` | Regras de negocio, criterios de aceitacao, casos de borda |
| `single-tasks.md` | Fluxo incremental SDD; TF auto-contidas; **ate 5** TF; especificacao nas Tarefas |

**Nota (incremental):** com `single-tasks.md`, **nao** e obrigatorio existir `spec.md` / `plan.md` no mesmo pacote; a consistencia concentra-se nas TF.

### Gate de limite (antes de validar o resto)

Se `single-tasks.md` **e o artefato ativo para esta execucao** (o identificador foi encontrado nele, nao em `tasks.md`) E tiver **mais de 5** blocos `#### TF-`:

1. Informar utilizador: escopo excede limite incremental (maximo 5 TFs em single-tasks.md)
2. Oferecer opcoes:
   - (a) Refatorar `single-tasks.md` para ≤5 TFs e retomar
   - (b) Delegar para skill /scrapup:scrapup-blueprint produzir fluxo completo (`spec.md` + `plan.md` + `tasks.md`) — ao retornar, reavaliar a partir da secao 2
3. Aguardar decisao do utilizador. **Nao avancar para branch ou implementacao.**

Se `single-tasks.md` coexiste mas **nao e o artefato ativo** (o identificador foi encontrado em `tasks.md`): o gate nao se aplica.

### Validacao

Ambos os fluxos (completo e incremental) produzem artefatos SDD a partir de **fontes de conhecimento externas e internas**: prompt do utilizador, historias no ClickUp, atas de reuniao, documentacao de API, contexto da conversa (externas) e o proprio codigo existente no workspace — tipos, interfaces, modulos, convencoes ja estabelecidas (internas). O codigo nao define a especificacao, mas revela o estado atual do aplicativo que deve ser ponderado no momento da especificacao. Os artefatos SDD sao uma visao padronizada dessas fontes. A validacao verifica que a padronizacao foi fiel.

**Contra prova (ambos os fluxos):**

1. Validar que os artefatos SDD cobrem o que foi pedido nas fontes externas — nada perdido
2. Validar que nenhum requisito ou TF foi inventado sem base nas fontes — nada adicionado
3. Detectar **placeholders** e **bloqueios externos** nas TFs (ex: `[INSERIR_IPS]`, dados de terceiros, credenciais pendentes, configs externas)

**Fluxo completo** (spec + plan + tasks.md) — validacao adicional:

4. Validar consistencia cross-artefato: `spec.md` ↔ `plan.md` ↔ `tasks.md` (regras de negocio alinhadas com arquitetura alinhada com tarefas)
5. Verificar contratos (OpenAPI/AsyncAPI) vs DTOs definidos no plan vs nomenclatura nas TFs
6. Verificar nomenclatura de propriedades (idioma, padrao de nomes, DTOs)

**Fluxo incremental** (single-tasks.md) — validacao adicional:

4. Validar consistencia interna entre TFs (nomes de campos/DTOs coerentes entre TFs que se referenciam, sem contradicoes)
5. Verificar nomenclatura de propriedades (idioma, padrao de nomes)

### Resolucao de bloqueios

Se placeholders ou bloqueios encontrados, resolver **proativamente** antes de prosseguir:

1. **Resolucao autonoma primeiro** — para cada placeholder/bloqueio, o agente tenta resolver sem perguntar ao utilizador:
   - Inferir valores do contexto do projeto (configs existentes, `.env.example`, `docker-compose.yml`, variaveis de ambiente documentadas)
   - Buscar no codebase por padroes similares (como o valor e usado em outros modulos)
   - Consultar saga por valores usados em execucoes anteriores (`note_search` tipo `context`)
2. **Se nao resolvivel autonomamente** — perguntar ao utilizador com opcoes:
   - (a) Fornecer o valor
   - (b) Remover TF do escopo desta execucao (a TF permanece no backlog, mas nao sera executada agora — nao e "blocked", e "adiada")
3. Substituir placeholders com valores fornecidos (autonomo ou pelo utilizador)

**Opcao "marcar como blocked" nao existe.** TFs nao ficam em limbo. Ou o bloqueio e resolvido, ou a TF e removida do escopo.

### Gate pos-resolucao

Apos processar todos os bloqueios, verificar se restam TFs executaveis no escopo. Se **0 TFs restam** (todas removidas por bloqueios nao resolviveis): informar utilizador e **encerrar** — nao prosseguir para branch, baseline ou execucao.

### Validacao de consistencia

Se discrepancias, inconsistencias de nomenclatura ou duvidas: questionar utilizador sobre cada ponto e aguardar resposta.

---

## 4. Setup de Branch

### Estrategia de Branching

Antes de operar branches, determinar qual estrategia de branching o projeto adota. A estrategia define a `BASE_BRANCH` (branch base para criacao de feature branches e alvo da PR).

**Deteccao automatica (heuristica):**

1. Verificar branches remotas: `git branch -r`
2. Verificar existencia de `.releaserc.json` (indicador de trunk-based com semantic-release)
3. Verificar existencia de `.github/workflows/tag_version.yml` (indicador de trunk-based)

| Sinal | Sugere |
|---|---|
| Branch `origin/development` existe | Git Flow |
| `.releaserc.json` presente | Trunk-based |
| `tag_version.yml` presente | Trunk-based |
| Apenas `origin/main` (sem `origin/development`) | Trunk-based |

**Sinais conflitantes:** se os sinais apontam para estrategias diferentes (ex.: `origin/development` existe **e** `.releaserc.json` presente), nao desempatar autonomamente — apresentar ambos os sinais ao utilizador na pergunta abaixo e deixar a escolha explicita decidir. O agente nunca infere `BASE_BRANCH` quando ha conflito.

**Decisao do utilizador (obrigatoria):**

Apresentar a heuristica detectada e perguntar ao utilizador via `AskUserQuestion`:

- **Git Flow**: base em `development`, PR para `development`. Branches de feature partem de `development` e retornam para `development`
- **Trunk-based**: base em `main`, PR para `main`. Branches de feature partem de `main` e retornam para `main`. Releases sao geridas por tags (semantic-release)

A resposta define a variavel `BASE_BRANCH`:

| Estrategia | `BASE_BRANCH` |
|---|---|
| Git Flow | `development` |
| Trunk-based | `main` |

Registrar a estrategia escolhida no mcp-saga (`note_save` tipo `context` com `branching_strategy: git-flow|trunk-based` e `base_branch: development|main`).

### Checkout e Atualizacao

```bash
git checkout $BASE_BRANCH
git pull origin $BASE_BRANCH
```

Se a branch da tarefa ja existe: `git checkout <branch>` + `git merge $BASE_BRANCH` (atualizar com base).

Se nao existe: `git checkout -b <tipo>/<id-slug>`.

### Convencao de nome

| Tipo | Prefixo | Exemplo |
|---|---|---|
| Nova funcionalidade | `feat/` | `feat/TF-01-01-criar-schema-mongoose` |
| Correcao | `fix/` | `fix/TF-02-03-corrigir-validacao-dto` |
| Refatoracao | `refactor/` | `refactor/TF-03-01-simplificar-usecase` |
| Testes | `test/` | `test/TF-01-06-testes-integracao-e2e` |
| Infraestrutura | `chore/` | `chore/TF-01-01-setup-migrations` |

Para US inteira: `feat/US-XX-slug-da-story`.

### Worktrees (modo US com TFs independentes)

Se o modo e US e ha TFs independentes (determinado na secao 4.2):

1. Verificar/criar diretorio de worktrees (skill /scrapup:using-git-worktrees: prioridade `.worktrees` > `worktrees` > perguntar ao utilizador)
2. Verificar que o diretorio esta em `.gitignore` (se nao: adicionar + commit)
3. A criacao dos worktrees individuais ocorre na secao 4.2 apos a separacao das TFs

Em modo TF unica ou quando todas as TFs sao dependentes: sem worktrees.

---

## 4.1 Baseline de Testes Local

Secao absorvida pela skill /scrapup:baseline-assessment invocada na secao **0**. Se a primeira invocacao de `assess` nesta sessao retornou `status` em `{cached, green, red-known}` com `environment_state=ready|partial`, o baseline de testes ja esta persistido (test-scripts, baseline-category, baseline-current, baseline-latest) e nao precisa ser re-executado aqui.

Apos setup da branch (secao 4), consultar o estado persistido para ter scripts e categoria atualizados:

```bash
BASELINE_PLUGIN_DIR="${BASELINE_PLUGIN_DIR:-$HOME/.claude/plugins/local/scrapup}"
bash "$BASELINE_PLUGIN_DIR/skills/utilitarios/baseline-assessment/scripts/baseline-check.sh" report --project-path "${REPO_ROOT:-.}"
```

Regras:

- Se `category_effective` retornada e `sem-infra` ou `legado-critico`: a forge nao tenta rodar suite local ao fim de cada TF (delega ao CI remoto). Subagents seguem o que o `report` informa em `scripts`, `runner` e `linter`.
- Se `baseline_current` esta ausente e `baseline_latest.outcome` e `red-known`: suite nao esta verde localmente. Informar utilizador e oferecer opcoes (registrar override via `.../scripts/baseline-check.sh override set`, confirmar classificacao via `classify confirm`, prosseguir mesmo assim com gate remoto).
- Se `overrides_active` contem entradas: subagents devem respeitar essas substituicoes de script (ex.: `test: npm run test:unit`). Overrides novos sao registrados via o mesmo dispatcher (`override set`) — forca TTL 1-30 dias e motivo obrigatorio. Nao usar `note_save` direto no saga.

Subagents de TF nao precisam consultar `BASELINE_OVERRIDES` via `note_search`; consultam `report` no dispatcher (comando acima) e recebem `overrides_active` estruturado.

---

## 4.2 Preparacao de TFs

### Modo US (US-XX)

1. Extrair todas as TFs da US (`tasks.md` ou `single-tasks.md`)
2. Construir grafo de dependencias:
   - **`tasks.md`:** usar coluna **"Depende de"** (grafo explicito)
   - **`single-tasks.md`:** usar dependencias textuais declaradas ("esta TF depende de TF-XX") se existirem; caso contrario, usar **ordem posicional** dos blocos `#### TF-` no documento (de cima para baixo = sequencia implicita)
   - **Complementar** com analise de ficheiros tocados em ambos os casos
3. Separar TFs independentes vs TFs dependentes. Uma TF e **dependente** se qualquer um destes sinais concretos ocorre; caso contrario, e **independente**:
   - **Dependencia declarada:** consta na coluna "Depende de" (`tasks.md`) ou em texto ("esta TF depende de TF-XX", `single-tasks.md`)
   - **Ficheiro em comum:** o conjunto de ficheiros que as duas TFs criam/editam tem intersecao nao vazia
   - **Acoplamento de contrato:** uma TF define um simbolo (tipo, interface, DTO, schema, funcao, rota, migration) que a outra importa, consome ou estende — ex.: schema + migration sobre a mesma entidade; DTO + controller que o valida; tipo + funcao que o recebe. Em repo JS/TS, confirmar via /scrapup:expert-lsp (referencias do simbolo); fora de JS/TS, via `rg` do nome do simbolo entre os ficheiros das TFs
   - **Fallback conservador:** quando nenhum sinal e conclusivo mas a independencia nao pode ser afirmada com certeza, classificar como **dependente** e executar sequencialmente na ordem do documento

### Criacao de worktrees (modo US com TFs independentes)

Se TFs independentes existem (separadas no passo anterior):

1. Para cada TF independente, criar worktree:
   - Branch: `{tipo}/{US-XX}-{TF-YY}-slug` (branch filha da branch US)
   - Path: `.worktrees/{TF-YY}-slug`
   - Comando: `git worktree add .worktrees/{TF-YY}-slug -b {tipo}/{US-XX}-{TF-YY}-slug`
2. Executar `npm install` em cada worktree (node_modules isolados por worktree)
3. Registrar path do worktree na task do saga (`comment_add` com worktree path)

Worktrees garantem isolamento real: cada subagent paralelo opera no seu proprio diretorio, sem conflitos de `git add`, index ou arquivos. Sem worktrees, commits concorrentes na mesma branch falham.

### Modo TF (TF-XX-YY)

Lista de TFs = [TF solicitada].

### Saga MCP (mcp-saga)

Criar projeto e tasks via skill /scrapup:saga-session. Convencoes de nomes, tipos de note e regras de lifecycle seguem a secao **Registro de Colecoes** da skill /scrapup:saga-session — fonte canonica.

1. `project_create` com nome `exec:{repo}:{TF-XX-YY|US-XX}` e descricao
2. `epic_create` para a US (se aplicavel)
3. `task_create` para cada TF com `depends_on` conforme grafo de dependencias
4. Overrides de script de baseline (utilizador desativou ou alterou comandos na secao 4.1) **nao** sao gravados via `note_save`: registrar pelo dispatcher da /scrapup:baseline-assessment (`override set`, com TTL e motivo obrigatorios — secao 4.1). Os subagents leem `overrides_active` via `report`, nao via `note_search`

O mcp-saga substitui o PROGRESS.md com vantagens: queries estruturadas (~800 tokens vs ~3000 tokens de markdown), dashboard de progresso, activity log, e busca cross-entity.

---

## 4.3 Relatorio de Risco Pre-Execucao

Antes de iniciar a execucao, gerar um relatorio de risco para o utilizador. Neste ponto o agente ja tem: ambiente validado, artefatos lidos, placeholders resolvidos, baseline verde, TFs extraidas com dependencias mapeadas.

### Fonte de dados atual

Consultar `mcp-saga` (task_list + task_get com dependencias) para obter dados estruturados de cada TF: status, dependencias, notas, bloqueios. Usar estes dados como base da analise em vez de re-ler tasks.md.

### Fonte de dados historica

Consultar `mcp-saga` por dados de execucoes anteriores para calibrar a analise:

1. `activity_log` — historico de mudancas de status, tempo real entre `in_progress` e `done` por TF
2. `note_search` tipo `technical` — padroes de falha recorrentes, issues de Sonar, problemas de integracao
3. `note_search` tipo `progress` — resumos de sessoes anteriores com o que funcionou e o que falhou
4. `tracker_search` por keywords tecnologicas — ex: "jwt", "zod", "prisma migrate", "rabbitmq"

**Dados historicos que calibram o relatorio:**

| Dado historico | Como calibra | Exemplo |
|---|---|---|
| Tempo real vs estimado | Ajusta estimativa de tempo | TFs de Guard levaram 15min em media, nao 8min |
| TFs que falharam em projetos anteriores | Identifica padroes de risco | "Migration Prisma falhou 2x por MySQL offline" |
| Tipos de erro mais frequentes | Prioriza mitigacoes | "60% das falhas de CI sao lint, nao testes" |
| Correcoes de self-review recorrentes | Antecipa problemas | "Guards sempre recebem sugestao de timing-safe" |
| Ciclos de validacao pos-commit | Estima custo real | "TFs de UseCase usam 4-5 ciclos em media" |

Se nao houver historico (primeiro uso do mcp-saga ou projeto novo): informar que a analise nao tem dados historicos para calibrar e usar apenas a analise tecnica. Com o tempo, o relatorio fica progressivamente mais preciso.

### Analise por TF

Para cada TF, avaliar:
- **Complexidade:** quantos conceitos distintos, quantos arquivos, quantas dependencias
- **Tipo:** codigo (TDAD) vs infra/config (DoD)
- **Riscos tecnicos:** bibliotecas novas, padroes nao documentados, integracao com sistemas externos
- **Dados externos:** credenciais, IPs, tokens de terceiros
- **Historico:** TFs similares em projetos anteriores, tempo real, padroes de falha

### Conteudo do relatorio

1. **Probabilidade de sucesso** estimada (%) — calibrada por dados historicos quando disponiveis
2. **TFs de alto risco** com justificativa + padroes de falha similares encontrados no historico
3. **Sugestoes de mitigacao:**
   - Fatiar TF complexa em sub-TFs
   - Fornecer mais contexto (ex: referencia a guard existente no projeto)
   - Resolver dependencia externa pendente
   - Reordenar ondas de paralelizacao
   - Antecipar correcoes que o self-review provavelmente vai sugerir (baseado no historico)
4. **Ondas de paralelizacao** com TFs em cada onda
5. **Tempo estimado de execucao** — calibrado por tempo real de execucoes anteriores

### Decisao do utilizador

Apresentar o relatorio e perguntar:
- "Deseja executar acoes antes de continuar?" (fatiar TFs, fornecer contexto, resolver deps)
- "Deseja ajustar os overrides de baseline?" (alteracoes via dispatcher `override set` da /scrapup:baseline-assessment — secao 4.1)
- "Deseja remover alguma TF do escopo desta execucao?"
- "Deseja prosseguir como esta?"

Se o utilizador solicitar acoes: executar, atualizar tasks no mcp-saga, e re-avaliar se necessario.

Se prosseguir: iniciar execucao.

---

## 5. Execucao de TFs (mimic-loop)

### TFs independentes (paralelas — com worktrees)

Se TFs independentes existem (worktrees ja criados na secao 4.2):

1. Despachar agentes paralelos via skill /scrapup:dispatching-parallel-agents
   - Cada subagent opera no seu worktree (`working_directory` apontando para `.worktrees/{TF-YY}-slug`)
   - Subagent faz commit na branch do worktree (nao na branch US)
2. Aguardar conclusao de todos os subagents paralelos
3. Atualizar status no mcp-saga (task_update, comment_add)
4. **Merge de worktrees na branch US:**
   - `git checkout {branch-US}` (voltar para branch principal)
   - Para cada worktree concluido: `git merge --no-ff {branch-worktree}` com mensagem `"chore(escopo): merge TF-YY — <slug>"`
   - Se conflito de merge: **resolucao spec-driven** (ver subsecao abaixo)
   - `git worktree remove .worktrees/{TF-YY}-slug` para cada worktree
   - `git branch -d {branch-worktree}` para cada branch temporaria
5. Prosseguir para TFs sequenciais na branch US (sem worktrees)

### Resolucao de conflitos de merge (spec-driven)

O agente tem artefatos SDD (spec.md, plan.md, tasks.md ou single-tasks.md) com a especificacao completa de cada TF. Se o merge entre worktree branches gera conflito, o agente usa esses artefatos como fonte de verdade para resolver — nao e necessario escalar ao utilizador.

**Principio:** se o agente tem especificacao suficiente para implementar, tem especificacao suficiente para decidir o merge.

**Fluxo de resolucao:**

1. `git merge --no-ff {branch-worktree}` resulta em conflito
2. Listar arquivos em conflito via `git diff --name-only --diff-filter=U`
3. Para cada arquivo em conflito:
   a. Ler o conteudo conflitado (marcadores `<<<<<<<`, `=======`, `>>>>>>>`)
   b. Consultar artefatos SDD: qual TF tocou este arquivo e com que intencao (tasks.md descreve o que cada TF faz)
   c. Consultar mcp-saga: `task_get` de ambas as TFs para obter notas, commit messages e contexto de implementacao
   d. Combinar ambas as implementacoes respeitando a especificacao: o resultado deve satisfazer os requisitos de AMBAS as TFs
   e. Se as TFs alteram a mesma funcao/metodo: compor as mudancas (ex: TF-A adiciona campo X, TF-B adiciona campo Y → resultado tem ambos)
   f. Se as TFs sao genuinamente contraditorias (uma remove o que a outra adiciona): a especificacao da TF com maior prioridade no grafo de dependencias prevalece; se mesma prioridade, consultar spec.md para determinar o comportamento correto
4. Resolver conflito no arquivo (edicao direta, remover marcadores)
5. `git add {arquivo-resolvido}`
6. Executar testes impactados via TDAD (skill /scrapup:test-driven-agentic-development) para verificar que a resolucao nao quebrou nenhuma das duas TFs
7. Se testes falham: ajustar resolucao e re-verificar (maximo 3 ciclos — ver **Limites de iteracao por fase**)
8. Se apos 3 ciclos nao converge: **entao** escalar ao utilizador com contexto completo (arquivo, conflito, ambas TFs, tentativa de resolucao, testes que falharam)
9. Apos todos os conflitos resolvidos: `git commit` (merge commit)
10. Registrar no mcp-saga: `comment_add` em ambas as TFs com nota sobre conflito resolvido e como

### TFs dependentes (sequenciais)

Loop por cada TF pendente no mcp-saga (executa na branch US, sem worktrees):
1. Consultar mcp-saga (`task_list status=todo`) e identificar proxima TF **cujas dependencias estao todas com status done** (verificar `depends_on` de cada task)
2. Despachar subagent com contexto limpo via skill /scrapup:mimic-loop
3. Verificar mcp-saga (task_get) atualizado pelo subagent
4. Repetir ate nao haver TFs pendentes com dependencias satisfeitas

### O que cada subagent executa

Os passos abaixo alinham com a nota do subagent no `.puml` (numeracao 0-based, sub-passo 3.1):

0. Consultar `report` via dispatcher da /scrapup:baseline-assessment (bloco `BASELINE_PLUGIN_DIR` + `bash .../scripts/baseline-check.sh report --project-path "${REPO_ROOT:-.}"`) para obter `scripts`, `runner`, `linter`, `overrides_active`, `category_effective` e `baseline_latest`. Respeitar entradas em `overrides_active` (alternativa ou desativado) e a `category_effective` ativa (ex.: em `legado-critico`, nao insistir em testes que exigem infra indisponivel)
1. Consultar mcp-saga (task_get) + tarefa completa (tasks.md ou single-tasks.md)
2. Implementacao:
   - **Tarefa de codigo:** ciclo IMPLEMENT → IMPACT → VERIFY → CORRECT → COBERTURA → SUBMIT por comportamento (skill /scrapup:test-driven-agentic-development — fonte canonica do ciclo)
   - **Tarefa infra/config:** executar + verificar DoD (build passa, app inicia, etc.)
   - Se bug ou comportamento inesperado: acionar skill /scrapup:systematic-debugging. Apos resolucao do bug, retomar ciclo TDAD na fase IMPACT (re-verificar testes impactados pelo fix)
3. Testes + lint + commit autonomo (skill /scrapup:commit-message). Capturar o SHA do commit (`COMMIT_SHA`)
   - **Env vars nos testes:** carregar via `process.env` no setup do teste. Nunca depender de `.env.test`
   - **PROIBIDO:** `git add .` — listar arquivos explicitamente
3.1. **Scan Sonar local (pre-push):**
   - Listar arquivos `.ts`/`.js` alterados via `git diff --name-only ${COMMIT_SHA}~1..${COMMIT_SHA}` (usar SHA explicito — `HEAD~1` nao e seguro em contexto de TFs paralelas)
   - Para cada arquivo: chamar `analyze_code_snippet` via MCP `mcp-sonar` com `language: ["ts"]`, `scope: ["MAIN"]`, `projectKey` do projeto
   - Se issues HIGH ou BLOCKER encontradas: corrigir via TDAD (skill /scrapup:test-driven-agentic-development) → `git commit --amend` → re-analisar
   - Se limpo ou apenas issues LOW/MEDIUM: prosseguir (issues menores serao pegas no CI)
   - Se MCP `mcp-sonar` indisponivel: pular scan local (CI fara a verificacao completa)
4. Validacao pos-commit (maximo 10 ciclos — ver **Limites de iteracao por fase**):
   - Verificar (exceto itens desativados por BASELINE_OVERRIDES): aderencia a documentacao, tipagem estrita (sem `any`), validacao de DTOs na borda, tratamento de erros/resiliencia, testes passando, lint limpo, sem hardcode, boas praticas
   - Se melhorias necessarias: implementar via TDAD (skill /scrapup:test-driven-agentic-development), executar testes, `git commit --amend`, incrementar ciclo
   - Skill /scrapup:verification-before-completion ao final do loop
   - Se 10 ciclos sem aprovacao total: informar utilizador com lista de criterios nao satisfeitos e aguardar orientacao. Se utilizador autoriza prosseguir: marcar task como done no mcp-saga com `comment_add` detalhando criterios nao satisfeitos e decisao do utilizador, registrar `note_save` tipo `override`
5. **Gate incremental via baseline-assessment** — antes de declarar a TF concluida, executar `verify-diff` no mesmo dispatcher: `bash "$BASELINE_PLUGIN_DIR/skills/utilitarios/baseline-assessment/scripts/baseline-check.sh" verify-diff --project-path "${REPO_ROOT:-.}" --scope=commit` (com `BASELINE_PLUGIN_DIR` como na secao **0**). Exit code 0 (pass) ou 2 (warn por falha pre-existente / flaky / sem baseline ou pos-`assess` implicito) permite prosseguir; exit code 1 (fail) indica regressao — corrigir via TDAD, novo commit sem `amend`, re-verificar. Em `legado-critico`/`sem-infra`, `verify-diff` so roda lint; aceitar `pass` sem insistir em testes locais.
6. Atualizar mcp-saga: task_update → done, comment_add com commit hash e notas

### Restricoes de implementacao (Filosofia Ironclad)

- **TypeScript estrito** — proibido `any`, usar tipagem estrita ou `unknown` com Type Guards
- **Validacao na borda** — todo DTO validado com Zod (Fastify) ou class-validator (NestJS)
- **Zero Trust** — nunca confiar em dados externos, validar tudo
- **Resiliencia** — try/catch, retries, circuit breakers, DLQ conforme documentacao
- **Mensageria** — usar o cliente RabbitMQ padronizado do projeto, nunca `amqplib` nativo
- **Logger** — usar o logger estruturado padronizado do projeto
- **Sem hardcode** — variaveis de ambiente via config, nunca inline
- **Queries** — nunca `SELECT *`, especificar campos

---

## 5.1 Guarda Pos-Execucao

Apos o mimic-loop (secao 5) concluir:

1. Consultar mcp-saga `task_list`: contar tasks com status `done`
2. Se **0 tasks done**: informar utilizador que nenhuma TF foi completada (listar motivos por TF — falha de subagent, bloqueio nao resolvido, etc.), oferecer opcoes:
   - (a) Resolver bloqueios e re-executar
   - (b) Encerrar execucao
   - Aguardar decisao do utilizador. **Nao prosseguir para consolidacao, validacao ou PR.**
3. Se **>=1 task done**: prosseguir para secao 6 (se US) ou secao 7

---

## 6. Consolidacao US (apenas para US-XX)

Worktrees ja foram removidos na secao 5 (merge + cleanup). A consolidacao opera na branch US com todos os merges feitos.

Apos todas as TFs concluidas, despachar subagent de consolidacao com contexto limpo (skill /scrapup:mimic-loop):

1. Ler `overrides_active` via `report` do dispatcher da /scrapup:baseline-assessment (secao 4.1)
2. Executar suite completa de testes
3. Executar linter
4. **Scan Sonar local** nos arquivos alterados via `analyze_code_snippet` (MCP `mcp-sonar`)
5. Verificar integracao entre TFs: imports resolvem entre modulos, tipos/interfaces alinham entre camadas (DTO → UseCase → Controller), contratos respeitados (OpenAPI/AsyncAPI vs implementacao), fluxo end-to-end funcional (request → response para APIs, input → output para processamento)
6. Se falhas (testes, lint, Sonar HIGH/BLOCKER): corrigir via TDAD (skill /scrapup:test-driven-agentic-development)
7. Commit de correcao (sem amend): `"fix(escopo): corrigir integracao entre TFs da US"`
8. Atualizar mcp-saga: comment_add, note_save tipo progress

Se falhas persistem: ate 3 tentativas com subagents de consolidacao limpos (ver **Limites de iteracao por fase**). Apos 3 tentativas sem resolucao: informar utilizador e aguardar orientacao.

Ao final: skill /scrapup:verification-before-completion — evidencia antes de afirmar conclusao.

---

## 7. Validacao Funcional

### Projeto API

1. Criar/atualizar collection via skill /scrapup:expert-postman
2. Organizar requests por dominio/modulo/feature
3. Sincronizar collection via API Postman
4. Informar utilizador que collection esta pronta

### Projeto nao-API

1. Identificar estrategia de teste aplicavel ao tipo de projeto
2. Informar utilizador sobre como validar a implementacao

### Loop de validacao

1. Aguardar utilizador executar testes e validar
2. Se problemas reportados:
   - Corrigir via TDAD (skill /scrapup:test-driven-agentic-development)
   - Executar suite completa de testes
   - `git add <arquivos corrigidos>` (explicitos, nunca `git add .`)
   - Commit sem amend: `"fix(escopo): corrigir problema reportado na validacao"`
   - Registrar correcao no mcp-saga: `comment_add` na task afetada com detalhe do que foi corrigido
   - Re-sincronizar collection se API
   - Aguardar nova validacao
3. Repetir ate utilizador confirmar validacao OK

**Este e o unico ponto bloqueante obrigatorio de validacao pelo utilizador no happy path** (distinto de pontos de decisao como secao 4.3 que tambem aguardam resposta). O utilizador valida e confirma.

---

## 8. Self-Review (multi-spec-review)

<EXTREMELY-IMPORTANT>
Esta secao e **inegociavel** independente do escopo, numero de ficheiros ou existencia de review externo (bot, humano). Se considerar pular por qualquer motivo, isto e red flag de racionalizacao. Executar ou escalar ao utilizador. NUNCA marcar como completa sem executar.
</EXTREMELY-IMPORTANT>

1. Determinar escopo via pipeline MSR (skill /scrapup:multi-spec-review):
   ```bash
   MSR_DIR="${BASELINE_PLUGIN_DIR:-$HOME/.claude/plugins/local/scrapup}/skills/validacao/multi-spec-review/scripts"
   bash "$MSR_DIR/msr-scope.sh" --mode validate --repo . --files "$(git diff --name-only $BASE_BRANCH...HEAD | tr '\n' ',' | sed 's/,$//')" --json
   ```
   Se `files: []` apos filtro, abortar self-review com mensagem explicita.
2. Executar skill /scrapup:multi-spec-review no modo Validacao (pipeline `msr-scope` → `msr-pack` → `msr-budget` → dispatch single-shot com pack inline)
   - Os 9 agents sao invocados em paralelo com o mesmo review pack (qa, security, architecture, clean-code, observability, performance, testing, homogeneity, ethics)
   - Dedup mecanico (`msr-dedup`), dedup semantico, resolucao de contradicoes e report consolidado sao produzidos pela skill
3. Receber report consolidado (findings por arquivo, decisao GO/NO-GO)
4. Avaliar decisao consolidada:

### Decisao GO

Nenhuma sugestao Blocker/Critical/Major. Findings Minor e Nit (se existirem): registrar no mcp-saga (`note_save` tipo `technical`) para referencia — nao implementar, serao capturados em code review humano. Aprovado internamente para abertura da PR (secao 9) sem alteracoes de codigo.

### Decisao GO_CONDITIONAL (findings Major)

1. Filtrar sugestoes Major relevantes para o contexto da tarefa
2. Descartar sugestoes com impacto em artefatos fora da tarefa
3. Findings Minor e Nit: registrar no mcp-saga (`note_save` tipo `technical`) para referencia — nao implementar
4. Implementar findings Major via TDAD (skill /scrapup:test-driven-agentic-development)
5. Executar suite completa de testes + linter
6. Se falhas: corrigir via TDAD
7. `git add <arquivos da tarefa>` (explicitos)
8. Commit autonomo: `"refactor(escopo): aplicar melhorias de self-review — <detalhe>"`
9. Registrar melhorias no mcp-saga: `note_save` tipo technical com specs analisadas e sugestoes aplicadas

### Decisao NO-GO (findings Blocker ou Critical)

1. Classificar findings Blocker/Critical:
   - **Corrigiveis pelo agente:** a correcao nao altera interface publica, nao muda contrato, nao requer novo modulo (ex: catch generico, validacao ausente, hardcode de secrets)
   - **Requerem decisao do utilizador:** muda contrato, novo modulo, trade-off de negocio (ex: redesign arquitetural, mudanca de API)
2. **Corrigiveis:** implementar via TDAD (skill /scrapup:test-driven-agentic-development), executar testes + linter, commit: `"fix(escopo): corrigir <severity> de <spec> — <detalhe>"`
3. **Requerem decisao:** informar utilizador com lista de findings, impacto e opcoes. Aguardar orientacao
4. Findings Major: incluir na correcao se afetam o mesmo arquivo; caso contrario, adiar para eventual GO_CONDITIONAL apos re-review
5. Apos correcoes: **re-executar multi-spec-review** com escopo recalculado via `git diff --name-only $BASE_BRANCH...HEAD` (inclui novos arquivos criados pelo fix)
6. Avaliar nova decisao do re-review: se GO → prosseguir para secao 9 (PR Draft); se GO_CONDITIONAL → seguir fluxo GO_CONDITIONAL acima; se NO-GO → incrementar ciclo e repetir
7. Maximo 2 ciclos de re-review (ver **Limites de iteracao por fase**). Se apos 2 ciclos ainda ha NO-GO: informar utilizador e aguardar orientacao
8. Registrar no mcp-saga: `note_save` tipo technical com findings corrigidos, ciclos de re-review usados e decisao final

**So prosseguir para a secao 9 (abertura da PR Draft) apos decisao GO/GO_CONDITIONAL.** A PR nunca e aberta com self-review pendente ou em estado NO-GO nao resolvido.

---

## 9. Pull Request Draft

<EXTREMELY-IMPORTANT>
A PR Draft so e criada **apos** o self-review da secao 8 concluir com decisao GO ou GO_CONDITIONAL. Abrir PR antes do multi-spec-review e violacao do fluxo.
</EXTREMELY-IMPORTANT>

### ClickUp

1. Verificar link de tarefa ClickUp em tasks.md ou single-tasks.md
2. Se link nao registrado: perguntar ao utilizador se o agente cria (skill /scrapup:expert-clickup) ou se o utilizador cria manualmente
3. Registrar link no artefato

### Limpeza

Registrar conclusao no mcp-saga: note_save tipo progress com resumo da execucao. Nao ha arquivos de progresso para limpar (estado vive no SQLite do mcp-saga).

### Criacao da PR

1. `git push -u origin <branch>` (inclui os commits de correcao do self-review, se houver)
2. Criar PR Draft para `BASE_BRANCH` via command `/scrapup:github` (nunca CLI `gh`)
3. Descricao com contexto e escopo (skill /scrapup:expert-pull-request + skill /scrapup:cnv para tom de comunicacao)
4. Associar link da tarefa ClickUp na descricao
5. **Em Git Flow:** PROIBIDO criar PR para `main`/`master` sem instrucao explicita do utilizador. **Em Trunk-based:** PR para `main` e o comportamento padrao (definido pela `BASE_BRANCH`)
6. **PROIBIDO:** criar PR pronta para revisao — sempre Draft

---

## 10. Monitorar CI Checks

**pre-push hook local NAO e CI remoto.** O hook valida lint/testes no ambiente local antes do push — isto nao substitui os checks do GitHub (Sonar, GitHub Actions, npm audit). A secao 10 so esta completa quando os checks **remotos** concluirem e forem tratados. Declarar "CI passou" com base apenas no pre-push hook e violacao.

1. Polling a cada 60s via command `/scrapup:github` ate checks **remotos** concluirem (nunca declarar conclusao com base em hooks locais). O push e a criacao da PR ja ocorreram na secao 9

### Checks passaram

Skill /scrapup:verification-before-completion para verificar evidencia. Marcar PR como Open via command `/scrapup:github`.

### Apenas npm audit falhou

Marcar PR como Open. Alertar utilizador sobre problemas de npm audit (nao bloquear).

### Lint ou testes falharam

1. Corrigir erros via TDAD (skill /scrapup:test-driven-agentic-development)
2. Executar suite completa de testes localmente
3. `git add <arquivos corrigidos>` (explicitos)
4. Commit sem amend: `"fix(escopo): corrigir falha de CI — <detalhe>"`
5. Registrar fix no mcp-saga: `comment_add` com detalhe do CI fix
6. `git push`
7. Voltar a monitorar checks

### Sonar falhou

1. Se MCP `mcp-sonar` disponivel: analisar issues via MCP
2. Corrigir issues via TDAD (skill /scrapup:test-driven-agentic-development)
3. Commit sem amend + push
4. Se MCP indisponivel: informar utilizador, sugerir alternativas (configurar MCP, analisar manualmente, compartilhar link do report), aguardar orientacao
   - Se utilizador autoriza abertura de PR apesar de Sonar: registrar decisao no mcp-saga (`note_save` tipo `override` com detalhe do CI incompleto), marcar PR como Open, sair do loop

### Erro nao tratavel

Informar utilizador sobre o erro e aguardar orientacao.
- Se utilizador autoriza abertura de PR apesar do erro: registrar decisao no mcp-saga (`note_save` tipo `override`), marcar PR como Open, sair do loop

### Limite de tentativas

Maximo 3 tentativas de correcao de CI (ver **Limites de iteracao por fase**). Apos 3 sem resolucao: informar utilizador e aguardar orientacao.
- Se utilizador autoriza abertura de PR: registrar decisao no mcp-saga (`note_save` tipo `override` com tentativas esgotadas e detalhe), marcar PR como Open, sair do loop

---

## Verificacao Final

Antes de declarar "tarefa concluida":

1. Skill /scrapup:verification-before-completion — verificar evidencia de testes, lint, CI passando, PR marcada como Open, checklist completo
2. Verificar `mcp-saga` dashboard (`tracker_dashboard`): todas as tasks done, nenhum blocker pendente
3. Se alguma task nao esta done ou ha blocker: investigar e resolver antes de afirmar conclusao

**Nunca afirmar conclusao sem evidencia.**

### Relatorio de Conclusao ao utilizador

Apos a verificacao final passar, entregar ao utilizador um relatorio com os campos obrigatorios abaixo. Este e o contrato de saida da skill — o que orquestradores (`/scrapup:mimic-loop`) e o utilizador consomem para confirmar o desfecho. Campo sem valor aplicavel: marcar `n/a` com motivo; nunca omitir a linha.

| Campo | Conteudo |
|---|---|
| PR URL | Link da PR aberta (secao 9) |
| Estado da PR | `Draft` ou `Open` (apos secao 10) |
| `BASE_BRANCH` | Branch base / alvo da PR (`main` ou `development`, secao 4) |
| Branch da tarefa | Nome da feature branch (`<tipo>/<id-slug>`) |
| Identificador | `TF-XX-YY` ou `US-XX` executado |
| TFs done/total | Ex.: `3/4` — quando `< total`, listar as TFs nao concluidas e o motivo |
| Decisao MSR | Decisao consolidada do self-review (secao 8): `GO` / `GO_CONDITIONAL` / `NO-GO` + ciclos de re-review usados |
| Status CI | Resultado dos checks remotos (secao 10): `passou` / `npm audit only` / `Sonar pendente` / `aberto via override` etc. |
| Link ClickUp | Link da tarefa (secao 9) **quando aplicavel**; `n/a` se o projeto nao usa ClickUp |
| Overrides aplicados | BASELINE_OVERRIDES, `--no-verify` ou decisoes de prosseguir sob aviso, com motivo; `nenhum` se nao houve |

### Metricas pos-execucao

Registrar no mcp-saga (`note_save` tipo `metrics`) com dados quantitativos da execucao:

- Tempo total de execucao (inicio ao PR Open)
- TFs completadas vs falhadas
- Ciclos de validacao pos-commit usados por TF (media e maximo)
- Issues Sonar encontradas vs corrigidas (local e CI)
- Tentativas de correcao de CI
- Ondas paralelas executadas vs sequenciais
- Numero de interacoes com o utilizador

Estes dados alimentam o relatorio de risco (secao 4.3) de execucoes futuras via `activity_log` e `note_search` tipo `metrics`.

### Licoes aprendidas

Registrar no mcp-saga (`note_save` tipo `lesson`) com analise qualitativa:

- O que funcionou bem (padroes que deram certo de primeira)
- Padroes de falha encontrados (ex: "migrations Prisma falham sem MySQL local")
- TFs que precisaram de mais ciclos de validacao e por que
- Sugestoes do self-review que foram recorrentes (ex: "sempre faltou timing-safe em guards")
- Problemas de ambiente resolvidos e como (para futuras baseline)
- Decisoes do utilizador que afetaram a execucao (BASELINE_OVERRIDES, TFs blocked, fatiamento)

Licoes sao recuperadas na secao 4.3 via `note_search` tipo `lesson` + keywords tecnologicas, calibrando o relatorio de risco progressivamente.

---

## Uso de --no-verify

O agente **nunca** usa `--no-verify` por iniciativa propria.

### Quando o utilizador pode solicitar

- Falhas generalizadas em testes nao alterados (problema de ambiente local)
- Hooks pre-commit ou pre-push que dependem de ferramentas externas indisponiveis
- Utilizador avaliou o risco e decide prosseguir

### Protocolo

1. Agente identifica a falha e informa utilizador com detalhes (mensagem de erro, hook que falhou)
2. Agente **nunca sugere** `--no-verify`
3. Se utilizador solicitar explicitamente:
   - Confirmar: "Voce solicitou --no-verify. A validacao de hooks sera ignorada. Deseja prosseguir?"
   - Executar com `--no-verify`
   - Registrar no mcp-saga (note_save) que a operacao foi feita com `--no-verify` a pedido do utilizador
4. Agente nunca sugere, recomenda ou incentiva `--no-verify`

O `--no-verify` so se aplica a commit e push. Nunca usar para burlar validacoes de qualidade do loop de validacao pos-commit.

---

## Restricoes Negativas

- **NUNCA** prossiga com `single-tasks.md` que tenha **mais de 5** Tarefas (`#### TF-`) — exigir fluxo completo /scrapup:scrapup-blueprint (repete gate das secoes 2 e 3)
- **NUNCA** inicie implementacao sem ler os artefatos SDD disponiveis (`tasks.md` e/ou `single-tasks.md`, e `spec`/`plan` quando existirem)
- **NUNCA** faca `git add .` ou `git add -A` — liste arquivos explicitamente
- **NUNCA** use `--no-verify` por iniciativa propria
- **Em Git Flow, NUNCA** crie PR para `main`/`master` sem instrucao explicita do utilizador. Em Trunk-based, a PR para `main` e o fluxo padrao definido pela `BASE_BRANCH`
- **NUNCA** assuma regras de negocio criticas — pergunte ao utilizador
- **NUNCA** pule o TDAD para codigo de producao (tarefas infra/config seguem DoD)
- **NUNCA** afirme conclusao sem evidencia (rodar testes, verificar lint)
- **NUNCA** dependa de `.env.test` — carregar env vars via `process.env` no setup do teste
- **NUNCA** inicie implementacao com placeholders pendentes nos artefatos — resolver proativamente ou remover TF do escopo
- **NUNCA** inicie execucao com bloqueios nao resolvidos — resolver proativamente (autonomo + utilizador) ou remover TF do escopo
- **NUNCA** despache TFs paralelas que tenham dependencias entre si (worktrees protegem contra conflitos de arquivo, mas dependencias logicas causam merges contraditorios)
- **NUNCA** despache TFs paralelas sem worktrees isolados — cada TF paralela deve ter seu proprio worktree e branch
- **NUNCA** prossiga para PR/self-review com 0 TFs completadas
- **NUNCA** crie PR pronta para revisao — sempre Draft
- **NUNCA** use CLI `gh` para operacoes GitHub — usar command `/scrapup:github`
- **NUNCA** marque secao como completa sem executar — cada secao (0-10 + Verificacao Final) e inegociavel: executar ou escalar ao utilizador
- **NUNCA** trate pre-push hook local como equivalente a CI remoto — secao 10 exige polling de checks do GitHub via MCP
- **NUNCA** substitua multi-spec-review por review de bot, verificacoes inline ou qualquer outra forma de validacao — secao 8 e complementar, nao intercambiavel
- **NUNCA** abra a PR Draft (secao 9) antes de concluir o self-review (secao 8) com decisao GO/GO_CONDITIONAL

---

## Checklist TodoWrite

Ao iniciar a execucao, criar todos via TodoWrite:

- [ ] Secao 0: Pre-requisitos de ambiente e baseline via /scrapup:baseline-assessment (`assess`) — interpretar `environment_state`/`category` (a forge nao invoca `rdctl`/`nvm`/`npm` diretamente)
- [ ] Secao 1: Identificar tarefa/US
- [ ] Secao 2: Localizar/produzir artefatos (busca; resolver TF/US em `tasks.md` ou `single-tasks.md`; se sem artefatos, delegar para a skill /scrapup:scrapup-blueprint producao + gate **<= 5 TF**)
- [ ] Secao 3: Ler artefatos em paralelo; gate **<= 5 TF** em `single-tasks.md`; validar consistencia; **resolver bloqueios proativamente** (autonomo → utilizador → remover TF); gate 0 TFs executaveis
- [ ] Secao 4: **Estrategia de branching** (Git Flow vs Trunk-based, definir `BASE_BRANCH`) + setup de branch + **worktrees** (se US com TFs independentes)
- [ ] Secao 4.1: Consultar estado persistido do baseline via dispatcher (`report`) — `scripts`, `runner`, `linter`, `category_effective`, `overrides_active`
- [ ] Secao 4.2: Preparar TFs + **criar worktrees** por TF independente + projeto no mcp-saga
- [ ] Secao 4.3: Relatorio de risco pre-execucao (utilizador decide)
- [ ] Secao 5: Executar TFs (**paralelas em worktrees** + sequenciais na branch US) + **merge spec-driven** de worktrees
- [ ] Secao 5.1: **Guarda pos-execucao** (0 TFs done → informar + encerrar ou re-executar)
- [ ] Secao 6: Consolidacao US (se US-XX) — worktrees ja removidos
- [ ] Secao 7: Validacao funcional (utilizador valida)
- [ ] Secao 8: Self-Review (multi-spec-review) — antes da PR
- [ ] Secao 9: Pull Request Draft + ClickUp
- [ ] Secao 10: Monitorar CI Checks + PR Open
- [ ] Verificacao final
- [ ] Relatorio de Conclusao ao utilizador (PR URL, estado, BASE_BRANCH, branch, identificador, TFs done/total, decisao MSR, status CI, link ClickUp, overrides)
- [ ] Registrar metricas pos-execucao no mcp-saga
- [ ] Registrar licoes aprendidas no mcp-saga
