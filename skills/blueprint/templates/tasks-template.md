# Template: Atomic Execution Backlog — `tasks.md` and `single-tasks.md`

## Usage Context

This template guides the creation of the SDD atomic execution artifacts. There are **two flows**:

| File | Flow | Prerequisites |
|---|---|---|
| **`tasks.md`** | **Full** — Phase 3 after `plan.md` | `spec.md` and `plan.md` **approved** |
| **`single-tasks.md`** | **Incremental** — low impact, no spec/plan | **No** `spec.md` / `plan.md` required; **max 5 Tasks** (`#### TF-`) |

The focus remains **atomic execution**: Tasks that can be implemented and tested in isolation.

**Where to save:**

- Full flow: `/docs/specs/<feature-name>/tasks.md`
- Incremental: `/docs/specs/<context>/single-tasks.md` (folder aligned with the feature or increment)

---

## `tasks.md` — full flow

**Mandatory prerequisites:** `spec.md` and `plan.md` approved by the user.

The focus is slicing **`plan.md`** into User Stories made of Tasks. See the **Hierarchy** and **Template** sections below; **per-US diagrams are proportional to scope** (see **Full backlog — `tasks.md`** in the blueprint `SKILL.md`).

---

## `single-tasks.md` — incremental flow

Use when the change has **low code impact**: e.g., adding a test, changing a constant, adjustments in **few snippets** and **few files**, with no new architecture or broad contract.

**Non-negotiable rules:**

1. **At most 5 Tasks** in the file. If more are needed, do **not** use this flow — produce `spec.md`, `plan.md` and `tasks.md`.
2. **No** `spec.md` and **no** `plan.md`: the approved `single-tasks.md` is the contract.
3. **Same markup format** as `tasks.md`: `## US-XX` (or equivalent), `#### TF-XX-YY`, User Story and Task template fields.
4. **All** the needed specification (context, files, criteria, DoD, local risks) must be **in the Tasks**; the User Story may be **brief** (summarized narrative).
5. **PlantUML diagrams:** optional; use only if they avoid ambiguity.

**Prerequisites Check (incremental):** there is no `plan.md` — only validate that each TF lists the touched files/areas and testable acceptance criteria.

---

## Backlog Hierarchy (Scrum)

| Level | Owner | Description |
|---|---|---|
| **Epic** | Product management | Received by the engineering team — macro context of what must be done. The engineering team **does not create** epics. |
| **User Story** | Engineering team (refinement) | Value deliverable to the product. Groups related Tasks. Registered during technical refinement. |
| **Task** | Engineering team (breakdown) | Atomic unit of work with every detail the developer needs to execute and validate it. |

`tasks.md` or `single-tasks.md` organizes the backlog into **User Stories** with their **Tasks**. Each User Story represents a value delivery and holds sequenced atomic Tasks.

## Phase 3 Constraints

- **FORBIDDEN** to generate plain checkbox lists (e.g., "- [ ] Build API") — slicing into descriptive Tasks is non-negotiable
- **FORBIDDEN** to include TypeScript/JavaScript code in the backlog artifact (`tasks.md` / `single-tasks.md`) — planning file only
- **FORBIDDEN** to generate Tasks that span more than one domain of responsibility
- **NEVER** combine "Create DB Table" with "Create RabbitMQ Consumer" in the same Task
- **FORBIDDEN** in `single-tasks.md`: more than **5** `#### TF-` blocks
- **FORBIDDEN** to choose or infer `US-XX` IDs. Ask the user for the first User Story ID and derive the new User Stories sequentially from it (minimum 2-digit padding). The `US-01`, `US-02`, `US-03` examples in this template are **illustrative placeholders**; in real use the IDs start from the number the user provides and may not start at `01`. Details in **User Story Identifiers** in `SKILL.md`

## Slicing Principles

1. **Atomicity:** each Task must be implementable and testable in isolation. If a Task needs another one to be tested, they are badly sliced
2. **Topological sequencing (`tasks.md` only):** respect dependencies — infra/schemas before connectors, connectors before use cases, use cases before controllers. In the incremental flow, order TFs by the least practical dependency
3. **Built-in resilience:** if the change touches queues or HTTP, the Task MUST specify try/catch, retries or circuit breakers where applicable (in the incremental flow, inside the TF text)

## Prerequisites Check (`tasks.md` only)

Before generating the full Phase 3 backlog, check in `plan.md`:

1. Are the database schemas/models detailed?
2. Are the input and output DTOs defined?
3. Is error handling per component mapped?

If information on how errors should be handled is missing, warn the user before generating the backlog.

## Default Sequencing Order (`tasks.md`)

```
1. Database Schemas / Entities / Models
2. Validation DTOs (Zod/class-validator)
3. Queue Consumers (RabbitMQ)
4. Workers / Sync Jobs
5. Repositories / Data Access Layer
6. UseCases / Services (business rules)
7. Controllers / HTTP Endpoints
8. Integration and End-to-End Tests
```

Adapt the order to the context, but keep the rule: **dependencies before dependents**.

---

## Template

```markdown
# Execution Backlog: [Feature Name]

## Reference Epic

**Epic:** [E-XX] [Epic name — as registered by product management]

---

## Traceability

| Rule/Requirement (spec.md) | Architectural Decision (plan.md) | User Story | Tasks |
|---|---|---|---|
| BR-XX | [Decision that implements the rule] | US-XX | TF-XX-01, TF-XX-02 |
| BR-XX | [Decision that implements the rule] | US-XX | TF-XX-03 |

---

## User Stories Overview

| # | User Story | Value Delivered |
|---|---|---|
| US-01 | [User Story name] | [Value delivered to the product] |
| US-02 | [User Story name] | [Value delivered to the product] |
| US-03 | [User Story name] | [Value delivered to the product] |

---

## US-01: [User Story Name — Value Deliverable]

[Fill in with the full User Story template — see templates/user-story-template.md]
[The User Story template already includes: value narrative, acceptance criteria, task sequencing and task blocks]

---

## US-02: [User Story Name — Value Deliverable]

[Repeat the full structure using templates/user-story-template.md]

---

[Repeat for each User Story until the plan.md scope is covered]
```

*Note for `single-tasks.md`:* there may be **one** User Story and up to **5** `#### TF-` blocks; the **Traceability** section may refer only to "incremental demand" or an external ticket, without spec/plan columns.

*Note on Ralph Tasks (RT):* complex TFs (3+ files, 4+ DoD criteria, >2h) may include section 4.7 (Iterative Decomposition) with Ralph Tasks. RTs live **exclusively in saga** (`mcp-saga` via `subtask_create`) — never in the backlog tracker. See `templates/task-template.md` section 4.7 for the format and usage criteria.

---

## Good Slicing Examples

**Scenario:** RabbitMQ consumer that syncs data from the legacy system into MongoDB.

**User Story:** US-01 — Automatic sync of legacy system data
> As the sales system, I want to receive updated legacy data via queue, so that queries return real-time information.

| # | Task | Scope | Testable in Isolation? |
|---|---|---|---|
| TF-01-01 | Create Mongoose schema and indexes | Persistence | Yes — schema test |
| TF-01-02 | Create validation DTOs for the queue payload | Validation | Yes — unit test |
| TF-01-03 | Implement the RabbitMQ consumer | Connectivity | Yes — test with a broker mock |
| TF-01-04 | Implement transformation and persistence logic | Business | Yes — service unit test |
| TF-01-05 | Implement error handling and DLQ | Resilience | Yes — failure scenario tests |
| TF-01-06 | End-to-end integration tests | Integration | Yes — test with a real broker |

**Anti-pattern:** a single Task "Implement a consumer that receives, validates, transforms and persists the message" — it mixes 4 domains of responsibility.

## Bad Slicing Examples

| Task | Problem |
|---|---|
| "Build the whole API" | Huge scope, impossible to test atomically |
| "Create database and consumer" | Mixes persistence with connectivity |
| "- [ ] Implement feature X" | Generic checkbox with no specification |
| "Implement and test endpoint" | Mixes implementation with QA |

## When to Simplify

If the feature boils down to 1 endpoint, 1 model, no asynchronous integration:

- Use 1 User Story with 1-2 Tasks at most
- DO NOT force slicing into 6+ tasks out of bureaucracy
- Apply the Ironclad principle: solidity over bureaucracy

Signs that the slicing is excessive:
- Tasks with less than 1 Story Point of isolated complexity
- More than 50% of the tasks are "create DTO" or "create schema" with no logic
- The developer can implement everything in under 2 hours
