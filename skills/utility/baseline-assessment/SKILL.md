---
name: baseline-assessment
description: Use quando precisar avaliar readiness de ambiente, descobrir ferramental de teste, classificar projeto Node/TS nas cinco categorias estaveis (mais estado de triagem indefinido), verificar se um diff regride o baseline ou consultar estado persistido via report. Fonte unica de readiness do ecossistema scrapup; consumida por scrapup-forge, test-driven-agentic-development (TDAD), agente scrapup:reviewer-testing e mimic-loop. Persiste em mcp-saga no projeto test-config:{repo}.
metadata:
  obsidian_identifier: scrapup:baseline-assessment
---

# Baseline Assessment

**Convencao de texto.** A regra ASCII-sem-acentos aplica-se a dois alvos:

1. **Edicao deste ficheiro** (`SKILL.md`): todo o corpo em PT-BR ASCII sem acentos, por consistencia com scripts e testes.
2. **Identificadores e slugs do JSON de saida**: chaves; valores enumerados (`status`, `category`, `category_effective`, `environment_state`, `gate_decision`, `action`); nomes de note; codigos de observacao/razao machine-readable (ex.: `coverage-summary-ausente`, `no-green-baseline-yet`). Estes sao contratos de interoperabilidade e **nunca** levam acentos.

**Excecao — texto livre para humanos:** os valores dos campos `observations` e `recommendations` do JSON, destinados a leitura humana, **podem conter acentos**. Os codigos/slugs que rotulam essas mensagens (quando existirem) seguem a regra ASCII do item 2.

Use esta skill como fonte unica de readiness do ecossistema scrapup. Orquestre as skills especializadas existentes (/scrapup:enable-docker-server, /scrapup:setup-node-env), descubra o ferramental do projeto, classifique-o em **cinco categorias estaveis** (`saudavel`, `legado-estavel`, `legado-docker-dependent`, `legado-critico`, `sem-infra`) mais o estado de triagem **`indefinido`** (ate `classify confirm`), e aplique o principio "nao regride o baseline" em verificacoes incrementais — em vez de impor gates absolutos que ou bloqueiam desenvolvedores em legados ou sao desligados por pragmatismo.

## Invocacao canonica

O dispatcher vive em `scripts/baseline-check.sh` (relativo a esta skill). O agente deve invocar com `bash` e caminho absoluto ou ancorado ao plugin:

```bash
BASELINE_PLUGIN_DIR="${BASELINE_PLUGIN_DIR:-$HOME/.claude/plugins/local/scrapup}"
bash "$BASELINE_PLUGIN_DIR/skills/utilitarios/baseline-assessment/scripts/baseline-check.sh" assess --project-path "$REPO_ROOT"
```

Substitua `assess` por `verify-diff`, `report`, `override` ou `classify` conforme o modo. `check-environment.sh` resolve `enable-docker.sh` / setup Node a partir de `BASELINE_PLUGIN_DIR` (default acima).

## Regras de negocio (RN)

As referencias `RN-NN` no corpo apontam para esta secao, que e a autoridade normativa unica da skill. Cada regra esta fundamentada no que os scripts em `scripts/` e os testes em `tests/` implementam; a coluna **Fonte** indica onde a regra esta ancorada no codigo (quando ha) ou que ela vive somente nesta especificacao. Regras nao verificaveis em codigo permanecem normativas para o agente e para a evolucao da skill.

| RN | Regra | Fonte |
|---|---|---|
| RN-01 | Existem exatamente **cinco categorias estaveis** (`saudavel`, `legado-estavel`, `legado-docker-dependent`, `legado-critico`, `sem-infra`) mais o estado de triagem `indefinido` durante a classificacao. Nenhuma outra categoria e valida. | `scripts/classify-project.sh:29` |
| RN-05 | Classificacao por **sondagem nao-invasiva** (dry-run do runner). Nao perguntar ao desenvolvedor quando os sinais sao suficientes; a sondagem automatica e sempre tentada primeiro. | `scripts/classify-project.sh:30` |
| RN-11 | **Segregacao de persistencia:** a skill escreve apenas no projeto saga `test-config:{repo}` e nunca toca `test-graph:{repo}`, propriedade de TDAD e do agente `scrapup:reviewer-testing`. | Especificacao (corpo) |
| RN-14 | **Nao instalar hooks Git** nem interferir nos comandos git do desenvolvedor. A invocacao da skill e sempre explicita pelo agente. | Especificacao (corpo) |
| RN-15 | Repositorios que **nao sao Node/TS** retornam `sem-infra` com observacao e **nunca bloqueiam** o fluxo. | Especificacao (corpo) |
| RN-16 | `verify-diff` **nunca executa a suite inteira**: apenas lint dos arquivos alterados, testes impactados e cobertura do diff. | Especificacao (corpo) |
| RN-17 | **Nao regride o baseline:** um patch so reprova se piorar o ultimo estado verde registrado; falhas pre-existentes nunca bloqueiam. | `scripts/lib/compare-baseline.sh:3`, `scripts/verify-diff.sh:4` |
| RN-19 | **Saidas JSON estruturadas e previsiveis**, consumidas por outras skills sem adaptacoes; todos os modos incluem `mode` no JSON e respeitam os contratos da secao **Contratos de saida**. | Especificacao (corpo) |
| RN-20 | **Nao reclassificar sem evidencia nova** (novo `manifest_hash`, presenca/ausencia de configs, runners novos). Hash inalterado com os mesmos configs nao dispara re-classificacao. | `scripts/classify-project.sh:32` |
| RN-21 | **Orquestrar, nao reimplementar** o ambiente: delegar a `/scrapup:enable-docker-server` e `/scrapup:setup-node-env`; nunca invocar `rdctl`, `nvm` ou `npm` diretamente. | `scripts/check-environment.sh:8` |
| RN-22 | `environment_state` (ambiente) e `category` (projeto) sao **eixos ortogonais e independentes**, persistidos como campos separados. | Especificacao (corpo) |
| RN-25 | `category_effective` e **ajustada quando `environment_state=partial`**, refletindo a capacidade real de execucao naquela invocacao. | `scripts/classify-project.sh:33`, `scripts/classify-project.sh:271` |
| RN-27 | `category_effective` e **sempre recomputada** na invocacao corrente a partir de `category` persistida + `environment_state` atual, e **nunca persistida** em nenhuma note. | `scripts/lib/effective-category.sh:2`, `scripts/report.sh:27-70`, `tests/integration/assess-core.bats:99` |
| RN-28 | Em **monorepo**, notes sao escopadas por workspace via prefixo de titulo `ws:{workspace-path}:<base>`. | Especificacao (corpo) |

> Regras presentes nos scripts mas nao citadas no corpo desta skill (RN-02, RN-06, RN-09, RN-10, RN-42) governam apenas detalhes internos de implementacao e ficam fora deste contrato normativo de skill.

## Principios operacionais

Aplique sempre:

- **Nao regrida o baseline:** reprove um patch apenas se ele piorar o ultimo estado verde registrado (RN-17). Nunca bloqueie por falhas pre-existentes.
- **Orquestre, nao reimplemente:** delegue o ambiente a /scrapup:enable-docker-server e /scrapup:setup-node-env. Consuma exit codes; nunca execute `rdctl`, `nvm` ou `npm` diretamente (RN-21).
- **Trate os eixos como ortogonais:** `environment_state` (ambiente) e `category` (projeto) sao independentes (RN-22). Um projeto saudavel pode estar com ambiente `blocked` temporariamente; um legado critico pode ter ambiente `ready`.
- **Mantenha a categoria efetiva transitoria:** recompute `category_effective` a cada invocacao a partir de `category` persistida + `environment_state` corrente. Nunca a persista (RN-27).
- **Segregue a persistencia:** escreva apenas em `test-config:{repo}`. Nunca toque `test-graph:{repo}` (propriedade de TDAD e do agente scrapup:reviewer-testing) (RN-11).
- **Degrade com resiliencia:** caia para cache local quando o saga estiver offline; migre automaticamente ao restabelecer a conexao.

## Testes unitarios e coverage (`assess`)

Escopo inicial: **apenas testes unitarios** (`scripts.test`). Scripts e2e (`test:e2e`, `test:e2e:cov`) ficam fora deste baseline.

### Scripts reconhecidos

| Script npm tipico | Slot detectado | Papel no `assess` |
|---|---|---|
| `test` | `scripts.test` | Suite unitaria principal |
| `test:cov` / `test:coverage` | `scripts.cov` | Quando presente, executado **em vez de** `test` numa unica passagem com coverage |
| `lint`, `build`, `typecheck` | slots homonimos | Descobertos; nao entram na suite do `assess` |

Padrao mais comum: `npm run test` + `npm run test:cov`. Com ambos definidos, o `assess` prefere `test:cov` para obter resultado dos testes **e** `coverage_global` numa so execucao.

### Execucao e parsing

Helper: `scripts/lib/run-unit-suite.sh`. Invocado por `assess-core.sh` quando `category_effective` permite execucao local (`saudavel`, `legado-estavel`, `legado-docker-dependent`).

1. **Jest / Vitest:** injeta reporter JSON (`--json --outputFile` / `--reporter=json`) e, se houver `scripts.cov`, flags de coverage (`--coverage` + `coverage-summary.json`).
2. **Runners nao estruturados** (mocha, turbo, npm scripts compostos): executa o comando detectado; outcome vem do exit code; observacao `runner-output-not-parsed` (sem lista de testes individuais).
3. **Overrides** nos slots `test` e `cov` substituem ou desativam (`disabled`) os comandos detectados.

### O que persiste no baseline

| Note | Quando | Campos de teste/coverage |
|---|---|---|
| `baseline-latest` | Sempre apos `assess` com ambiente nao-blocked | `tests_count`, `tests_previously_red`, `tests_previously_green`, `coverage_global`, `outcome` |
| `baseline-current` | Apenas quando suite **totalmente verde** (`status=green`) | `tests_count`, `coverage_global` (snapshot verde de referencia) |

`coverage_global` usa percentuais de `lines`, `branches`, `functions` e `statements` extraidos de `coverage-summary.json` (Jest/Vitest). Ausencia do ficheiro gera observacao `coverage-summary-ausente` e `coverage_global: null`.

Identificadores de teste no baseline seguem `{ficheiro-relativo}::{nome-do-teste}` (ex.: `src/payment.service.spec.ts::PaymentService calculates total`).

## Quando usar

- Pre-execucao de TF ou US no /scrapup:scrapup-forge (substitui a verificacao de readiness e descoberta de ferramental inline do forge)
- Ao fim de TF no /scrapup:mimic-loop (`verify-diff --scope=staged` quando o fluxo usa staged)
- Antes do push, na etapa de gate pre-push do forge (`verify-diff --scope=push`)
- Como leitura pura no agente `scrapup:reviewer-testing` para calibrar severidade de findings
- Diagnostico direto de readiness de um repositorio (`report`)

## Quando NAO usar

- Substituir execucao de testes unitarios durante TDAD ciclo VERIFY — TDAD invoca runner diretamente para comportamentos individuais. A skill entra no gate global.
- Repositorios que nao sao Node/TS — retornam `sem-infra` com observacao e nao bloqueiam (RN-15).

## Modos

| Modo | Tipo | Efeito | Consumidores tipicos |
|---|---|---|---|
| `assess` | Operacional | Readiness + descoberta + classificacao + execucao da suite (quando aplicavel) + persistencia de `baseline-current` (se verde) e `baseline-latest` (sempre) | /scrapup:scrapup-forge pre-execucao |
| `verify-diff` | Operacional | Gate incremental sobre diff (lint nos arquivos alterados, testes impactados, coverage do diff, comparacao com baselines). **Default `--scope=commit`** (diff `HEAD~1..HEAD`). Se nao houver baseline persistido e houver ficheiros no diff, executa **`assess` implicito** uma vez; ver secao **Contratos de saida**. | /scrapup:scrapup-forge pos-TF, /scrapup:mimic-loop fim de iteracao |
| `report` | Operacional (leitura pura) | Retorna estado persistido sem executar nada; recomputa `category_effective` na hora | `scrapup:reviewer-testing` pre-dispatch, TDAD checklist, consulta humana |
| `override` | Administrativo | Subcomandos `set` (registrar override com TTL 1-30 dias) e `remove` | Desenvolvedor via agente |
| `classify` | Administrativo | Subcomando `confirm` resolve `category=indefinido` com categoria escolhida pelo desenvolvedor | Desenvolvedor via agente |

Entry point unico: `scripts/baseline-check.sh <mode> [flags]`.

### Flags do dispatcher

| Modo | Flag | Tipo | Default | Obrigatoria | Descricao |
|---|---|---|---|---|---|
| `assess` | `--project-path` | string | `.` | nao | Caminho para o projeto alvo |
| `assess` | `--force` | flag | `false` | nao | Ignora cache e re-executa descoberta + suite |
| `assess` | `--timeout-seconds` | inteiro | `600` | nao | Timeout total da execucao da suite |
| `assess` | `--workspace` | string | auto-detect | nao | Em monorepo, escopar a um workspace especifico (ex.: `apps/api`) |
| `verify-diff` | `--project-path` | string | `.` | nao | Caminho para o projeto alvo |
| `verify-diff` | `--scope` | enum | `commit` | nao | Escopo do diff: `staged`, `commit`, `push` |
| `verify-diff` | `--base` | string | depende do scope | nao | Branch/ref base para `--scope=push` (override do default) |
| `verify-diff` | `--workspace` | string | auto-detect | nao | Em monorepo, escopar a um workspace especifico |
| `report` | `--project-path` | string | `.` | nao | Caminho para o projeto alvo |
| `report` | `--workspace` | string | auto-detect | nao | Em monorepo, escopar a um workspace especifico |
| `override set` | `--script` | enum | — | **sim** | Qual script sobrescrever: `test`, `lint`, `build`, `typecheck`, `cov` |
| `override set` | `--alternative` | string | — | **sim** | Comando alternativo; usar `disabled` para desativar |
| `override set` | `--ttl-days` | inteiro | `7` | nao | Dias ate expiracao (1-30) |
| `override set` | `--reason` | string | — | **sim** | Motivo textual registrado na note |
| `override remove` | `--script` | enum | — | **sim** | Qual script remover |
| `classify confirm` | `--category` | enum | — | **sim** | Categoria confirmada: `saudavel`, `legado-estavel`, `legado-docker-dependent`, `legado-critico`, `sem-infra` |
| `classify confirm` | `--reason` | string | — | **sim** | Motivo textual |
| todos | `--project-path` | string | `.` | nao | Raiz do repositorio para todos os modos |
| todos | `--help` | flag | — | nao | Imprime uso e sai |

**Semantica de `--scope` em `verify-diff`:**

| Scope | Range de diff | Uso tipico |
|---|---|---|
| `staged` | `git diff --cached --name-only` | Antes do commit |
| `commit` | `git diff --name-only HEAD~1 HEAD` | Apos commit autonomo do subagent, antes do push |
| `push` | `git diff --name-only <base>...HEAD`, onde `<base>` e `--base` se fornecido, senao `origin/development` (fallback `origin/main`) | Antes do `git push` ou na etapa de gate pre-push da /scrapup:scrapup-forge |

Em monorepo, `--workspace` default **auto-detect**; e possivel omitir `--workspace` e executar na raiz com observacao.

## Categorias operacionais

Cinco categorias **estaveis** (RN-01) mais **`indefinido`** durante triagem ate confirmacao humana.

| Categoria | Sinais tipicos | Comportamento em `verify-diff` |
|---|---|---|
| `saudavel` | Testes verdes locais, lint limpo, infra completa | Gate estrito: lint nos arquivos alterados, testes impactados, cobertura 100% do diff |
| `legado-estavel` | Testes rodam localmente (mesmo com flakies conhecidos), cobertura baixa historica | Gate incremental: lint + testes impactados; nao exige cobertura retroativa |
| `legado-docker-dependent` | Suite exige containers; sem Docker, falha por infra, nao logica | Condicional a Docker: gate completo quando Docker ready; reduzido quando Docker off |
| `legado-critico` | Testes nao rodam localmente (VPN, banco externo, servicos terceiros) | Apenas lint local; testes delegados ao CI remoto |
| `sem-infra` | Sem runner, sem linter, sem `package.json`, ou stack nao-Node | Gate e no-op com observacao; nao bloqueia |
| `indefinido` | Sinais contraditorios durante triagem | Nao classificada ate `classify confirm`; `verify-diff` bloqueado ou `warn` apos `assess` implicito com este estado |

RN-20 governa re-classificacao: acontece apenas quando `assess` detecta mudanca significativa nos sinais (novo `manifest_hash`, presenca/ausencia de configs, runners novos).

## Environment state

`environment_state` e ortogonal a `category` (RN-22). Registrado e consultado como campo independente.

| Estado | Significado | Baseline prossegue? |
|---|---|---|
| `ready` | Todos os pre-requisitos OK (Docker quando exigido, Node via nvm, NPM_TOKEN, `npm install`) | Sim, sem ajustes |
| `partial` | Alguns pre-requisitos falharam mas ainda e possivel executar lint e testes sem dependencia externa | Sim, com `category_effective` ajustada (RN-25) |
| `blocked` | Ambiente inviavel para qualquer execucao significativa | **Nao.** `assess` retorna status `blocked`; `verify-diff` retorna `warn` imediato |

`category_effective` e recomputada na invocacao corrente combinando `category` persistida com `environment_state` atual (RN-27). Exemplo: projeto `legado-docker-dependent` com Docker off vira `legado-critico` para aquela execucao — a categoria persistida nao muda.

## Contratos de saida

Saidas JSON estruturadas sao previsiveis e consumidas por outras skills sem adaptacoes (RN-19). Todos os modos incluem `mode` no JSON.

### Saida `assess`

Campos principais: `status`, `environment_state`, `environment_details`, `workspace`, `is_monorepo`, `category`, `category_effective`, `scripts`, `runner`, `linter`, `overrides_active`, `baseline_current`, `baseline_latest`, `observations`, `recommendations`.

| `status` | Significado | `category` tipico | `category_effective` |
|---|---|---|---|
| `cached` | Cache valido, nao re-executou descoberta nem suite | persistida | recomputada; **nao-nula** se categoria persistida e ambiente permitem |
| `green` | Suite passou completamente; `baseline-current` atualizado | persistida | **nao-nula** |
| `red-known` | Suite com falhas conhecidas; `baseline-latest` atualizado | persistida | **nao-nula** |
| `no-execution` | Categoria efetiva nao permite execucao local | persistida | **nao-nula** |
| `blocked` | `environment_state=blocked`; encerramento antes de classificar | **`null`** | **`null`** |
| `blocked-classification` | `category=indefinido`; requer `classify confirm` | `indefinido` | **`null`** |

Quando `status` e `blocked` ou `blocked-classification`, `scripts`, `runner`, `linter` e snapshots de baseline podem estar ausentes ou minimos.

Exemplo de payload `assess` com suite verde (identificadores ASCII; `recommendations` com texto humano acentuado):

```json
{
  "mode": "assess",
  "status": "green",
  "environment_state": "ready",
  "workspace": null,
  "is_monorepo": false,
  "category": "saudavel",
  "category_effective": "saudavel",
  "scripts": { "test": "jest", "cov": "jest --coverage" },
  "runner": "jest",
  "linter": "eslint",
  "overrides_active": [],
  "baseline_current": { "tests_count": 128, "coverage_global": { "lines": 92.4, "branches": 81.0, "functions": 88.7, "statements": 92.1 } },
  "baseline_latest": { "tests_count": 128, "outcome": "green" },
  "observations": ["coverage-summary-encontrado"],
  "recommendations": ["Suite verde; baseline-current atualizado como referência."]
}
```

### Saida `verify-diff`

Campos principais: `gate_decision`, `environment_state_current`, `category_effective`, `workspace`, `diff_scope`, `results` (lint, tests, coverage_diff), `baseline_comparison`, `reasons`, `observations`, `saga_offline`.

**Semantica de `gate_decision`:**

- `fail`: `tests_previously_green_now_red` nao-vazio **ou** `lint.new_errors = true` **ou** cobertura do diff abaixo da meta em projeto `saudavel`
- `warn`: `tests_previously_red_still_red` sem regressao nova; ou ambiente `blocked`; ou `flaky_observed` nao-vazio; ou `baseline_source = none`
- `pass`: tudo verde novo; nenhuma regressao sobre o baseline comparado

`baseline_source` em `baseline_comparison`: `baseline-current` se existe; senao `baseline-latest`; senao `none` (com `gate_decision: warn`).

**`verify-diff` sem baseline persistido:**

1. Se `environment_state` ja e `blocked` no check inicial: `gate_decision: warn` imediato (sem `assess` implicito).
2. Caso contrario, com ficheiros no diff e sem `baseline-latest`/`baseline-current`: executa **`assess` implicito** uma vez (mesmas flags `--project-path` / `--workspace`). Se o implicito devolver `blocked`, `warn` com razao `implicit-assess-environment-blocked`. Se devolver `blocked-classification`, `warn` com `classification-indefinido-after-implicit-assess`.
3. Se ainda nao houver baseline (ex.: `BASELINE_VERIFY_DIFF_SKIP_IMPLICIT_ASSESS=1` em diagnostico): `warn` com `no-green-baseline-yet`.
4. Se `assess` implicito classificar `sem-infra`, o fluxo prossegue com gate calibrado (nao bloqueia por RN-15).

### Saida `report`

Campos principais: `repo`, `workspace`, `is_monorepo`, `last_assessed_at`, `environment_state`, `category`, `scripts`, `runner`, `linter`, `overrides_active`, `baseline_current`, `baseline_latest`, `recent_runs_summary`, `saga_offline`.

`report` nunca executa nada; retorna `recent_runs_summary` agregando `metrics:run` dos ultimos 7 dias. Campo `saga_offline` e **sinonimo operacional** de `pending_saga_sync` no cache local (`true` = existem escritas ainda nao sincronizadas com `mcp-saga`).

**Contrato de `report` para repo nunca avaliado** (sem qualquer note em `test-config:{repo}` nem cache local): `report` retorna exit 0 com `mode: "report"` e os campos de estado em `null` / vazios:

- `last_assessed_at`, `environment_state`, `category`, `scripts`, `runner`, `linter`, `baseline_current`, `baseline_latest`: **`null`**
- `overrides_active`, `recent_runs_summary`: **`[]`** (lista vazia)
- `repo`, `workspace`, `is_monorepo`, `saga_offline`: preenchidos a partir da inspecao corrente do repositorio (nao dependem de avaliacao previa)
- `observations`: inclui `never-assessed`

O consumidor distingue "nunca avaliado" de "avaliado e blocked" pela combinacao `category: null` + observacao `never-assessed` (em vez de `status` de `assess`, que `report` nao emite).

### Saidas administrativas

**`override`:** `action` (`set`|`remove`), `script`, `override_active`, `alternative`, `expires_at`, `reason`.

**`classify`:** `action` (`confirm`), `category_confirmed`, `reason`, `confirmed_at`.

### Exit codes do dispatcher

Consumidores devem usar exit code + `status`/`gate_decision` combinados, nunca apenas um dos dois.

| Modo | Exit 0 | Exit 1 | Exit 2 | Exit 3 |
|---|---|---|---|---|
| `assess` | `status` em `{cached, green, red-known, no-execution}` | `status` em `{blocked, blocked-classification}` | — | Erro nao tratavel |
| `verify-diff` | `gate_decision = pass` | `gate_decision = fail` | `gate_decision = warn` | Erro nao tratavel |
| `report` | Leitura bem-sucedida | — | — | Erro nao tratavel |
| `override set`/`remove` | Operacao registrada | Operacao rejeitada por validacao | — | Erro nao tratavel |
| `classify confirm` | Categoria registrada | Operacao rejeitada | — | Erro nao tratavel |

## Persistencia no saga

Projeto: `test-config:{repo}` — onde `{repo}` e o nome do origin remote ou, em fallback, o nome do diretorio.

Unica skill que escreve neste projeto e a /scrapup:baseline-assessment; outras apenas leem.

Em monorepo, notes sao escopadas por workspace via prefixo de titulo `ws:{workspace-path}:<base>` (RN-28). Detector decide escopo no momento da leitura/escrita com base em `workspaces` do `package.json`, `nx.json`, `turbo.json` ou `pnpm-workspace.yaml`.

| Note title | Proposito |
|---|---|
| `environment-state` | Ultimo estado do ambiente avaliado |
| `test-scripts` | Scripts descobertos + `manifest_hash` |
| `baseline-category` | Categoria persistida (inclui `classified_by = auto` ou `user-confirmed`) |
| `baseline-current` | Ultimo estado **verde** registrado (opcional — ausente em projetos que nunca tiveram suite totalmente verde) |
| `baseline-latest` | Ultima execucao de `assess` (sempre escrita); inclui `tests_previously_red` e `tests_previously_green` |
| `baseline-overrides` | Overrides manuais com TTL |
| `metrics:run:{timestamp}` | Historico de execucoes para calibracao futura |
| `category-confirmation` | Classificacao confirmada pelo desenvolvedor quando `indefinido` |

Todas as notes incluem `schema_version` (inteiro; atual `1`); schema desatualizado causa descarte e re-execucao de `assess`.

Fallback local: `~/.claude/plugins/local/scrapup/cache/baseline/{repo-hash}.json`, com lock `.lock` (timeout 30s) para evitar corrida entre subagents. Cache e espelho de escritas bem-sucedidas; migracao automatica quando saga volta online.

`manifest_hash` e SHA-256 sobre conteudo canonico de `package.json` (bloco `scripts` + `devDependencies`), configs relevantes (`nx.json`, `turbo.json`, `pnpm-workspace.yaml`, configs de runner e linter) e `.nvmrc`. Em monorepo, calculado por workspace — configs de raiz afetam todos os workspaces.

## Integracoes no ecossistema scrapup

| Artefacto | Relacao | Chamada tipica |
|---|---|---|
| Skill /scrapup:scrapup-forge | Consumidora principal. Verificacao de readiness e descoberta de ferramental do forge substituidas por invocacao unica. | `bash .../scripts/baseline-check.sh assess` no pre-execucao; `verify-diff --scope=commit` ao fim de cada TF; `verify-diff --scope=push` antes do push |
| Skill /scrapup:test-driven-agentic-development | Consumidora (leitura). Checklist final referencia `baseline-current` via `report`. | `bash .../scripts/baseline-check.sh report` antes do SUBMIT |
| Skill /scrapup:mimic-loop | Consumidora. Invoca ao fim de iteracao com alteracoes significativas. | `bash .../scripts/baseline-check.sh verify-diff --scope=staged` |
| Agente `scrapup:reviewer-testing` | Consumidor (leitura). Calibra severidade por categoria e overrides ativos. Nao escreve em `test-config:{repo}`. | `bash .../scripts/baseline-check.sh report` pre-dispatch |
| Skill /scrapup:enable-docker-server | Orquestrada. `check-environment.sh` delega verificacao/start do Docker. | `enable-docker.sh start` via check-environment |
| Skill /scrapup:setup-node-env | Orquestrada. Detecta versao Node, nvm install/use, NPM_TOKEN, `npm install`. | Scripts canonicos via check-environment |
| Skill /scrapup:saga-session | Fonte canonica de convencoes de persistencia (nomes de projeto, note types, lifecycle). Nao redefinida aqui. | — |

## Diagramas

Codigo PlantUML (fonte da verdade) em `diagrams/` relativo a esta skill:

- C4 Nivel 2 (contexto e containers): `diagrams/baseline-c4-container.puml`
- C4 Nivel 3 (componentes internos): `diagrams/baseline-c4-component.puml`
- Sequencia `assess` com sucesso: `diagrams/baseline-seq-assess-success.puml`
- Sequencia `verify-diff` com regressao: `diagrams/baseline-seq-verify-diff-regression.puml`

## Anti-patterns

- **Reimplementar logica de /scrapup:enable-docker-server ou /scrapup:setup-node-env** (ex.: chamar `rdctl` direto, rodar `nvm install` inline). Viola RN-21. Sempre delegar.
- **Escrever em `test-graph:{repo}`** (propriedade de TDAD e do agente `scrapup:reviewer-testing`). Viola RN-11.
- **Persistir `category_effective`** em qualquer note. Viola RN-27. Sempre recomputada.
- **Persistir `NPM_TOKEN`** (ou qualquer secret) no saga ou cache local. Apenas `npm_token_present: true|false`.
- **Reclassificar sem evidencia nova** (hash inalterado, mesmos configs). Viola RN-20.
- **Instalar hooks Git no MVP** ou interferir em comandos git do desenvolvedor. Viola RN-14. Invocacao e sempre explicita pelo agente.
- **Executar suite inteira em `verify-diff`** como atalho. Viola RN-16. Apenas lint dos arquivos alterados + testes impactados + cobertura do diff.
- **Falhar `verify-diff` por falha pre-existente**. Viola RN-17. Apenas regressao introduzida bloqueia.
- **Perguntar ao desenvolvedor quando os sinais sao suficientes**. Viola RN-05. Sondagem automatica sempre tentada primeiro.
- **Retornar `category_effective` diferente de `null` com `status=blocked-classification`**. Contrato exige `null` nesse caso.
- **Ecoar `override set --alternative` ou motivos longos para logs publicos** sem validar origem; tratar como dado nao confiavel.

## Checklist de verificacao

Ao evoluir a skill ou scripts internos, validar:

- [ ] `environment_state` e `category` persistidos como campos independentes; `category_effective` nunca persistida
- [ ] Fluxo de ambiente sempre delegado a /scrapup:enable-docker-server e /scrapup:setup-node-env
- [ ] Todas as saidas JSON validas contra os contratos desta secao **Contratos de saida**
- [ ] Exit codes coerentes com a tabela **Exit codes do dispatcher** nesta skill
- [ ] Notes escritas apenas em `test-config:{repo}`
- [ ] Monorepo escopado via prefixo `ws:{workspace-path}:` quando detectado
- [ ] `baseline-current` apenas com suite completamente verde; `baseline-latest` sempre apos `assess` bem-sucedido
- [ ] `manifest_hash` determinista para a mesma entrada
- [ ] Fallback para cache local nao bloqueia operacao quando saga offline
- [ ] Overrides com TTL obrigatorio; renovacao explicita
- [ ] `classify confirm` resolve `indefinido` e atualiza `classified_by = user-confirmed`
