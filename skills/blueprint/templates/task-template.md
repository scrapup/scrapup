# Template: Technical Task

## Usage Context

This template defines the mandatory format for each **Task** generated in Phase 3 (`tasks.md` or `single-tasks.md`) of Spec-Driven Development.
Tasks are the **last planning level** of the Scrum hierarchy (Epic > User Story > Task) and must be **technical, prescriptive and unambiguous** — they are consumed by AI agents (forge, clean-context executors) and by engineers for direct implementation.

**`single-tasks.md` (incremental):** each Task must be **self-contained**: include in the TF body all the context, touched files/paths, acceptance criteria and DoD needed to implement it **without** consulting `spec.md` or `plan.md` (they do not exist in this flow).

### Hierarchy

| Level | Owner | Where it lives | Description |
|---|---|---|---|
| **Epic** | Product management | Backlog tracker | Macro context received by the engineering team |
| **User Story** | Engineering team | tasks.md | Value deliverable to the product (registered during refinement) |
| **Task (TF)** | Engineering team | tasks.md | Atomic unit of work — **this template** |
| **RT (iteration)** | Agent (execution) | saga (mcp-saga) | Operational step inside a TF — **section 4.7, optional** |

**RTs (iterations)** are the clean-context iterative execution level (section 5 of forge). They exist **only in saga** — never in the backlog tracker. They are optional: simple TFs run without RT decomposition.

## Constraints

- **NEVER** write generic specifications — use real method, table and queue names when the context provides them
- **NEVER** suggest HTTP webhooks for internal communication without asking whether event-driven via RabbitMQ would fit better
- If configuration data is missing, insert explicit placeholders such as `[INSERT_ROUTING_KEY]` and warn the user
- Each Task must cover **a single domain of responsibility**
- **NEVER** invent the `TF-XX-YY` ID. `XX` **inherits exactly** the parent User Story ID (derived from the first User Story ID provided by the user) and `YY` is **locally sequential** inside the US (`01`, `02`, `03`...). See **User Story Identifiers** in `SKILL.md`

---

## Template

````markdown
### [TF-XX-YY] [System] Clear, Objective Task Title

**User Story:** [US-XX] User Story name
**Epic:** [E-XX] Epic name (product management reference)
**System:** [Exact repository name]
**Priority:** [P0 | P1 | P2]

#### 1. Description and Goal

> **As** [Actor/System],
> **I want** [Specific technical action],
> **So that** [Contribution to the User Story value].

*Architectural Context:* [Explain the macro scenario — e.g., "We are migrating to event-driven to avoid synchronous HTTP calls between system X and Y."]

#### 2. Technical Specification

**2.1 Interception Points**

List the exact Services, Controllers, UseCases or Repositories to be created or changed:
- `src/modules/[module]/[file].ts` — [description of the change]
- `src/modules/[module]/[file].ts` — [description of the change]

**2.2 Data and Persistence**

Specify the affected collections (MongoDB) or tables (MySQL):
- Collection/Table: `[name]`
- Affected fields: [list]
- Required indexes: [specify]
- Queries: [NEVER use SELECT * — specify fields]

**2.3 Data Contract (DTO/Payload)**

Define the strict JSON input and output structure with validation rules:

**Input:**
```json
{
  "field": "string — required, min 3 chars",
  "value": "number — required, min 0"
}
```

**Output:**
```json
{
  "id": "string — UUID",
  "result": "object"
}
```

**Validation:** [Zod schema for Fastify | class-validator decorators for NestJS]

**2.4 Resilience and Zero Trust (CRITICAL)**

Define the expected behavior on failure:

| Failure Scenario | Strategy | Impact |
|---|---|---|
| Database unavailable | [e.g., Circuit Breaker, retry 3x with backoff] | [e.g., 503] |
| Queue unavailable | [e.g., Silent try/catch, log the error, return 200] | [e.g., None — secondary operation] |
| Invalid data | [e.g., Fail fast, reject with 400] | [e.g., Request rejected] |

#### 3. Visual Modeling

Generate PlantUML (text-based) diagrams when they add value:

**Sequence Diagram** — full synchronous/asynchronous interaction, including error flows.

**C4 Diagram (Level 3)** — internal components of the affected container (if not covered in plan.md).

#### 4. Execution Guidance

Operational metadata consumed by the agent (forge, clean-context executor) or by the engineer while implementing this Task. It is not a prompt to copy — it is structured information to guide execution.

**4.1 Input Context**

Files to read BEFORE implementing (order matters):
1. `src/modules/[module]/[file].ts` — [reason: understand the existing interface]
2. `src/modules/[module]/[file].spec.ts` — [reason: understand the current coverage]
3. [other reference files]

**4.2 Implementation Steps**

1. [Atomic step — e.g., "Create the Mongoose schema in `src/models/x.ts` with fields Y and Z"]
2. [Atomic step — e.g., "Add a compound index on fields Y and Z"]
3. [Atomic step]

**4.3 Validation Command**

```bash
[npm test -- --testPathPattern="[pattern]" | pnpm test | other]
```

**4.4 Negative Constraints**

Constraints **specific to this TF** (global constraints — Ironclad, `any` — are already covered by the active skills):
- DO NOT [TF-specific constraint]
- DO NOT [TF-specific constraint]

**4.5 Required Skills**

| Skill | Reason |
|---|---|
| `test-driven-agentic-development` | [e.g., TF changes business logic and requires checking impacted tests before commit] |
| [skill] | [reason] |

**4.6 Exit Criteria**

The agent MUST stop when ALL are true:
- [ ] The validation command (4.3) passes with no errors
- [ ] The files listed in 2.1 were created/changed as specified
- [ ] [Specific verifiable criterion]

If 3 consecutive attempts fail on the same criterion → escalate to the user.

**4.7 Iterative Decomposition (clean context) — OPTIONAL**

> Fill in when: the TF touches 3+ files, the DoD has 4+ criteria,
> the estimate is > 2h of implementation, or execution will be delegated
> to clean-context executors (forge, section 5).
> Simple TFs (P2, 1 file, DoD with 1-2 items) do NOT need this subsection.

**Execution mode:** `clean-context`
**Max validation cycles:** [N — default 10, forge limit]
**Saga project:** `exec:{repo}:{TF-XX-YY}`

| # | RT / iteration | Completion Criterion | Depends on |
|---|---|---|---|
| RT-01 | [Atomic action — e.g., "Create the schema and schema test"] | [Verifiable: test passes, file exists] | — |
| RT-02 | [Atomic action — e.g., "Implement the DTO with Zod validation"] | [Verifiable: DTO unit test passes] | RT-01 |
| RT-03 | [Atomic action] | [Verifiable] | RT-01 |

**Saga mapping:**

| Blueprint Concept | Saga Concept | Tool |
|---|---|---|
| TF-XX-YY | Task in the `exec:*` project epic | `task_create` |
| RT-01, RT-02... | Subtask of the task | `subtask_create` |
| RT completion criterion | Evidence comment on the subtask | `comment_add` |
| Handoff between iterations | Note of type `context` | `note_save` |

**Exit signals:**
- Every RT with status `done` in saga → TF complete
- Context rotation exhausted (1 restart) without progress → escalate to the user

#### 5. Acceptance Tests (Definition of Done)

- [ ] Happy Path Validation — [describe the specific scenario]
- [ ] Resilience Validation — [e.g., "What happens if Redis is down?"]
- [ ] Idempotency Rules — [if applicable]
- [ ] Contract Constraints — [e.g., "DTO rejects extra fields"]
- [ ] Unit test coverage for the business logic
- [ ] Integration tests for the failure path
````

---

## Priority Guide

| Priority | Description | When to Use |
|---|---|---|
| **P0** | Blocking — nothing else works without it | Database schemas, base DTOs, infra setup |
| **P1** | Essential — core functionality | UseCases, Controllers, Consumers |
| **P2** | Complementary — improvement or optimization | Cache, metrics, additional logs |

## When to Use Section 4.7 (clean context)

| Indicator | Section 4.7? |
|---|---|
| TF touches 1-2 files, DoD with 1-2 items | NO — direct execution |
| P2 TF, trivial change (constant, config) | NO |
| TF touches 3+ files in different domains | YES |
| DoD with 4+ verifiable criteria | YES |
| Estimate > 2h of implementation | YES |
| User asks for clean-context execution per subtask | YES |
| TF involves integration + logic + persistence | YES |
