# Template: Backlog de Execucao Atomica — `tasks.md` e `single-tasks.md`

## Contexto de Uso

Este template guia a criacao dos artefatos de execucao atomica do SDD. Existem **dois fluxos**:

| Ficheiro | Fluxo | Pre-requisitos |
|---|---|---|
| **`tasks.md`** | **Completo** — Fase 3 apos `plan.md` | `spec.md` e `plan.md` **aprovados** |
| **`single-tasks.md`** | **Incremental** — baixo impacto, sem spec/plan | **Nenhum** `spec.md` / `plan.md` obrigatorio; **maximo 5 Tarefas** (`#### TF-`) |

O foco continua a ser **execucao atomica**: Tarefas implementaveis e testaveis isoladamente.

**Onde gravar:**

- Fluxo completo: `/docs/specs/<nome-da-feature>/tasks.md`
- Incremental: `/docs/specs/<contexto>/single-tasks.md` (pasta alinhada a feature ou incremento)

Ambos sao consumidos pela skill **expert-clickup** para sincronizar com o ClickUp.

---

## `tasks.md` — fluxo completo

**Pre-requisitos obrigatorios:** `spec.md` e `plan.md` aprovadas pelo utilizador.

O foco e fatiar o **`plan.md`** em User Stories compostas por Tarefas. Ver seccoes **Hierarquia** e **Template** abaixo; **diagramas por US sao obrigatorios** (C4 N2 + sequencia no minimo, conforme skill blueprint).

---

## `single-tasks.md` — fluxo incremental

Use quando a mudanca for de **baixo impacto em codigo**: por exemplo adicionar um teste, alterar uma constante, ajustes em **poucos trechos** e **poucos ficheiros**, sem nova arquitetura nem contrato amplo.

**Regras inegociaveis:**

1. **No maximo 5 Tarefas** no ficheiro. Se precisar de mais, **nao** use este fluxo — produza `spec.md`, `plan.md` e `tasks.md`.
2. **Sem** `spec.md` e **sem** `plan.md`: o contrato e o proprio `single-tasks.md` aprovado.
3. **Mesmo formato de marcacoes** que `tasks.md`: `## US-XX` (ou equivalente), `#### TF-XX-YY`, campos dos templates de User Story e Tarefa.
4. **Toda a especificacao** necessaria (contexto, ficheiros, criterios, DoD, riscos locais) deve estar **nas Tarefas**; a User Story pode ser **breve** (narrativa resumida).
5. **Diagramas PlantUML:** opcionais; usar so se evitarem ambiguidade.

**Pre-Requisitos Check (incremental):** nao ha `plan.md` — validar apenas que cada TF lista ficheiros/areas tocadas e criterios de aceitacao testaveis.

---

## Hierarquia ClickUp (Scrum)

| Nivel | Responsavel | Descricao |
|---|---|---|
| **Epico** | Time de PM | Recebido pelo time tecnico — contexto macro do que deve ser feito. O time tecnico **nao cria** epicos. |
| **User Story** | Time tecnico (refinamento) | Entregavel de valor ao produto. Agrupa Tarefas relacionadas. Cadastrada no refinamento tecnico. |
| **Tarefa** | Time tecnico (detalhamento) | Unidade atomica de trabalho com todos os detalhes para execucao e validacao pelo desenvolvedor. |

O `tasks.md` ou `single-tasks.md` organiza o backlog em **User Stories** com suas respectivas **Tarefas**. Cada User Story representa uma entrega de valor e contem Tarefas atomicas sequenciadas.

## Restricoes da Fase 3

- **PROIBIDO** gerar apenas listas de checkboxes (ex: "- [ ] Fazer API") — o fatiamento em Tarefas descritivas e inegociavel
- **PROIBIDO** incluir codigo TypeScript/JavaScript no artefato de backlog (`tasks.md` / `single-tasks.md`) — ficheiro de planejamento apenas
- **PROIBIDO** gerar Tarefas que incluam mais de um dominio de responsabilidade
- **NUNCA** junte "Criar Tabela no DB" com "Criar Consumidor RabbitMQ" na mesma Tarefa
- **PROIBIDO** em `single-tasks.md`: mais de **5** blocos `#### TF-`
- **PROIBIDO** atribuir IDs `US-XX` manualmente. Para **cada** User Story nova, invocar `bash ~/.claude/plugins/local/scrapup/skills/documentacao/blueprint/getNextUserStoryId.sh` e usar o numero retornado (com padding minimo 2 digitos). Os exemplos `US-01`, `US-02`, `US-03` deste template sao **placeholders ilustrativos**; em uso real os IDs vem do script e podem nao comecar em `01`. Detalhes na secao **Identificadores Sequenciais de User Story (Global)** da `SKILL.md`

## Principios de Fatiamento

1. **Atomicidade:** Cada Tarefa deve ser implementavel e testavel isoladamente. Se uma Tarefa precisa de outra para ser testada, elas estao mal fatiadas
2. **Sequenciamento topologico (`tasks.md` apenas):** Respeite dependencias — infra/schemas antes de conectores, conectores antes de usecases, usecases antes de controllers. No incremental, ordene TF pela menor dependencia pratica
3. **Resiliencia embutida:** Se a mudanca tocar filas ou HTTP, a Tarefa DEVE especificar try/catch, retries ou circuit breakers quando aplicavel (no incremental, dentro do texto da TF)

## Pre-Requisitos Check (`tasks.md` apenas)

Antes de gerar o backlog da Fase 3 completa, verifique no `plan.md`:

1. Os schemas/models de banco estao detalhados?
2. Os DTOs de entrada e saida estao definidos?
3. O tratamento de erros por componente esta mapeado?

Se faltar informacao sobre como erros devem ser tratados, avise o utilizador antes de gerar o backlog.

## Ordem Padrao de Sequenciamento (`tasks.md`)

```
1. Schemas de Banco / Entities / Models
2. DTOs de Validacao (Zod/class-validator)
3. Consumers de Fila (RabbitMQ)
4. Workers / Sync Jobs
5. Repositories / Data Access Layer
6. UseCases / Services (regras de negocio)
7. Controllers / Endpoints HTTP
8. Integracao e Testes End-to-End
```

Adapte a ordem conforme o contexto, mas mantenha a regra: **dependencias antes de dependentes**.

---

## Template

```markdown
# Backlog de Execucao: [Nome da Funcionalidade]

## Epico de Referencia

**Epico:** [E-XX] [Nome do Epico — conforme cadastrado pelo time de PM no ClickUp]

---

## Rastreabilidade

| Regra/Requisito (spec.md) | Decisao Arquitetural (plan.md) | User Story | Tarefas |
|---|---|---|---|
| RN-XX | [Decisao que implementa a regra] | US-XX | TF-XX-01, TF-XX-02 |
| RN-XX | [Decisao que implementa a regra] | US-XX | TF-XX-03 |

---

## Visao Geral das User Stories

| # | User Story | Entrega de Valor |
|---|---|---|
| US-01 | [Nome da User Story] | [Valor entregue ao produto] |
| US-02 | [Nome da User Story] | [Valor entregue ao produto] |
| US-03 | [Nome da User Story] | [Valor entregue ao produto] |

---

## US-01: [Nome da User Story — Entregavel de Valor]

[Preencher com o template completo de User Story — ver templates/user-story-template.md]
[O template de User Story ja inclui: narrativa de valor, criterios de aceitacao, sequenciamento de tarefas e blocos de tarefas]

---

## US-02: [Nome da User Story — Entregavel de Valor]

[Repetir estrutura completa usando templates/user-story-template.md]

---

[Repetir para cada User Story ate fechar o escopo do plan.md]
```

*Nota para `single-tasks.md`:* pode haver **uma** User Story e ate **5** blocos `#### TF-`; a seccao **Rastreabilidade** pode referir apenas "demanda incremental" ou ticket externo, sem colunas spec/plan.

*Nota sobre Ralph Tasks (RT):* TFs complexas (3+ ficheiros, 4+ criterios DoD, >2h) podem incluir secao 4.7 (Decomposicao Iterativa) com Ralph Tasks. RTs vivem **exclusivamente no saga** (`mcp-saga` via `subtask_create`) — nunca sobem ao ClickUp. Ver `templates/task-template.md` secao 4.7 para formato e criterios de uso.

---

## Exemplos de Bom Fatiamento

**Cenario:** Consumer RabbitMQ que sincroniza dados do sistema legado para MongoDB.

**User Story:** US-01 — Sincronizacao automatica de dados do sistema legado
> Eu como sistema de vendas, eu quero receber dados atualizados do legado via fila, para que as consultas retornem informacoes em tempo real.

| # | Tarefa | Escopo | Testavel Isoladamente? |
|---|---|---|---|
| TF-01-01 | Criar schema Mongoose e indices | Persistencia | Sim — teste de schema |
| TF-01-02 | Criar DTOs de validacao do payload da fila | Validacao | Sim — teste unitario |
| TF-01-03 | Implementar consumer RabbitMQ | Conectividade | Sim — teste com mock do broker |
| TF-01-04 | Implementar logica de transformacao e persistencia | Negocio | Sim — teste unitario do service |
| TF-01-05 | Implementar tratamento de erros e DLQ | Resiliencia | Sim — teste de cenarios de falha |
| TF-01-06 | Testes de integracao end-to-end | Integracao | Sim — teste com broker real |

**Anti-padrao:** Uma unica Tarefa "Implementar consumer que recebe mensagem, valida, transforma e persiste" — isso mistura 4 dominios de responsabilidade.

## Exemplos de Mau Fatiamento

| Tarefa | Problema |
|---|---|
| "Fazer a API toda" | Escopo gigante, impossivel testar atomicamente |
| "Criar banco e consumer" | Mistura persistencia com conectividade |
| "- [ ] Implementar feature X" | Checkbox generico sem especificacao |
| "Implementar e testar endpoint" | Mistura implementacao com QA |

## Quando Simplificar

Se a feature se resume a 1 endpoint, 1 model, sem integracao assincrona:

- Use 1 User Story com 1-2 Tarefas no maximo
- NAO force fatiamento em 6+ tarefas por burocracia
- Aplique o principio Ironclad: solidez sobre burocracia

Indicadores de que o fatiamento esta excessivo:
- Tarefas com menos de 1 Story Point de complexidade isolada
- Mais de 50% das tarefas sao "criar DTO" ou "criar schema" sem logica
- O dev consegue implementar tudo em menos de 2 horas
