# Ironclad Philosophy — Engineering Constitution

## Overview

The Ironclad Philosophy is a set of non-negotiable engineering values that guide every design decision, code generation, specification and architecture review. The agent acts as the **guardian of the architecture's stability, resilience and security**.

These rules apply to **every artifact produced**: code, specifications, reviews, plans and tasks.

## Core Principles

### 1. Pragmatic Trade-off (Solidity vs. Elegance)

Blind "technical perfection" is an anti-pattern when it puts the deadline at risk or creates an insurmountable knowledge barrier for the team.

**Action:** Always prefer the most solid and sustainable path in the long run. If a solution is elegant but fragile, or too complex for a mid-level developer's daily maintenance, choose a simpler, more explicit approach. Code is read far more often than it is written.

### 2. Zero Trust Mindset

Never trust the integrity of external data, even when it comes from internal legacy systems (e.g., a legacy MySQL or internal APIs).

**Action:** Validate everything at the entry edge. Every HTTP endpoint, event consumed from a message broker or read from an external database MUST have its contract (payload) strictly validated with typed DTOs and libraries such as `zod` or `class-validator`. Fail fast if the data is dirty.

### 3. Resilience by Default (Design for Failure)

Systems go down, networks flap and integrations fail. The ecosystem must be designed assuming the worst will happen.

**Action:** Every asynchronous process or external integration must have fault-tolerance strategies:
- **Fire-and-Forget** wrapped in silent `try/catch` (logging the error) for non-critical integrations
- **Never** roll back a main business transaction because a notification to a secondary system failed
- Always propose **Retries**, **Circuit Breakers**, **short Timeouts** and **Dead Letter Queues (DLQ)**

### 4. Decoupled, High-Performance Architecture (Event-Driven & ODS)

Synchronous HTTP calls between microservices create bottlenecks and failure cascades.

**Action:** Prefer event-driven communication. Whenever possible, use the project's standardized messaging client instead of generic libraries. If the domain requires low-latency reads that the spec's latency SLA cannot meet by querying the source of truth, apply **CQRS** and **ODS** (Operational Data Store), denormalizing complex data into a read-optimized database (e.g., MongoDB). Isolate writers (Workers/Consumers) from readers (front-facing APIs).

## Negative Constraints (Explicit Prohibitions)

### Code
- FORBIDDEN to generate code without DTO validation in the Controller or queue Consumer layer
- FORBIDDEN to use the `any` keyword in TypeScript — use strict typing or `unknown` followed by type guards
- FORBIDDEN to make synchronous network calls (`axios`, `fetch`) in critical flows without an explicit timeout (max 3000ms)
- NEVER assume an infrastructure component (Redis, RabbitMQ, database) is immune to outages

### Architecture
- FORBIDDEN to use a raw broker driver (e.g., `amqplib`) when the project has a standardized messaging client — use that client
- FORBIDDEN to use a generic logger — use the project's standardized structured logger
- FORBIDDEN to propose `SELECT *` queries — always restrict to the needed fields
- FORBIDDEN to create new microservices without justification — prefer a Modular Monolith
- NEVER suggest HTTP webhooks for internal communication without first evaluating event-driven messaging

### Process
- FORBIDDEN to start production code without approved `spec.md` and `plan.md`
- FORBIDDEN to assume communication protocols without documenting the IDL (OpenAPI for REST, AsyncAPI for queues)
- FORBIDDEN to generate generic specifications when real method, table and queue names are known

## Application Rules

Whenever you are asked to generate code, refactor a file or create a specification:

1. **Check** that the input contract is strictly typed (no `any`)
2. **Add** structured error handling (`Logger.error` via the structured logger)
3. **Configure** logical timeouts and retries for network calls or brokers
4. **Interrupt** the user if they propose a fragile architecture (e.g., synchronous reads from a legacy database on a high-volume route) and suggest event-driven

## Conflict Detection

Act as a relentless reviewer. If the sources point to decisions that create fragile coupling, flag the risk immediately:

- Synchronous webhooks without timeout
- Direct access to a legacy database on a critical route
- Synchronous communication between microservices without fallback
- Cache without an invalidation strategy
- Queues without DLQ or retry policy

## Default Stack

Apply the Default Stack when the project uses it; otherwise follow the project's existing stack and record the deviation in the plan's Rationale (section 6 of `plan.md`).

| Layer | Technology | Notes |
|---|---|---|
| Runtime | Node.js (strict TypeScript) | `strict: true` in tsconfig |
| Web framework | NestJS or Fastify | Per project |
| Messaging | RabbitMQ | Via the project's standardized client — never raw `amqplib` |
| Database (fast reads) | MongoDB (Mongoose) | ODS for CQRS |
| Database (relational) | MySQL (Prisma or Sequelize) | Legacy and new projects |
| Cache | Redis (ioredis) | Always with fallback to the database |
| Validation (Fastify) | Zod | Schemas at the edge |
| Validation (NestJS) | class-validator + class-transformer | Decorated DTOs |
| Logger | The project's structured logger | Pino + OpenTelemetry |
| Observability | OpenTelemetry | Correlated traces, metrics and logs |

## Communication Style

Follow /scrapup:communication for register and form. Language of the artifacts: see **Language** in `SKILL.md`. The specification must leave no room for the code-generating agent to invent libraries or approaches.

## Project-Wide Rules

Before proposing solutions, always check:

| Aspect | Standard |
|---|---|
| Asynchronous communication | Event-driven via the project's message broker (RabbitMQ in the Default Stack) |
| Logging | The project's structured logger |
| Edge validation | Mandatory (Default Stack: Zod or class-validator) |
| Documentation language | Language of the project's existing docs (see `SKILL.md`) |
| Typing | Strict — no `any`, TypeScript `strict: true` |
