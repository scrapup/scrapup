# Inception Brief — {{Initiative title}}

> **`brief.md` template** — the **single, complete** artifact of the **Inception** phase.
> **Shallow** depth ("inch deep"): identify and ground, do not detail (detail →
> Elaboration/`spec.md`/`plan.md`). Produced in **validated layers** (grounding chain): each section
> is filled and **validated with the user** before the next. **Do not infer gaps — ask.** ID
> conventions: `UCnnnn`, `FTnnnn`, `RKnnnn` (4 digits, starting at 0001).

| Field | Value |
|-------|-------|
| Phase | Inception |
| Target milestone | LCO (go/no-go) |
| Status | `draft` \| `in validation` \| `LCO approved` |
| Author / Validator | {{user (Architect-Validator)}} |
| Date | {{YYYY-MM-DD}} |

---

## 1. Grounding — raw references (request sources)

> _Layer 1. The sources (scraps) that originate the initiative. The brief **distills** these sources
> — a link does not replace the synthesis. Attach critical content (link rot); record the capture
> date._

| Source | Type | Link / attachment | Captured on |
|--------|------|-------------------|-------------|
| {{description}} | {{issue \| message \| transcript \| email \| prompt \| doc}} | `{{link/attachment}}` | {{YYYY-MM-DD}} |

## 2. Vision

> _Layer 2 (foundational — validate early). The "why". No financial business case here (§9)._

- **Problem:** {{pain/need}}
- **Stakeholders:** {{who is affected / decides}}
- **Key needs:** {{what must exist}}
- **Opportunity:** {{expected gain}}
- **Success criteria (provisional):** {{how we will know it worked}}

## 3. Domain model / Glossary

> _Layer 3. Context that anchors the use cases. **Ubiquitous language** (DDD). Light: glossary +
> sketch._

| Term | Definition |
|------|------------|
| {{Term}} | {{definition}} |

> _Optional: domain class diagram (UML) and/or state machine of a concept with a lifecycle._

```plantuml
@startuml
' conceptual domain model (not solution)
@enduml
```

## 4. Feature list (candidate requirements)

> _Layer 4. List for planning. Priority + risk per item (feeds risk-driven ordering)._

| ID | Feature | Status | Est. cost | Priority | Risk |
|----|---------|--------|-----------|----------|------|
| FT0001 | {{feature}} | proposed | {{S/M/L}} | {{critical/important/ancillary}} | {{low/medium/high}} |

## 5. Risk list + rating

> _Layer 5. Fields (UP, [p.362-363]): Description · Priority (rating) · Impact · Monitor ·
> Responsibility · Contingency. **Rating = Priority = `critical`/`significant`/`routine`** (from
> Probability×Impact — see SKILL "Risk rating"). Drives iteration order (critical early)._

| ID | Description | Priority (rating) | Impact | Monitor | Responsibility | Contingency |
|----|-------------|-------------------|--------|---------|----------------|-------------|
| RK0001 | {{risk}} — prob. {{low/medium/high}} | {{routine/significant/critical}} | {{low/medium/high}} — {{affected parts}} | {{signal to watch}} | {{owner}} | {{mitigation/contingency}} |

## 6. Use-case model

> _Layer 6. Backbone of the UP (use-case driven). Actors + use cases + relationships. **Shallow**
> spec per UC._

**Actors (catalog)**

| Actor | Type | Role |
|-------|------|------|
| {{Actor}} | {{primary/secondary}} | {{role}} |

```plantuml
@startuml
left to right direction
@enduml
```

### Basic spec per use case (shallow)

> _UML structure: actor · **preconditions** · main flow (ordered list `1, 2, 2.1, 3`) ·
> **postconditions** · relationships. Alternative flows/exceptions → `spec.md` (Elaboration)._

**UC0001 · {{Name}}** — *({{FTxxxx}}, risk {{level}})*
- Actor: {{actor}}.
- Preconditions: {{required state}}.
- Brief: {{1 line}}.
- Main flow:
  1. {{step}}
  2. {{step}}
     - 2.1. {{sub-step, if any}}
  3. {{step}}
- Postconditions: {{guaranteed state; mark read-only if a query}}.

### Relationships between use cases

> _Precondition (state dependency) · «include» (sub-behavior always invoked) · «extend»
> (conditional) · generalization. Build order is risk-driven (Ranking), not an execution graph
> here._

- {{e.g.: UC0002 and UC0003 require an authenticated Customer (UC0001) — precondition}}

### Use-case ranking (order by risk)

1. {{UCxxxx — foundational/high risk}}
2. {{...}}

### Traceability (trace)

> _Upstream → source (Grounding §1); downstream → test (`spec.md`). The matrix grows with the
> cycle._

| Feature | Use case | Risk |
|---------|----------|------|
| {{FTxxxx}} | {{UCxxxx}} | {{RKxxxx}} |

## 7. Supplementary requirements (non-functional)

> _Layer 7. FURPS+ / "-ilities" taxonomy. A UC-specific NFR anchors to that UC; the rest are
> systemic._

| Category | Requirement (provisional) |
|----------|---------------------------|
| Functionality | {{...}} |
| Usability | {{...}} |
| Reliability | {{...}} |
| Performance | {{...}} |
| Supportability | {{observability}} |
| + Constraints | {{stack / applicable data-protection law (e.g., GDPR) / security}} |

## 8. Candidate architecture (direction, provisional)

> _Layer 8. Direction **by promise** (candidate, not proven). Formal ADR and proof → Elaboration.
> Diagrams: **C4 L1 (Context) + L2 (shallow Container)**. **L3/Component and component sequence →
> Elaboration.**_

- **Style / direction decisions:** {{e.g.: modular monolith; event-driven; cache}}
- **Why:** {{links to risks RKxxxx}}
- **Status:** provisional — to be proven by the executable baseline in Elaboration.

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

## 9. Business case (draft)

> _Layer 9. Economic justification **in general** (order of magnitude); detailed bid →
> Elaboration._

- **Justification:** {{problem → value}}
- **Cost (order of magnitude):** development · infra/operation · tooling.
- **Return/value:** {{revenue/savings/strategic}}
- **ROI / recommendation:** {{provisional go/no-go, to be confirmed in Elaboration}}

## 10. Phase plan / estimate (light)

> _Layer 10. Light PM. Referential distribution (Construction tends to shrink in AI-assisted UP)._

| Phase | Milestone | Focus | Effort (ref.) |
|-------|-----------|-------|---------------|
| Inception (current) | LCO | this brief | ~10% |
| Elaboration | LCA | spec.md + plan.md/C4 + ADRs + baseline + execution plan | ~30% |
| Construction | IOC | forge + TDAD + review up to beta | ~50% (tends lower) |
| Transition | Product Release | deploy + production verification | ~10% |

Planned iterations (estimate): {{Elaboration N · Construction N · Transition N}}.

## 11. Boundary (what is NOT in this brief)

- **Use-case detailing** (alternative flows, exceptions) → `spec.md` (Elaboration).
- **Detail diagrams** (component sequence, activity, **C4 L3**) → Elaboration.
- **Formal ADR** (proven architecture decision) → Elaboration.
- **Slicing/execution** (tasks, cycles, PRs) → `tasks.md` + execution plan.

## 12. LCO readiness (end-of-Inception milestone)

> _Final layer. Milestone-aware checklist. The gate is sealed by the **user (Architect-Validator)**
> (sign-off)._

| LCO criterion | Where | Status |
|---------------|-------|--------|
| Clear scope | §2, §6 | {{OK / pending}} |
| Actors identified | §6 | {{...}} |
| Candidate architecture in view | §8 | {{...}} |
| Critical risks identified and mitigable | §5 | {{...}} |
| Business case justifies the investment | §9 | {{...}} |
| Phase plan / estimate | §10 | {{...}} |
| Stakeholders agree | — | user (Architect-Validator) sign-off |
