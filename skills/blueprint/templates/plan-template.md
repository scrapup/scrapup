# Template: Technical Plan (plan.md) — Phase 2

## Usage Context

This template guides the creation of the `plan.md` artifact, the second phase of Spec-Driven Development.
The focus is the **real architecture**: how the specification will be implemented systemically.

Save as: `/docs/specs/<feature-name>/plan.md`

**Mandatory prerequisite:** `spec.md` approved by the user.

## Phase 2 Constraints

- **FORBIDDEN** to write TypeScript/JavaScript implementation code — generate only Markdown, JSON schemas for DTOs and PlantUML code
- **NEVER** assume new microservices without need — prefer a Modular Monolith (separate modules in the same deploy)
- **NEVER** suggest a raw broker driver (e.g., `amqplib`) when the project has a standardized messaging client — use that client
- **NEVER** propose `SELECT *` queries — restrict to the needed fields
- **NEVER** assume communication protocols without documenting the corresponding IDL

## Prerequisites Check

Before generating `plan.md`, check in `spec.md`:

1. Are volume and performance bottlenecks defined?
2. Are latency SLAs clear?
3. Were edge cases mapped?

If volume or SLA information is missing, ask the user **before** deciding between a synchronous (HTTP) and an asynchronous (Worker/Queue) approach.

## Architectural Principles

**Stack:** apply the **Default Stack** ([philosophy.md](../philosophy.md)) when the project uses it; otherwise follow the project's existing stack and record the deviation in section 6 (Rationale and Trade-offs).

Apply these principles when designing the solution:

1. **Event-Driven First:** integrations between legacy and new systems should be asynchronous via the project's message broker (RabbitMQ in the Default Stack), unless explicitly justified
2. **Fast Reads (CQRS/ODS):** if the latency SLA in `spec.md` cannot be met by querying the source of truth, denormalize data into an Operational Data Store (MongoDB in the Default Stack) for reads, isolating writers (Workers) from readers (APIs)
3. **Resilience by Design:** every asynchronous flow must cover DLQ, Retry policies and Fire-and-forget. Failures in secondary integrations must not roll back main operations
4. **Zero Trust:** input contracts (REST or queues) must require strict validation (Default Stack: Zod or class-validator)

---

## Template

```markdown
# Technical Plan: [Feature Name]

## 1. Architecture Overview

Executive summary of how the feature described in `spec.md` will be implemented.

- **Main Decision:** [e.g., New module in the monorepo | New broker consumer | New Mongo collection]
- **Approach:** [e.g., Event-driven with ODS for reads | Synchronous REST with Redis cache]
- **Affected Repository(ies):** [Exact repository name(s)]

## 2. Solution Diagrams

### 2.1 C4 Diagram — Level 2 (Containers)

Shows the system containers, external integrations and infrastructure.

[Generate in PlantUML — NEVER link to external images]

### 2.2 C4 Diagram — Level 3 (Components)

Shows how classes, services and databases interact inside the main container.

[Generate in PlantUML]

### 2.3 Sequence Diagram

Shows the exact flow, including database calls and messaging dispatches.
Must show both the **success path** and the **failure path**.

[Generate in PlantUML]

### 2.4 Envelope/Traceability Diagram (when there is messaging)

Shows the message format on the queue, the logs emitted at each step, the spans/wide events, and how to trace the flow end to end in the project's observability stack.

[Generate in PlantUML — omit this subsection when there is no messaging]

## 3. Data Modeling and Persistence

### 3.1 Schemas/Models

[For MongoDB — Mongoose Schema]
[For MySQL — Table with fields, types and constraints]

| Field | Type | Required | Description |
|---|---|---|---|
| `_id` | ObjectId | Yes | Unique identifier |
| `[field]` | [type] | [Yes/No] | [description] |
| `createdAt` | Date | Yes | Creation date |
| `updatedAt` | Date | Yes | Update date |

### 3.2 Indexes

| Index | Fields | Type | Rationale |
|---|---|---|---|
| `idx_[name]` | `{ field: 1 }` | [Unique/Compound/TTL] | [Why this index is needed] |

### 3.3 Migrations

[Describe the required migrations if an existing schema changes]

## 4. Integration Contracts (IDL / Interfaces)

### 4.1 Synchronous APIs (REST)

**Endpoint:** `[METHOD] /api/v1/[resource]`

**Request:**
```json
{
  "field": "type — validation rule"
}
```

**Response (success):**
```json
{
  "field": "type"
}
```

**Response (error):**
```json
{
  "statusCode": 400,
  "error": "Bad Request",
  "message": "error description"
}
```

**Required headers:** [e.g., `x-api-key`, `Authorization: Bearer`]

### 4.2 Messaging (message broker)

| Property | Value |
|---|---|
| Exchange | `[exchange-name]` |
| Routing Key | `[routing.key.pattern]` |
| Queue | `[queue-name]` |
| DLQ | `[queue-name].dlq` |
| Retry Policy | [e.g., 3 attempts with exponential backoff] |

**Payload:**
```json
{
  "field": "type — validation rule"
}
```

**Envelope and traceability:** [the project's message envelope, if any — record how the correlation/trace ID, idempotency key and schema version travel with the message; see diagram 2.4]

## 5. Resilience, Security and Error Handling

### 5.1 Failure Matrix

| Component | Failure Type | Strategy | User Impact |
|---|---|---|---|
| Database | Timeout/unavailable | [e.g., Circuit Breaker + retry 3x] | [e.g., 503 with retry-after] |
| Message broker | Unavailable | [e.g., Silent try/catch, do not block the main transaction] | [e.g., None — secondary operation] |
| External API | Timeout | [e.g., 3000ms timeout + cache fallback] | [e.g., Stale data for up to 5min] |
| Redis (cache) | Unavailable | [e.g., Bypass cache, query the database directly] | [e.g., Degraded latency] |

### 5.2 Security

- Authentication: [e.g., JWT via middleware, API Key via header]
- Authorization: [e.g., RBAC, scopes]
- Input validation: [e.g., Zod schema in the controller, class-validator in the DTO]
- Sensitive data: [e.g., Never log tax IDs, tokens, passwords]

### 5.3 Observability

Define which metrics, logs and traces will be emitted for monitoring and diagnosis.

| Type | Name/Pattern | When to Emit | Purpose |
|---|---|---|---|
| Metric | `[metric.name]` | [Triggering event] | [Dashboard/Alert] |
| Log (error) | `[log.pattern]` | [Failure scenario] | [SRE alert] |
| Log (info) | `[log.pattern]` | [Business event] | [Audit/Debug] |
| Trace | span `[spanName]` | [Flow start/end] | [P95 latency] |

**Tools:** the project's structured logger and tracing stack (Default Stack: Pino + OpenTelemetry)

## 6. Rationale and Trade-offs

Explain **why** this architecture was chosen. What cost/benefit was accepted?

| Decision | Discarded Alternative | Rationale |
|---|---|---|
| [e.g., Denormalize into an ODS] | [e.g., Read directly from the legacy database] | [e.g., P95 latency SLA from spec.md unachievable with complex joins] |
| [e.g., Use the message broker] | [e.g., HTTP webhook] | [e.g., Native resilience and retries] |
| [e.g., Deviation from the Default Stack] | [Default Stack component] | [Why the project's existing stack was kept] |
```

---

## PlantUML Diagrams

Generate every diagram with /scrapup:expert-plantuml (C4 L2, C4 L3, Sequence success + failure, Envelope/Traceability when there is messaging). Do not copy boilerplate here — the skill owns the syntax and the "Done when" checklist.
