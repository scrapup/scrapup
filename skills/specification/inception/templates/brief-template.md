# Brief de Inception — {{Título da iniciativa}}

> **Template do `brief.md`** — artefato **único e completo** da fase de **Inception**. Profundidade
> **rasa** ("inch deep"): identifica e fundamenta, não detalha (detalhe → Elaboration/`spec.md`/`plan.md`).
> Produzido em **camadas validadas** (cadeia de lastro): cada seção é preenchida e **validada com o
> utilizador** antes da próxima. **Não inferir lacunas — perguntar.** Convenções de ID: `UCnnnn`,
> `FTnnnn`, `RKnnnn` (4 dígitos, a partir de 0001).

| Campo | Valor |
|-------|-------|
| Fase | Inception |
| Marco-alvo | LCO (go/no-go) |
| Status | `draft` \| `em validação` \| `LCO aprovado` |
| Autor / Validador | {{humano-arquiteto/validador}} |
| Data | {{AAAA-MM-DD}} |

---

## 1. Lastro — referências brutas (fontes do pedido)

> _Camada 1. As fontes (scraps) que originam a iniciativa. O brief **destila** estas fontes — o link não
> dispensa a síntese. Anexar conteúdo crítico (link rot); registrar data de captura._

| Fonte | Tipo | Link / anexo | Capturado em |
|-------|------|--------------|--------------|
| {{descrição}} | {{ClickUp \| Slack \| transcrição \| e-mail \| prompt \| doc}} | `{{link/anexo}}` | {{AAAA-MM-DD}} |

## 2. Vision

> _Camada 2 (fundacional — validar cedo). O "porquê". Sem business case financeiro aqui (§10)._

- **Problema:** {{dor/necessidade}}
- **Stakeholders:** {{quem é afetado / decide}}
- **Necessidades-chave:** {{o que precisa existir}}
- **Oportunidade:** {{ganho esperado}}
- **Critérios de sucesso (provisórios):** {{como saberemos que deu certo}}

## 3. Domain model / Glossário

> _Camada 3. Contexto que ancora os use cases. **Linguagem ubíqua** (DDD). Leve: glossário + esboço._

| Termo | Definição |
|-------|-----------|
| {{Termo}} | {{definição}} |

> _Opcional: diagrama de classes de domínio (UML) e/ou state machine de um conceito com ciclo de vida._

```plantuml
@startuml
' domain model conceitual (não solução)
@enduml
```

## 4. Feature list (candidate requirements)

> _Camada 4. Lista para planejar. Prioridade + risco por item (alimenta a ordenação risk-driven)._

| ID | Feature | Status | Custo est. | Prioridade | Risco |
|----|---------|--------|-----------|------------|-------|
| FT0001 | {{feature}} | proposto | {{S/M/L}} | {{crítica/importante/ancilar}} | {{baixo/médio/alto}} |

## 5. Risk list + rating

> _Camada 5. Campos (UP, [p.362-363]): Description · Priority(rating) · Impact · Monitor · Contingency.
> **Rating = Priority = `critical`/`significant`/`routine`** (de Prob×Impacto — ver SKILL "Rating de
> risco"). Dirige a ordem das iterações (crítico cedo)._

| ID | Risco | Prob. | Impacto | Rating (Priority) | Mitigação / contingência |
|----|-------|-------|---------|-------------------|---------------------------|
| RK0001 | {{risco}} | {{baixa/média/alta}} | {{baixo/médio/alto}} | {{routine/significant/critical}} | {{mitigação}} |

## 6. Use-case model

> _Camada 6. Espinha do UP (use-case driven). Atores + use cases + relações. Spec **rasa** por UC._

**Atores (catálogo)**

| Ator | Tipo | Papel |
|------|------|-------|
| {{Ator}} | {{primário/secundário}} | {{papel}} |

```plantuml
@startuml
left to right direction
@enduml
```

### Spec básica por use case (rasa)

> _Estrutura UML: ator · **pré-condições** · fluxo principal (lista ordenada `1, 2, 2.1, 3`) ·
> **pós-condições** · relações. Fluxos alternativos/exceções → `spec.md` (Elaboration)._

**UC0001 · {{Nome}}** — *({{FTxxxx}}, risco {{nível}})*
- Ator: {{ator}}.
- Pré-condições: {{estado exigido}}.
- Breve: {{1 linha}}.
- Fluxo principal:
  1. {{passo}}
  2. {{passo}}
     - 2.1. {{sub-passo, se houver}}
  3. {{passo}}
- Pós-condições: {{estado garantido; marcar read-only se consulta}}.

### Relações entre use cases

> _Pré-condição (dependência de estado) · «include» (sub-comportamento sempre invocado) · «extend»
> (condicional) · generalização. Ordem de construção é risk-driven (Ranking), não grafo de execução aqui._

- {{ex.: UC0002 e UC0003 exigem Cliente autenticado (UC0001) — pré-condição}}

### Ranking de use cases (ordem por risco)

1. {{UCxxxx — fundacional/risco alto}}
2. {{...}}

### Rastreabilidade (trace)

> _Montante → fonte (Lastro §1); jusante → teste (`spec.md`). A matriz cresce com o ciclo._

| Feature | Use case | Risco |
|---------|----------|-------|
| {{FTxxxx}} | {{UCxxxx}} | {{RKxxxx}} |

## 7. Requisitos suplementares (não-funcionais)

> _Camada 7. Taxonomia FURPS+ / "-ilities". NFR específico de um UC ancora-se a ele; demais sistêmicos._

| Categoria | Requisito (provisório) |
|-----------|------------------------|
| Functionality | {{...}} |
| Usability | {{...}} |
| Reliability | {{...}} |
| Performance | {{...}} |
| Supportability | {{observabilidade}} |
| + Constraints | {{stack/LGPD/segurança}} |

## 8. Arquitetura candidata (direção, provisória)

> _Camada 8. Direção **por promessa** (candidata, não provada). ADR formal e prova → Elaboration.
> Diagramas: **C4 N1 (Context) + N2 (Container raso)**. **N3/Component e sequence de componentes →
> Elaboration.**_

- **Estilo / decisões de direção:** {{ex.: monolito modular; event-driven; cache}}
- **Porquê:** {{liga aos riscos RKxxxx}}
- **Status:** provisória — a provar pelo baseline executável na Elaboration.

```plantuml
@startuml
!include <C4/C4_Context>
@enduml
```

```plantuml
@startuml
!include <C4/C4_Container>
@enduml
```

## 9. Business case (rascunho)

> _Camada 9. Justificativa econômica **em geral** (ordem de grandeza); bid detalhado → Elaboration._

- **Justificativa:** {{problema → valor}}
- **Custo (ordem de grandeza):** desenvolvimento · infra/operação · tooling.
- **Retorno/valor:** {{receita/economia/estratégico}}
- **ROI / recomendação:** {{go/no-go provisório, a confirmar na Elaboration}}

## 10. Plano de fase / estimativa (leve)

> _Camada 10. PM leve. Distribuição referencial (Construction tende a encolher no AI-assisted)._

| Fase | Marco | Foco | Esforço (ref.) |
|------|-------|------|----------------|
| Inception (atual) | LCO | este brief | ~10% |
| Elaboration | LCA | spec.md + plan.md/C4 + ADRs + baseline + execution plan | ~30% |
| Construction | IOC | forge + TDAD + review até beta | ~50% (tende a menor) |
| Transition | Product Release | deploy + verificação em prd | ~10% |

Iterações previstas (estimativa): {{Elaboration N · Construction N · Transition N}}.

## 11. Fronteira (o que NÃO está neste brief)

- **Detalhamento dos use cases** (fluxos alternativos, exceções) → `spec.md` (Elaboration).
- **Diagramas de detalhe** (sequence de componentes, activity, **C4 N3**) → Elaboration.
- **ADR formal** (decisão de arquitetura provada) → Elaboration.
- **Fatiamento/execução** (tasks, ciclos, PRs) → `tasks.md` + execution plan.

## 12. Prontidão para o LCO (marco de fim da Inception)

> _Camada final. Checklist *marco-aware*. O gate é selado pelo **humano-validador** (sign-off)._

| Critério LCO | Onde | Status |
|--------------|------|--------|
| Escopo claro | §2, §6 | {{OK / pendente}} |
| Atores identificados | §6 | {{...}} |
| Arquitetura candidata à vista | §8 | {{...}} |
| Riscos críticos identificados e mitigáveis | §5 | {{...}} |
| Business case justifica o investimento | §9 | {{...}} |
| Plano de fase / estimativa | §10 | {{...}} |
| Stakeholders concordam | — | sign-off do validador |
