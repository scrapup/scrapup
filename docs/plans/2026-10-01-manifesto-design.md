# Manifesto — design

> Design approved 2026-10-01 after a brainstorming session with the founder. Defines the form,
> content map, placement, and validation of the scrapup manifesto. No manifesto text is drafted
> here; drafting is the implementation step.

## Context / Problem

scrapup's objective is stated in descriptive documents (product objective, `CLAUDE.md`,
`README`) that answer **what** the product does and **how** it works. None states **why** —
what we believe about software, agents, and the people who build software. Those documents
change with the product; the beliefs should not.

The manifesto becomes the pillar of scrapup: the base document from which future artifacts
derive. It is **aspirational**, describes the idea rather than any implementation, and is
public.

Founding narrative: on a highly specified public-tender system, small slices of specification
(use-case specs, sequence diagrams, ER models) let external developers work autonomously; the
remaining bottleneck was construction time. Agents now remove that bottleneck — provided the
work is well specified.

## Approach

Three forms were weighed:

| Form | Verdict |
|---|---|
| A. Short declaration (Agile-style) | Memorable and signable, but cannot carry the origin or the human figure |
| B. Narrative essay | Moving, but long, hard to quote, unusable as a norm by agents |
| **C. Layered (chosen)** | A one-page public core **+** a derived, normative principles layer that agents and gates consult |

C was chosen because it is the founder's first decision — "constitution + public declaration" —
turned into form.

Decisions that bind the design:

| Decision | Choice |
|---|---|
| Founding beliefs | Developer dignity + speed without trust → *trust requires judgment, and judgment is human* |
| Agents | Execute, never govern |
| Never delegated | Sealing milestones · deciding the architecture · answering for the result |
| Risk ordering | Agent proposes, human approves within the milestone seal |
| Core values | Trust over speed · Evidence over declaration |
| Scope | The whole cycle: from the basic idea to the product in production |
| Abstraction | Aspirational, not mechanical — no milestone mechanics in the core |
| Tone | Affirmative; no named adversary; AI amplifies, it does not end the world |
| Promise | *What you specify is what you get* — in both directions (aspirational) |
| Refusal | Replacing product and engineering people — a tool, like a hammer |
| Spec as asset | *The specification is the asset, not the model* — in the core |
| Human roles in core | Plain names: product, architecture, validation |
| Idea vs. implementation | The core names no runtime, vendor, or product form (plugin and a future agentic development platform are implementations of the same idea) |
| Voice | "We" throughout — the we of signatories, an open invitation |
| UP | Not named in the core; present as vocabulary through the milestone names; lineage and fidelity go to the principles layer and an ADR |

## Architecture & components

### Core — `MANIFESTO.md` (one page, ≤ ~450 words)

| # | Block | Content |
|---|---|---|
| 1 | Title + north star | From scrap to trusted, forged delivery |
| 2 | Preamble (3–5 sentences) | We have seen well-specified work set builders free; AI makes execution cheap but not trustworthy; AI amplifies; human effort belongs in the right place |
| 3 | We believe (5–6) | Trust requires judgment, and judgment is human · Agents execute; they never govern · The specification is the asset, not the model · Software is a whole cycle, from idea to production · A decision without a name cannot be audited · There are roles where we are needed: product, architecture, validation |
| 4 | We value | Trust over speed · Evidence over declaration — while there is value in the items on the right |
| 5 | The spine | LCO, LCA, IOC, Product Release — one aspirational sentence each on what it guarantees, no mechanics |
| 6 | We promise | What you specify is what you get — in both directions |
| 7 | We refuse | To replace the people of product and engineering |
| 8 | Signatories | Founder's name and date; open to co-signers |

Excluded from the core: milestone mechanics (including who seals IOC), risk-ordering mechanics,
UP fidelity, runtime/vendor/product-form names, personal stories beyond the founding narrative.

### Principles — `PRINCIPLES.md` (English only, normative)

Named *Principles* to avoid ambiguity with Spec Kit's *constitution*. Each principle has:

| Field | Content |
|---|---|
| ID | `P1`, `P2`, … — stable, citable by skills and reviews |
| Statement | One normative sentence using RFC 2119 MUST/SHOULD |
| Rationale | One or two sentences |
| Traces to | Core belief, value, or promise it derives from |
| Status | `enforced` (naming the skill/agent/gate) or `aspirational` |

Seed list (~10, wording to be drafted): versioned contract over loose prompt · evidence before
done · multi-lens validation · human seals LCO/LCA/Release (IOC mechanics open) · agent
proposes risk ordering, human approves · human authorship and accountability · ceremony scales
with risk · open tooling, no model/vendor lock-in · the cycle covers Transition · UP lineage and
fidelity declared in an ADR.

Rules: a principle with no trace signals a missing belief or an out-of-scope principle; start
small; mechanics enter here when mature, never in the core.

### Placement & localization

| Artifact | Path | Language |
|---|---|---|
| Core | `MANIFESTO.md`, `MANIFESTO.pt.md`, `MANIFESTO.ja.md` (repo root) | EN source; PT/JA replicate the EN diff in the same commit; language nav line; identical structure |
| Principles | `PRINCIPLES.md` (repo root) | EN only |
| README ×3 | One link line after the tagline | EN/PT/JA |
| Landing (`scrapup.dev`) | Section or page with the core | Follow-up, outside this repo |

## Data flow

1. **Beliefs → core:** each core block maps to recorded decisions.
2. **Core → principles:** each principle traces to a core belief, value, or promise.
3. **Principles → tooling:** each `enforced` principle names the skill, agent, or gate that
   upholds it; linking skills to principle IDs is roadmap.
4. **Core → anchors:** the product objective (Alignment hook) and both `CLAUDE.md` files cite
   the manifesto as the source of beliefs.
5. **EN → PT/JA:** every core change is replicated in the same commit.

Lifecycle: core changes are rare, by PR sealed by the founder, dated, committed as
`docs(manifesto):` (no release bump). Principle changes are more frequent; every PR states the
`Traces to`. Co-signing is a PR adding a name to *Signatories* — the commit is the auditable
signature.

## Error handling

| Failure mode | Handling |
|---|---|
| Core drifts into mechanics or product names | Deterministic check (see Testing) blocks; content moves to principles or README |
| Orphan principle | Flag: add the missing belief to the core or drop the principle |
| Declared ≠ existing | `Status: aspirational` keeps the delta explicit; the objective keeps tracking it |
| PT/JA drift from EN | Same-commit rule; structural diff check |
| Exposure of people or private history | Ethics review + deterministic scan |
| Existing docs contradict the manifesto | Corrections land in the same work (below) |

Corrections that land with this work:

| Document | Correction |
|---|---|
| Workspace and repo `CLAUDE.md`, product objective | UP from "immutable / foundation" to lineage and vocabulary (fidelity → ADR); risk ordering → agent proposes, human approves; "humans seal every milestone" → pending until IOC mechanics are decided |
| Workspace `CLAUDE.md`, product objective, landing brief, sealed-tooling doc | Spec Kit description updated: idea assessment (go/clarify/stop), three independent workflows, `converge`; no release/production phase |
| Repo and workspace `CLAUDE.md` | Localization surface now includes the manifesto, not only the README |

## Testing

Deterministic checks, run with evidence:

| Check | Criterion |
|---|---|
| Traceability | Every core block maps to a decision; every principle has a valid `Traces to` |
| Implementation independence | Core contains no "Claude Code", "plugin", "platform", "ADP", "MCP", vendor or model names |
| Affirmative tone | Core names no competitor or adversary |
| Voice | Core is in "we" throughout |
| Length | Core ≤ ~450 words |
| Localization | Three core files share headings and order; nav line correct; current language bold and unlinked |
| Document coherence | All listed corrections applied |

Review lenses: `reviewer-prompt-engineering` (PRINCIPLES.md clarity for agents),
`reviewer-ethics` (exposure, misleading promises, licensing), `reviewer-homogeneity` (repo
conventions).

Human seal: the founder reads the core aloud in the three languages and signs. Without the
signature, nothing reaches `main`.
