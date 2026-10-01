# Principles behind the scrapup Manifesto

These principles derive from the [Manifesto](./MANIFESTO.md). The Manifesto states what we
believe; this document states what that belief requires. Skills, agents, reviews, and gates
consult it as the project's norm.

The key words MUST, MUST NOT, SHOULD, SHOULD NOT, and MAY are to be interpreted as described in
BCP 14 (RFC 2119, RFC 8174) when, and only when, they appear in all capitals. Statements are
normative; rationales are explanatory.

Where a skill, agent, tool default, or harness instruction conflicts with a principle, the
principle prevails; only a human may grant an exception, and the exception is recorded. An agent
that detects a violation stops and reports it with the principle ID instead of proceeding. Where no
mechanism upholds a principle yet, the agent escalates to a human instead of assuming
compliance.

## How to read a principle

- **ID** — stable; cite it as `P<n>`.
- **Statement** — the norm.
- **Rationale** — why it exists.
- **Traces to** — the Manifesto item it derives from (see the table below). A principle with no
  trace signals a missing belief or an out-of-scope principle.

## Manifesto references

| Ref | Manifesto item |
|---|---|
| B1 | We believe — Trust requires judgment, and judgment is human |
| B2 | We believe — Agents execute; they never govern |
| B3 | We believe — The specification is the asset, not the model |
| B4 | We believe — Software is a whole cycle |
| B5 | We believe — A decision without a name cannot be audited |
| B6 | We believe — People lead |
| V1 | We value — Trust over speed |
| V2 | We value — Evidence over declaration |
| S1–S4 | The spine — LCO, LCA, IOC, Product Release |
| CM | We commit — What you specify is what you get |
| RF | We refuse — to replace the people of product and engineering |

## Principles

### P1 — Versioned contract over loose prompt

**Statement:** Every feature MUST derive from a versioned specification (`spec.md` / `plan.md` /
`tasks.md`, or `single-tasks.md`), not from an ad-hoc prompt.

**Rationale:** The specification is what makes the result reproducible and auditable,
independent of the model that executes it.

**Traces to:** B3, CM

### P2 — Evidence before done

**Statement:** Work MUST NOT be declared done without observable evidence (command output, test
results, or a validation report) produced for that claim.

**Rationale:** A declaration is a claim; evidence is a fact.

**Traces to:** V2

### P3 — Multi-lens validation

**Statement:** Work SHOULD be reviewed from multiple independent perspectives (quality,
security, architecture, and others) before it is concluded. A perspective is independent when
it is produced by a reviewer other than the implementer, in a clean context.

**Rationale:** A single reviewer, human or agent, sees a single angle; trust needs several.

**Traces to:** B1, V1

### P4 — Humans seal the milestones

**Statement:** LCO, LCA, and Product Release MUST be sealed by a human. How IOC is sealed — by a
human or by evidence alone — is not yet decided; until it is, agents MUST NOT declare IOC sealed
and report the evidence to a human instead. A seal is an explicit go decision by a named human,
recorded in a versioned artifact. An agent MUST NOT record a seal on a human's behalf.

**Rationale:** Named milestones are the points where judgment is irreplaceable.

**Traces to:** B1, B5, S1–S4

### P5 — Agents propose risk ordering; humans approve it

**Statement:** Agents MAY propose the order in which risks are attacked; a human MUST approve
that order as part of the seal of the milestone that precedes the iteration.

**Rationale:** Proposing an order is analysis; committing to it accepts residual risk, and
accepting risk is a decision.

**Traces to:** B1, B2

### P6 — Human authorship and accountability

**Statement:** Commits and pull requests MUST carry a human author and MUST NOT attribute
authorship or co-authorship to an agent.

**Rationale:** Someone answers for the result, and that someone is a person.

**Traces to:** B6, RF

### P7 — Ceremony scales with impact

**Statement:** Process weight SHOULD match the impact of the change: the incremental flow
(`single-tasks.md`, up to 5 tasks) for low-impact work; the full flow for high-impact work or
more than 5 tasks.

**Rationale:** Trust comes from the right control at the right point, not from paperwork.

**Traces to:** V1

### P8 — Open artifacts, no lock-in

**Statement:** Artifacts (specifications, decisions, reviews) MUST stay in open, plain-text
formats under version control; generated binaries MUST have a versioned plain-text source.
Specifications MUST NOT require a specific model or vendor to be read or executed.

**Rationale:** If the specification is the asset, nothing can hold it hostage.

**Traces to:** B3

### P9 — The cycle reaches production

**Statement:** After release, delivery SHOULD include a verification of the feature in the
user's environment (Transition) before the work is considered complete.

**Rationale:** Software is not done until it works where it matters.

**Traces to:** B4, S4

### P10 — Lineage declared

**Statement:** scrapup's lineage from the Unified Process, and the degree of fidelity to it,
MUST be declared in an Architecture Decision Record.

**Rationale:** The milestone names come from the Unified Process; how much else is inherited is
a decision, and decisions need names.

**Traces to:** B5
