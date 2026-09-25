# Baseline Persistence via mcp-saga

Protocolo de persistencia e consulta de padroes de homogeneidade usando o MCP server `mcp-saga`. Este arquivo define templates, schema de tags, e fluxos operacionais.

---

## Modelo de dados no mcp-saga

### Projeto (um por repositorio)

```
project_create:
  name: "homogeneity:{repo-name}"
  description: "Baseline de homogeneidade do repositorio {repo-name}"
  tags: ["homogeneity", "baseline"]
```

Exemplos: `homogeneity:checkout-api`, `homogeneity:payment-service`, `homogeneity:event-broker`.

### Schema de tags

| Tag | Uso |
|-----|-----|
| `homogeneity` | Presente em TUDO (projeto, notes). Filtro primario. |
| `baseline` | Identifica notes de padroes (vs notas operacionais). |
| `D{n}` | Dimensao: `D1`, `D2`, ..., `D10`. Filtro por dimensao. |
| `meta` | Nota indice do repositorio (apenas na meta-note). |
| `{dimension-slug}` | Slug da dimensao: `naming-language`, `naming-patterns`, `directory-org`, `object-shape`, `api-contract`, `tooling`, `error-handling`, `config-init`, `code-org`, `baseline-integrity`. |

### Notes: tipos e quando usar

| Tipo de note | Quando |
|---|---|
| `technical` | Registro de padrao baseline (cada dimensao) e meta-note |

Todos os registros de baseline usam `note_type: "technical"` com `related_entity_type: "project"`.

---

## Template: Meta-note [META]

A meta-note e o ponto de entrada. O agente le esta nota primeiro para decidir se precisa re-analisar.

```
note_save:
  title: "[META] {repo-name}"
  content: (template abaixo)
  note_type: "technical"
  related_entity_type: "project"
  related_entity_id: {project_id}
  tags: ["homogeneity", "baseline", "meta"]
```

### Content da meta-note

```markdown
## Baseline Overview

**Repository:** {repo-name}
**Last analysis:** {ISO timestamp}
**Commit SHA:** {head_sha}
**Branch:** {branch_name}
**Files analyzed:** {n}/{total} ({pct}%)
**Analysis type:** first-scan | incremental

### Hard Patterns (tooling-enforced)

| Config file | Key patterns |
|-------------|-------------|
| `.eslintrc` | singleQuote, semi, ... |
| `tsconfig.json` | strict: true, paths: ... |
| `.prettierrc` | tabWidth: 2, ... |

### Dimensions

| # | Dimension | Confidence | Status |
|---|-----------|------------|--------|
| D1 | Naming Language | 97% | registered |
| D2 | Naming Patterns | 95% | registered |
| D3 | Directory Org | 92% | registered |
| D4 | Object Shape | 82% | below threshold |
| D5 | API Contract | 94% | registered |
| D6 | Tooling | 100% | registered |
| D7 | Error Handling | 88% | below threshold |
| D8 | Config & Init | 91% | registered |
| D9 | Code Org | 93% | registered |
| D10 | Baseline Integrity | 96% | registered |

### Quality Gaps (below threshold - NAO registradas como notes)

- D4 (82%): Mix de class-validator e zod — sem padrao dominante
- D7 (88%): Mix de HttpException e Error generico — nenhum com 90%+
```

---

## Template: Note de dimensao

Uma note por dimensao com padrao >=90%. Dimensoes abaixo do threshold ficam apenas na meta-note.

```
note_save:
  title: "[D{n}] {Dimension Name}"
  content: (template abaixo)
  note_type: "technical"
  related_entity_type: "project"
  related_entity_id: {project_id}
  tags: ["homogeneity", "baseline", "D{n}", "{dimension-slug}"]
```

### Content da note de dimensao

```markdown
## Baseline: {Dimension Name}

**Commit SHA:** {head_sha}
**Analyzed:** {ISO timestamp}
**Coverage:** {analyzed}/{total} files ({pct}%)

### Patterns

| Pattern | Value | Confidence | Sample |
|---------|-------|------------|--------|
| {pattern_name} | {pattern_value} | {pct}% | `src/modules/x/x.service.ts` |
| {pattern_name} | {pattern_value} | {pct}% | `src/modules/y/y.controller.ts` |

### Reference files

| File | SHA |
|------|-----|
| `src/modules/checkout/checkout.service.ts` | {git_hash_object} |
| `src/modules/payment/payment.service.ts` | {git_hash_object} |
| `src/modules/billing/billing.service.ts` | {git_hash_object} |
```

### Exemplos concretos por dimensao

**[D1] Naming Language:**

| Pattern | Value | Confidence | Sample |
|---------|-------|------------|--------|
| Code language | English | 97% | `src/modules/checkout/checkout.service.ts` |
| DB columns | snake_case English | 100% | `prisma/schema.prisma` |
| Domain terms | English (beneficiary, plan, provider) | 95% | `src/modules/eligibility/eligibility.entity.ts` |

**[D2] Naming Patterns:**

| Pattern | Value | Confidence | Sample |
|---------|-------|------------|--------|
| Property casing | camelCase | 99% | `src/modules/checkout/dtos/create-checkout.dto.ts` |
| Class casing | PascalCase | 100% | `src/modules/checkout/checkout.service.ts` |
| Class suffix | Service, Controller, Repository | 98% | `src/modules/payment/payment.service.ts` |
| Interface prefix | none (no I prefix) | 96% | `src/modules/checkout/ports/checkout-repository.port.ts` |
| Enum values | UPPER_SNAKE_CASE | 94% | `src/shared/enums/payment-status.enum.ts` |
| File naming | kebab-case.{type}.ts | 97% | `src/modules/checkout/checkout.service.ts` |

**[D6] Tooling:**

| Pattern | Value | Confidence | Sample |
|---------|-------|------------|--------|
| Logger | Pino (structured JSON) | 100% | `src/main.ts` |
| Broker | amqplib wrapper | 100% | `src/modules/events/event-publisher.service.ts` |
| Validation | class-validator + class-transformer | 95% | `src/modules/checkout/dtos/create-checkout.dto.ts` |
| ORM | Prisma | 100% | `prisma/schema.prisma` |
| HTTP client | axios (shared instance) | 92% | `src/shared/http/http.service.ts` |

---

## Fluxo: First Scan

Executar quando `project_list` nao encontra projeto `homogeneity:{repo}`.

```
1. project_create("homogeneity:{repo}", tags=["homogeneity", "baseline"])
   → guardar project_id

2. Identificar hard patterns:
   - Ler .eslintrc / .prettierrc / tsconfig.json / biome.json / editorconfig
   - Registrar regras como hard patterns na meta-note

3. Para cada dimensao (D1-D10):
   a. Escanear 90%+ dos arquivos relevantes:
      - D1/D2/D9: todos os .ts/.js (exceto node_modules, dist, build)
      - D3: estrutura de diretorios de src/
      - D4: arquivos de DTO, entity, interface
      - D5: controllers/routes e seus responses
      - D6: imports de libs (logger, broker, http, validation, orm)
      - D7: blocos catch, throw, exception classes
      - D8: uso de process.env, ConfigService, .env files
      - D10: fluxos completos (controller→service→repository)
   b. Calcular confidence: % de arquivos que seguem o padrao dominante
   c. Se confidence >= 90%:
      - note_save com template de dimensao
      - Incluir file SHAs: git hash-object {file} para cada reference file
   d. Se confidence < 90%:
      - Registrar apenas na meta-note como "below threshold"

4. note_save da meta-note [META]:
   - Commit SHA: git rev-parse HEAD
   - Listar todas as dimensoes com status (registered / below threshold)
   - Incluir hard patterns
   - Incluir quality gaps
```

---

## Fluxo: Incremental

Executar quando projeto `homogeneity:{repo}` ja existe no saga.

```
1. project_list → encontrar project_id para "homogeneity:{repo}"

2. note_list(related_entity_type="project", related_entity_id={id}, tag="meta")
   → ler meta-note [META]
   → extrair commit SHA da ultima analise

3. Comparar com HEAD:
   - git rev-parse HEAD → current_sha
   - Se current_sha == meta_sha: DONE — usar padroes em cache

4. Se SHAs diferem:
   a. git diff --name-only {meta_sha}..HEAD → changed_files
   b. Filtrar changed_files por tipo relevante (.ts, .js, config files)

5. Verificar hard patterns:
   - Se .eslintrc / .prettierrc / tsconfig.json mudou:
     → Re-ler configs, atualizar hard patterns na meta-note

6. Para cada dimensao com note registrada:
   a. Verificar se algum changed_file e relevante para a dimensao
   b. Se sim:
      - Re-analisar os changed_files no contexto da dimensao
      - Verificar se o padrao se mantém
      - Se mantém: atualizar apenas SHA na note
      - Se mudou (evolucao consistente em 90%+): atualizar padrao na note
      - Se mudou (drift em <90%): manter padrao anterior, registrar drift como observacao
   c. Se nao: pular (padrao intacto)

7. Para dimensoes "below threshold" na meta:
   - Se changed_files incluem arquivos relevantes:
     → Re-avaliar — talvez agora tenha 90%+
     → Se sim: criar note de dimensao (promoção)

8. Arquivos novos (nao existiam na analise anterior):
   - Incluir na analise para expandir cobertura
   - Atualizar coverage na meta-note

9. Atualizar meta-note [META]:
   - Novo commit SHA
   - Novo timestamp
   - Atualizar coverage
   - Atualizar status das dimensoes se necessario
```

---

## Fluxo: Consulta (durante critique)

Executar no inicio de qualquer critique de homogeneidade.

```
1. project_list → buscar "homogeneity:{repo}"

2. Se nao encontrado:
   → Executar First Scan (bloqueia ate concluir)
   → Prosseguir com padroes recem-registrados

3. Se encontrado:
   a. note_list(related_entity_type="project", related_entity_id={id}, tag="meta")
      → Ler meta-note
   b. Verificar SHA:
      - Se igual ao HEAD: usar cache
      - Se diferente: executar Incremental
   c. note_list(related_entity_type="project", related_entity_id={id}, tag="baseline")
      → Carregar todas as notes de dimensao
   d. Montar mapa de baseline para o critique:
      {D1: {patterns: [...], confidence: 97%}, D2: {...}, ...}

4. Aplicar baseline nas dimensoes do checklist
```

---

## Comandos git uteis

| Operacao | Comando |
|----------|---------|
| SHA do HEAD | `git rev-parse HEAD` |
| SHA de arquivo | `git hash-object {file}` |
| Branch atual | `git rev-parse --abbrev-ref HEAD` |
| Arquivos alterados entre SHAs | `git diff --name-only {old_sha}..{new_sha}` |
| Total de arquivos .ts | `find src -name '*.ts' \| wc -l` (excluir node_modules, dist) |
| Listar arquivos .ts | `find src -name '*.ts' -not -path '*/node_modules/*' -not -path '*/dist/*'` |

---

## Regras de persistencia

1. **Apenas padroes validos** — NUNCA registrar anti-patterns, code smells ou desvios
2. **90%+ para registro** — abaixo do threshold, registrar apenas na meta-note como `below threshold`
3. **Per-repositorio** — cada repo tem seu proprio projeto saga; nao compartilhar baseline entre repos
4. **SHA tracking obrigatorio** — commit SHA na meta-note, file SHAs nas reference files
5. **Upsert por id** — ao atualizar, usar `note_save` com `id` da note existente (nao criar duplicatas)
6. **Evolucao consistente** — se 90%+ dos modulos migraram para novo padrao, atualizar baseline (nao resistir)
7. **Quality gaps** — dimensoes com padroes ruins abaixo de 90% ficam como `below threshold / quality gap` na meta-note
