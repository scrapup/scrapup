# Template: User Story (Entregavel de Valor)

## Contexto de Uso

Este template define o formato obrigatorio para cada **User Story** gerada na Fase 3 (`tasks.md` ou `single-tasks.md`) do Spec-Driven Development.
A User Story e o **nivel intermediario** da hierarquia Scrum e representa uma **entrega de valor ao produto**. Ela e cadastrada pelo time tecnico durante o refinamento tecnico no ClickUp.

**`single-tasks.md` (incremental):** a User Story pode ser **mais enxuta** (narrativa e valor em poucas linhas); o detalhe de implementacao e validacao concentra-se nas **Tarefas**. Continua obrigatorio cumprir campos do template na medida em que o ClickUp e destinatarios precisem de contexto (ver cnv ao cadastrar).

### Hierarquia ClickUp

| Nivel | Responsavel | Descricao |
|---|---|---|
| **Epico** | Time de PM | Contexto macro recebido pelo time tecnico |
| **User Story** | Time tecnico | Entregavel de valor ao produto — **este template** |
| **Tarefa** | Time tecnico | Unidade atomica de trabalho (ver [`task-template.md`](task-template.md)) |

## Papel da User Story

A User Story **nao e** uma tarefa executavel pelo desenvolvedor. Ela e um **agrupador de valor** que:

1. Define **o que** sera entregue e **qual valor** isso agrega ao produto
2. Serve como unidade de **planejamento e acompanhamento** no refinamento/sprint
3. Agrupa **Tarefas atomicas** que juntas compoem a entrega de valor
4. E a unidade que o time tecnico **cadastra no ClickUp** vinculada ao Epico do PM

## Restricoes

- **NUNCA** misture mais de um entregavel de valor na mesma User Story
- **NUNCA** detalhe implementacao tecnica na User Story — isso pertence as Tarefas
- **NUNCA** crie User Stories sem vinculo explicito ao Epico de referencia
- **NUNCA** escolha o ID `US-XX` manualmente — obter via `bash ~/.claude/plugins/local/scrapup/skills/documentacao/blueprint/getNextUserStoryId.sh` (gerador sequencial **global**, mantem unicidade entre execucoes e projetos). Ver secao **Identificadores Sequenciais de User Story (Global)** da `SKILL.md`
- A narrativa "Eu como... Eu quero... Para que..." deve focar no **valor de negocio**, nao em detalhes tecnicos
- Cada User Story deve ser **demonstravel** ao final da sprint — se nao e demonstravel, refatie

### Formato do ID

| Numero retornado pelo script | ID final |
|---|---|
| 1 a 9 | `US-01` ... `US-09` (padding com zero a esquerda, minimo 2 digitos) |
| 10 a 99 | `US-10` ... `US-99` |
| >= 100 | `US-100`, `US-1234` (sem padding adicional) |

As Tarefas usam `TF-XX-YY` onde `XX` **herda exatamente** o ID da US pai e `YY` e sequencial local dentro da US (`01`, `02`, `03`...).

---

## Template

```markdown
## [US-XX]: [Titulo — Entregavel de Valor]

**Epico:** [E-XX] Nome do Epico (referencia PM)
**Sistema:** [Nome exato do repositorio]
**Estimativa:** [X] Story Points
**Prioridade:** [P0 | P1 | P2]

### Narrativa de Valor

> **Eu como** [Ator/Persona de Negocio],
> **Eu quero** [Capacidade/Funcionalidade entregue],
> **Para que** [Valor de negocio — impacto mensuravel no produto].

### Contexto de Negocio

[Explique o cenario de negocio que motiva esta entrega. Qual problema do usuario ou do produto esta sendo resolvido? Como esta User Story contribui para o objetivo do Epico?]

### Criterios de Aceitacao (Nivel de Negocio)

Define **quando** a User Story esta completa do ponto de vista do produto:

- [ ] [Criterio 1 — comportamento observavel pelo usuario ou pelo sistema]
- [ ] [Criterio 2 — regra de negocio validada]
- [ ] [Criterio 3 — integracao funcional entre componentes]
- [ ] [Criterio N — demonstravel na review da sprint]

### Regras de Negocio Aplicaveis

| # | Regra | Tipo |
|---|---|---|
| RN-XX | [Regra de negocio que impacta esta US] | [Obrigatoria / Restritiva / Condicional] |
| RN-XX | [Regra de negocio que impacta esta US] | [Obrigatoria / Restritiva / Condicional] |

### Sequenciamento de Tarefas

| # | Tarefa | Escopo | Depende de |
|---|---|---|---|
| TF-XX-01 | [Nome da Tarefa] | [Dominio] | — |
| TF-XX-02 | [Nome da Tarefa] | [Dominio] | TF-XX-01 |
| TF-XX-03 | [Nome da Tarefa] | [Dominio] | TF-XX-01, TF-XX-02 |

### Tarefas

#### TF-XX-01: [Titulo Atomico da Tarefa]

[Preencher com o template completo de Tarefa — ver templates/task-template.md]

---

#### TF-XX-02: [Titulo Atomico da Tarefa]

[Preencher com o template completo de Tarefa — ver templates/task-template.md]

---

[Repetir para cada Tarefa da User Story]
```

---

## Guia de Fatiamento em User Stories

### Principio: Uma User Story = Um Entregavel Demonstravel

Pergunte-se: "Consigo demonstrar o valor dessa US ao final da sprint?" Se a resposta for nao, a US esta grande demais ou abstrata demais.

### Exemplos de Bom Fatiamento

| User Story | Valor Entregue | Demonstravel? |
|---|---|---|
| US-01: Sincronizacao de dados do legado para ODS | Consultas de vendas retornam dados em tempo real | Sim — consulta retorna dado atualizado |
| US-02: Endpoint de consulta de cotacao PME | Usuario recebe cotacao calculada em < 1s | Sim — chamada HTTP retorna cotacao |
| US-03: Notificacao automatica de erro no consumer | Time de suporte e alertado quando sync falha | Sim — alerta disparado em cenario de falha |

### Exemplos de Mau Fatiamento

| User Story | Problema |
|---|---|
| "Implementar toda a feature X" | Escopo gigante, nao e um entregavel atomico de valor |
| "Criar schemas e DTOs" | Nao entrega valor de negocio observavel — isso e Tarefa |
| "Refatorar modulo Y" | Valor tecnico sem impacto demonstravel no produto |
| "Setup de infra e deploy" | Atividade operacional, nao entregavel de valor |

## Guia de Estimativa (Story Points)

Story Points sao definidos **exclusivamente na User Story**. Nem Epicos nem Tarefas recebem pontos.

| Points | Complexidade | Exemplo |
|---|---|---|
| 1 | Trivial — alteracao de config ou schema simples | Adicionar indice no MongoDB |
| 2 | Simples — CRUD basico, DTO direto | Criar DTO de validacao |
| 3 | Medio — logica de negocio com 2-3 caminhos | Implementar UseCase com validacao |
| 5 | Complexo — integracao com sistema externo | Consumer RabbitMQ com DLQ e retry |
| 8 | Muito complexo — multiplas integracoes | Worker de sync com transformacao e idempotencia |

## Relacao com Outros Templates

| Template | Nivel | Quando Usar |
|---|---|---|
| [`tasks-template.md`](tasks-template.md) | Backlog Fase 3 | Estrutura o `tasks.md` ou `single-tasks.md` com todas as US e Tarefas |
| **[`user-story-template.md`](user-story-template.md)** | **User Story** | **Formato de cada US dentro do artefato de backlog** |
| [`task-template.md`](task-template.md) | Tarefa | Formato de cada Tarefa atomica dentro de uma US |
