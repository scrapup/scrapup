# Template: User Story (Value Deliverable)

## Usage Context

This template defines the mandatory format for each **User Story** generated in Phase 3 (`tasks.md` or `single-tasks.md`) of Spec-Driven Development.
The User Story is the **intermediate level** of the Scrum hierarchy and represents a **value delivery to the product**. The engineering team registers it during technical refinement.

**`single-tasks.md` (incremental):** the User Story may be **leaner** (narrative and value in a few lines); implementation and validation detail concentrates in the **Tasks**. The template fields are still required to the extent readers need context (apply /scrapup:communication).

### Hierarchy

| Level | Owner | Description |
|---|---|---|
| **Epic** | Product management | Macro context received by the engineering team |
| **User Story** | Engineering team | Value deliverable to the product — **this template** |
| **Task** | Engineering team | Atomic unit of work (see [`task-template.md`](task-template.md)) |

## Role of the User Story

The User Story **is not** a task the developer executes. It is a **value grouping** that:

1. Defines **what** will be delivered and **what value** it adds to the product
2. Serves as the **planning and tracking** unit in refinement/sprint
3. Groups the **atomic Tasks** that together make up the value delivery
4. Is the unit the engineering team registers, linked to the product management Epic

## Constraints

- **NEVER** mix more than one value deliverable in the same User Story
- **NEVER** detail technical implementation in the User Story — that belongs to the Tasks
- **NEVER** create User Stories without an explicit link to the reference Epic
- **NEVER** choose or infer the `US-XX` ID — ask the user for the first User Story ID and derive the following US sequentially. See **User Story Identifiers** in `SKILL.md`
- The "As... I want... So that..." narrative must focus on **business value**, not technical detail
- Each User Story must be **demonstrable** at the end of the sprint — if it is not demonstrable, re-slice it

### ID Format

| Number (provided by the user or derived) | Final ID |
|---|---|
| 1 to 9 | `US-01` ... `US-09` (zero-padded, minimum 2 digits) |
| 10 to 99 | `US-10` ... `US-99` |
| >= 100 | `US-100`, `US-1234` (no extra padding) |

Tasks use `TF-XX-YY`, where `XX` **inherits exactly** the parent US ID and `YY` is locally sequential inside the US (`01`, `02`, `03`...).

---

## Template

```markdown
## [US-XX]: [Title — Value Deliverable]

**Epic:** [E-XX] Epic name (product management reference)
**System:** [Exact repository name]
**Estimate:** [X] Story Points
**Priority:** [P0 | P1 | P2]

### Value Narrative

> **As** [Business Actor/Persona],
> **I want** [Delivered capability/feature],
> **So that** [Business value — measurable impact on the product].

### Business Context

[Explain the business scenario behind this delivery. Which user or product problem is being solved? How does this User Story contribute to the Epic's goal?]

### Acceptance Criteria (Business Level)

Defines **when** the User Story is complete from the product's point of view:

- [ ] [Criterion 1 — behavior observable by the user or the system]
- [ ] [Criterion 2 — validated business rule]
- [ ] [Criterion 3 — functional integration between components]
- [ ] [Criterion N — demonstrable in the sprint review]

### Applicable Business Rules

| # | Rule | Type |
|---|---|---|
| BR-XX | [Business rule that impacts this US] | [Mandatory / Restrictive / Conditional] |
| BR-XX | [Business rule that impacts this US] | [Mandatory / Restrictive / Conditional] |

### Task Sequencing

| # | Task | Scope | Depends on |
|---|---|---|---|
| TF-XX-01 | [Task name] | [Domain] | — |
| TF-XX-02 | [Task name] | [Domain] | TF-XX-01 |
| TF-XX-03 | [Task name] | [Domain] | TF-XX-01, TF-XX-02 |

### Tasks

#### TF-XX-01: [Atomic Task Title]

[Fill in with the full Task template — see templates/task-template.md]

---

#### TF-XX-02: [Atomic Task Title]

[Fill in with the full Task template — see templates/task-template.md]

---

[Repeat for each Task of the User Story]
```

---

## Slicing Guide for User Stories

### Principle: One User Story = One Demonstrable Deliverable

Ask yourself: "Can I demonstrate this US's value at the end of the sprint?" If the answer is no, the US is too big or too abstract.

### Good Slicing Examples

| User Story | Value Delivered | Demonstrable? |
|---|---|---|
| US-01: Sync legacy data into the ODS | Sales queries return real-time data | Yes — the query returns updated data |
| US-02: SME quote lookup endpoint | The user gets a calculated quote in < 1s | Yes — the HTTP call returns the quote |
| US-03: Automatic consumer error notification | The support team is alerted when the sync fails | Yes — alert fired in a failure scenario |

### Bad Slicing Examples

| User Story | Problem |
|---|---|
| "Implement the whole feature X" | Huge scope, not an atomic value deliverable |
| "Create schemas and DTOs" | Delivers no observable business value — that is a Task |
| "Refactor module Y" | Technical value with no demonstrable product impact |
| "Infra setup and deploy" | Operational activity, not a value deliverable |

## Estimation Guide (Story Points)

Story Points are set **only on the User Story**. Neither Epics nor Tasks get points.

| Points | Complexity | Example |
|---|---|---|
| 1 | Trivial — config change or simple schema | Add an index in MongoDB |
| 2 | Simple — basic CRUD, straightforward DTO | Create a validation DTO |
| 3 | Medium — business logic with 2-3 paths | Implement a UseCase with validation |
| 5 | Complex — integration with an external system | RabbitMQ consumer with DLQ and retry |
| 8 | Very complex — multiple integrations | Sync worker with transformation and idempotency |

## Relation to Other Templates

| Template | Level | When to Use |
|---|---|---|
| [`tasks-template.md`](tasks-template.md) | Phase 3 backlog | Structures `tasks.md` or `single-tasks.md` with every US and Task |
| **[`user-story-template.md`](user-story-template.md)** | **User Story** | **Format of each US inside the backlog artifact** |
| [`task-template.md`](task-template.md) | Task | Format of each atomic Task inside a US |
