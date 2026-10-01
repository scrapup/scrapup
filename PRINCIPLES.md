# Principles behind the scrapup Manifesto

These principles derive from the [Manifesto](./MANIFESTO.md). The Manifesto states what we
believe; this document states what that belief requires. Skills, agents, reviews, and gates
consult it as the project's norm.

The key words MUST, MUST NOT, SHOULD, and MAY are to be interpreted as described in RFC 2119.

## How to read a principle

- **ID** — stable; cite it as `P<n>`.
- **Statement** — the norm.
- **Rationale** — why it exists.
- **Traces to** — the Manifesto belief (B1–B6), value (V1–V2), promise (PR), or refusal (RF) it
  derives from. A principle with no trace signals a missing belief or an out-of-scope principle.
- **Status** — `enforced` (names what upholds it) or `aspirational` (declared, not yet upheld).

## Manifesto references

| Ref | Manifesto item |
|---|---|
| B1 | Trust requires judgment, and judgment is human |
| B2 | Agents execute; they never govern |
| B3 | The specification is the asset, not the model |
| B4 | Software is a whole cycle |
| B5 | A decision without a name cannot be audited |
| B6 | There are roles where we are needed — product, architecture, validation |
| V1 | Trust over speed |
| V2 | Evidence over declaration |
| PR | What you specify is what you get |
| RF | We refuse to replace the people of product and engineering |

## Principles

### P1 — Versioned contract over loose prompt

**Statement:** Every feature MUST derive from a versioned specification, not from an ad-hoc
prompt.

**Rationale:** The specification is what makes the result reproducible and auditable,
independent of the model that executes it.

**Traces to:** B3, PR

**Status:** enforced — `skills/blueprint` (full flow or `single-tasks.md`)

### P2 — Evidence before done

**Statement:** No work MAY be declared done without observable evidence (command output, test
results, validation reports).

**Rationale:** A declaration is a claim; evidence is a fact.

**Traces to:** V2

**Status:** enforced — `skills/verification-before-completion`

### P3 — Multi-lens validation

**Statement:** Work SHOULD be reviewed from multiple independent perspectives (quality,
security, architecture, and others) before it is concluded.

**Rationale:** A single reviewer, human or agent, sees a single angle; trust needs several.

**Traces to:** B1, V1

**Status:** aspirational — review lenses are not yet published in this repository

### P4 — Humans seal the milestones

**Statement:** LCO, LCA, and Product Release MUST be sealed by a human. How IOC is sealed —
by a human or by evidence alone — is not yet decided.

**Rationale:** Named milestones are the points where judgment is irreplaceable.

**Traces to:** B1, B5

**Status:** aspirational

### P5 — Agents propose risk ordering; humans approve it

**Statement:** Agents MAY propose the order in which risks are attacked; a human MUST approve
that order as part of the milestone seal.

**Rationale:** Ordering is execution; accepting the risk is a decision.

**Traces to:** B2, B1

**Status:** aspirational

### P6 — Human authorship and accountability

**Statement:** Delivered work MUST carry human authorship. Commits MUST NOT attribute
co-authorship to an agent.

**Rationale:** Someone answers for the result, and that someone is a person.

**Traces to:** B6, RF

**Status:** enforced — `skills/commit-writer`

### P7 — Ceremony scales with risk

**Statement:** Process weight SHOULD match the impact of the change: a lean increment for small
work, the full flow only for high-impact work.

**Rationale:** Trust comes from the right control at the right point, not from paperwork.

**Traces to:** V1

**Status:** enforced — `skills/blueprint` (incremental flow vs. full flow)

### P8 — Open tooling, no lock-in

**Statement:** Artifacts MUST stay in open, plain-text formats under version control, and the
process MUST NOT depend on a single model or vendor.

**Rationale:** If the specification is the asset, nothing may hold it hostage.

**Traces to:** B3

**Status:** enforced — repository conventions (MIT license, markdown, git)

### P9 — The cycle reaches production

**Statement:** The process SHOULD verify delivered features in the user's environment after
release (Transition), not stop at implementation.

**Rationale:** Software is not done until it works where it matters.

**Traces to:** B4

**Status:** aspirational

### P10 — Lineage declared

**Statement:** scrapup's lineage from the Unified Process, and the degree of fidelity to it,
MUST be declared in an Architecture Decision Record.

**Rationale:** The milestone names come from the Unified Process; how much else is inherited is
a decision, and decisions need names.

**Traces to:** B5

**Status:** aspirational — ADR not yet written
