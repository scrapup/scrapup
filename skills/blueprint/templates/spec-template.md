# Template: Functional Specification (spec.md) — Phase 1

## Usage Context

This template guides the creation of the `spec.md` artifact, the first phase of Spec-Driven Development.
The focus is exclusively on **business intent**: what will be built and why.

Save as: `/docs/specs/<feature-name>/spec.md`

## Phase 1 Constraints

- **FORBIDDEN** to mention databases (MongoDB, MySQL), languages (Node.js, TypeScript) or infrastructure (RabbitMQ, Redis)
- **FORBIDDEN** to include C4 diagrams, database schemas or library names
- **NEVER** assume critical business rules without user confirmation
- Absolute focus on **What** and **Why**, never on **How**

## Discovery Mode (Pre-Generation)

Before filling the template, check that you have answers to:

1. What business problem originates this feature?
2. Who are the actors (users, systems) involved?
3. What are the non-negotiable limits (critical business rules)?
4. What happens when input data is invalid or systems fail?
5. Are there performance SLAs or expected volume?

If answers are missing, ask the user per the **Blocking Information Rule** (see **Discovery Mode** in `SKILL.md`) before generating the artifact.

---

## Template

```markdown
# Functional Specification: [Feature Name]

## 1. Overview and Goal

- **The Problem:** [What is the current pain of the business or the user?]
- **The Solution (What):** [What will be built, technology-agnostic]
- **The Value (Why):** [Expected impact — e.g., higher sales, error elimination, reduced operational time]

## 2. User Journeys

Describe the step-by-step narrative flow for each actor involved.

**Main Journey:**
1. [Actor] performs [action]
2. The system [reaction]
3. The system [next step]
4. [Expected final result]

**Alternative Journey (if applicable):**
1. [Variation of the main flow]

## 3. Business Rules and Constraints

List the non-negotiable limits. What the system MUST do and what it MUST NOT do.

| # | Rule | Type |
|---|---|---|
| BR-01 | [Rule description] | Mandatory |
| BR-02 | [Rule description] | Restrictive |
| BR-03 | [Rule description] | Conditional |

## 4. Edge Cases and Exception Flows (Zero Trust)

Define the exact system behavior for failure scenarios. Never assume external data is trustworthy.

| Scenario | Expected Behavior | Severity |
|---|---|---|
| Invalid input data | [e.g., Reject with a validation error] | Critical |
| External system unavailable | [e.g., Return a fallback or enqueue for retry] | High |
| Duplicate data received | [e.g., Idempotency — ignore the duplicate] | Medium |
| Operation timeout | [e.g., Fail fast, log and notify] | High |
| [Domain-specific scenario] | [Behavior] | [Severity] |

## 5. Success Criteria and SLAs

How do we validate that the delivery is complete and performant?

**Functional Criteria:**
- [ ] [e.g., Every user journey runs successfully]
- [ ] [e.g., Business rules BR-01 to BR-03 validated]

**Performance SLAs:**
- Latency: [e.g., < [X]ms at P95]
- Throughput: [e.g., Sustain 50 req/s at peak]
- Availability: [e.g., 99.9% uptime]

**Quality Criteria:**
- [ ] Unit test coverage > [X]%
- [ ] Integration tests for every edge case

## 6. Glossary

Define domain terms that may be interpreted ambiguously across stakeholders.

| Term | Definition in this context |
|---|---|
| [Term 1] | [Precise definition for this project] |
| [Term 2] | [Precise definition for this project] |
```

---

## Usage Example

**Scenario:** library book reservation system.

```markdown
# Functional Specification: Book Reservation

## 1. Overview and Goal
- **The Problem:** Reservations are recorded manually at the front desk, causing double bookings and waits of up to 2 days.
- **The Solution:** A self-service reservation flow that checks availability, member status and active holds.
- **The Value:** Reservation confirmed in the same session, eliminating double bookings.

## 4. Edge Cases (Zero Trust)
| Scenario | Expected Behavior | Severity |
|---|---|---|
| Invalid member ID | Reject with a validation error | Critical |
| No copy available | Offer a waitlist position without failing the request | Medium |
| Catalog unavailable | Tell the member the reservation cannot be confirmed now and to try again later | High |
```
