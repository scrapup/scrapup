# Template: Tarefa Tecnica

## Contexto de Uso

Este template define o formato obrigatorio para cada **Tarefa** gerada na Fase 3 (`tasks.md` ou `single-tasks.md`) do Spec-Driven Development.
As Tarefas sao o **ultimo nivel de planejamento** da hierarquia Scrum (Epico > User Story > Tarefa) e devem ser **tecnicas, prescritivas e inambiguas** — serao consumidas por agentes de IA (scrapup-forge, subagents mimic-loop) e por engenheiros para implementacao direta.

**`single-tasks.md` (incremental):** cada Tarefa deve ser **auto-contida**: incluir no corpo da TF todo o contexto, ficheiros/caminhos tocados, criterios de aceitacao e DoD necessarios para implementar **sem** consultar `spec.md` ou `plan.md` (porque nao existem neste fluxo).

### Hierarquia

| Nivel | Responsavel | Onde vive | Descricao |
|---|---|---|---|
| **Epico** | Time de PM | ClickUp | Contexto macro recebido pelo time tecnico |
| **User Story** | Time tecnico | ClickUp + tasks.md | Entregavel de valor ao produto (cadastrada no refinamento) |
| **Tarefa (TF)** | Time tecnico | ClickUp + tasks.md | Unidade atomica de trabalho — **este template** |
| **RT (iteracao)** | Agente (execucao) | saga (mcp-saga) | Passo operacional dentro de uma TF — **secao 4.7, opcional** |

**RT (iteracoes)** sao o nivel de execucao iterativa (mimic-loop). Existem **apenas no saga** — nunca sobem ao ClickUp. Sao opcionais: TFs simples executam sem decomposicao RT.

## Restricoes

- **NUNCA** gere especificacoes genericas — use nomes reais de metodos, tabelas e filas quando o contexto for fornecido
- **NUNCA** sugira Webhooks HTTP para comunicacao interna sem questionar se Event-Driven via RabbitMQ nao seria mais adequado
- Se dados de configuracao faltarem, insira placeholders claros como `[INSERIR_ROUTING_KEY]` e avise o usuario
- Cada Tarefa deve cobrir **um unico dominio de responsabilidade**
- **NUNCA** invente o ID `TF-XX-YY`. O `XX` **herda exatamente** o ID da User Story pai (vindo de `getNextUserStoryId.sh` — gerador sequencial global) e o `YY` e sequencial **local** dentro da US (`01`, `02`, `03`...). Ver secao **Identificadores Sequenciais de User Story (Global)** da `SKILL.md`

---

## Template

````markdown
### [TF-XX-YY] [Sistema] Titulo Claro e Objetivo da Tarefa

**User Story:** [US-XX] Nome da User Story
**Epico:** [E-XX] Nome do Epico (referencia PM)
**Sistema:** [Nome exato do repositorio]
**Prioridade:** [P0 | P1 | P2]

#### 1. Descricao e Objetivo

> **Eu como** [Ator/Sistema],
> **Eu quero** [Acao Tecnica especifica],
> **Para que** [Contribuicao para o valor da User Story].

*Contexto Arquitetural:* [Explique o cenario macro — ex: "Estamos migrando para Event-Driven para evitar chamadas HTTP sincronas entre o sistema X e Y."]

#### 2. Especificacao Tecnica

**2.1 Pontos de Interceptacao**

Liste os exatos Services, Controllers, UseCases ou Repositories que devem ser criados ou alterados:
- `src/modules/[modulo]/[arquivo].ts` — [descricao da alteracao]
- `src/modules/[modulo]/[arquivo].ts` — [descricao da alteracao]

**2.2 Dados e Persistencia**

Especifique colecoes (MongoDB) ou tabelas (MySQL) afetadas:
- Colecao/Tabela: `[nome]`
- Campos afetados: [lista]
- Indices necessarios: [especificar]
- Queries: [NUNCA use SELECT * — especifique campos]

**2.3 Contrato de Dados (DTO/Payload)**

Defina a estrutura JSON estrita de entrada e saida com regras de validacao:

**Entrada:**
```json
{
  "campo": "string — obrigatorio, min 3 chars",
  "valor": "number — obrigatorio, min 0"
}
```

**Saida:**
```json
{
  "id": "string — UUID",
  "resultado": "object"
}
```

**Validacao:** [Zod schema para Fastify | class-validator decorators para NestJS]

**2.4 Resiliencia e Zero Trust (CRITICO)**

Defina o comportamento esperado em caso de falha:

| Cenario de Falha | Estrategia | Impacto |
|---|---|---|
| Banco indisponivel | [Ex: Circuit Breaker, retry 3x com backoff] | [Ex: 503] |
| Fila indisponivel | [Ex: try/catch silencioso, logar erro, retornar 200] | [Ex: Nenhum — operacao secundaria] |
| Dados invalidos | [Ex: Fail-fast, rejeitar com 400] | [Ex: Request rejeitado] |

#### 3. Modelagem Visual

Gere diagramas em PlantUML (text-based) quando agregar valor:

**Diagrama de Sequencia** — interacao sincrona/assincrona completa, incluindo fluxos de erro.

**Diagrama C4 (Nivel 3)** — componentes internos do container afetado (se nao coberto no plan.md).

#### 4. Orientacao de Execucao

Metadados operacionais consumidos pelo agente (scrapup-forge, subagent mimic-loop) ou pelo engenheiro durante a implementacao desta Tarefa. Nao e um prompt para copiar — e informacao estruturada para guiar a execucao.

**4.1 Contexto de Entrada**

Ficheiros a ler ANTES de implementar (ordem importa):
1. `src/modules/[modulo]/[arquivo].ts` — [motivo: entender interface existente]
2. `src/modules/[modulo]/[arquivo].spec.ts` — [motivo: entender cobertura atual]
3. [outros ficheiros de referencia]

**4.2 Passos de Implementacao**

1. [Passo atomico — ex: "Criar schema Mongoose em `src/models/x.ts` com campos Y e Z"]
2. [Passo atomico — ex: "Adicionar indice composto em campo Y e Z"]
3. [Passo atomico]

**4.3 Comando de Validacao**

```bash
[npm test -- --testPathPattern="[pattern]" | pnpm test | outro]
```

**4.4 Restricoes Negativas**

Restricoes **especificas desta TF** (restricoes globais — Ironclad, any — ja cobertas pelas skills ativas):
- NAO [restricao especifica da TF]
- NAO [restricao especifica da TF]

**4.5 Skills Obrigatorias**

| Skill | Motivo |
|---|---|
| `test-driven-agentic-development` | [Ex: TF altera logica de negocio e exige verificacao de testes impactados antes de commit] |
| [skill] | [motivo] |

**4.6 Criterios de Saida**

O agente DEVE parar quando TODOS forem verdadeiros:
- [ ] Comando de validacao (4.3) passa sem erros
- [ ] Ficheiros listados em 2.1 foram criados/alterados conforme especificado
- [ ] [Criterio especifico verificavel]

Se 3 tentativas consecutivas falham no mesmo criterio → escalar ao utilizador.

**4.7 Decomposicao Iterativa (mimic-loop) — OPCIONAL**

> Preencher quando: TF toca 3+ ficheiros, DoD com 4+ criterios,
> estimativa > 2h de implementacao, ou execucao sera delegada a
> subagents com contexto limpo (mimic-loop).
> TFs simples (P2, 1 ficheiro, DoD com 1-2 items) NAO precisam desta sub-secao.

**Modo de execucao:** `mimic-loop`
**Max iteracoes:** [N — default 30]
**Projeto saga:** `exec:{repo}:{TF-XX-YY}`

| # | RT / iteracao | Criterio de Conclusao | Depende de |
|---|---|---|---|
| RT-01 | [Acao atomica — ex: "Criar schema e teste de schema"] | [Verificavel: teste passa, ficheiro existe] | — |
| RT-02 | [Acao atomica — ex: "Implementar DTO com validacao Zod"] | [Verificavel: teste unitario do DTO passa] | RT-01 |
| RT-03 | [Acao atomica] | [Verificavel] | RT-01 |

**Mapeamento saga:**

| Conceito Blueprint | Conceito Saga | Tool |
|---|---|---|
| TF-XX-YY | Task no epic do projeto `exec:*` | `task_create` |
| RT-01, RT-02... | Subtask da task | `subtask_create` |
| Criterio de conclusao RT | Comment de evidencia na subtask | `comment_add` |
| Handoff entre iteracoes | Note tipo `context` | `note_save` |

**Sinais de saida:**
- Todas as RT com status `done` no saga → TF concluida
- 3 subagents consecutivos sem progresso → escalar ao utilizador

#### 5. Testes de Aceitacao (Definition of Done)

- [ ] Validacao do Caminho Feliz — [descrever cenario especifico]
- [ ] Validacao de Resiliencia — [Ex: "O que acontece se o Redis estiver fora do ar?"]
- [ ] Regras de Idempotencia — [se aplicavel]
- [ ] Restricoes de Contrato — [Ex: "DTO rejeita campos extras"]
- [ ] Cobertura de testes unitarios para a logica de negocio
- [ ] Testes de integracao para o caminho de falha
````

---

## Guia de Prioridades

| Prioridade | Descricao | Quando Usar |
|---|---|---|
| **P0** | Bloqueante — sem isso nada mais funciona | Schemas de banco, DTOs base, setup de infra |
| **P1** | Essencial — funcionalidade core | UseCases, Controllers, Consumers |
| **P2** | Complementar — melhoria ou otimizacao | Cache, metricas, logs adicionais |

## Quando Usar Secao 4.7 (mimic-loop)

| Indicador | Secao 4.7? |
|---|---|
| TF toca 1-2 ficheiros, DoD com 1-2 items | NAO — execucao direta |
| TF com P2, alteracao trivial (constante, config) | NAO |
| TF toca 3+ ficheiros em dominios diferentes | SIM |
| DoD com 4+ criterios verificaveis | SIM |
| Estimativa > 2h de implementacao | SIM |
| Utilizador pede execucao via mimic-loop | SIM |
| TF envolve integracao + logica + persistencia | SIM |
