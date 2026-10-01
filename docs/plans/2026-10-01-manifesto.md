# Manifesto Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use /scrapforge:executing-plans to implement this plan task-by-task.

**Goal:** Publish the scrapup manifesto (one-page public core in EN/PT/JA + a normative
`PRINCIPLES.md`), link and package it, and correct every existing document that contradicts it.

**Architecture:** Two layers, per the approved design
(`docs/plans/2026-10-01-manifesto-design.md`): `MANIFESTO.md` (+ `.pt.md`, `.ja.md`) states
beliefs in "we" voice with no product/runtime names; `PRINCIPLES.md` (EN only) holds numbered,
traceable, normative principles. Existing docs in this repo and in the non-versioned workspace
root (`~/Develop/scrapup`) are realigned.

**Tech Stack:** Markdown, bash (`grep`, `wc`, `diff`), git. No code.

**Inputs the implementer must read first:**

- Design: `docs/plans/2026-10-01-manifesto-design.md` (this repo).
- Session record (internal, non-versioned):
  `~/Develop/scrapup/docs/vision/2026-10-01-manifesto-brainstorm-context.md` — decisions 1–13.
- Conventions: `CLAUDE.md` (this repo) → *Conventions*; `CONTRIBUTING.md` → *Language*.

**Hard rules (apply to every task):**

- All artifacts in English, except `MANIFESTO.pt.md` / `MANIFESTO.ja.md`.
- `git add` only the files listed in the task, by name. Never `git add .` / `-A`.
- Commits: Conventional Commits, English, **no** `Co-Authored-By` / "Generated with" trailer.
  After each commit run `git log -1 --format=%B | grep -iE 'co-authored-by|generated with'`
  → expected: no output.
- Files under `~/Develop/scrapup/` outside `scrapup/` are **not** in git: edit, never commit.
- The founder is the human Validator: Task 2 and Task 9 are blocking checkpoints. Do not
  proceed past them without explicit approval.

Working directory for all commands unless stated: `~/Develop/scrapup/scrapup`.

---

### Task 1: Draft the English core (`MANIFESTO.md`)

**Files:**
- Create: `MANIFESTO.md`

**Step 1: Run the checks to verify they fail (file absent)**

Run:
```bash
test -f MANIFESTO.md && echo present || echo absent
```
Expected: `absent`

**Step 2: Write the draft**

Create `MANIFESTO.md` with exactly this content:

```markdown
# The scrapup Manifesto

🌐 **English** | [日本語](./MANIFESTO.ja.md) | [Português](./MANIFESTO.pt.md)

> From scrap to forged, trusted delivery.

## Preamble

We have seen well-specified work set its builders free: given clear use cases, sequences, and
models, people far from the original idea built it faithfully and on their own. Today, AI makes
building cheap — but not yet trustworthy. AI will not end our craft; it amplifies it. What it
amplifies depends on where we put our human effort. We put it where judgment lives.

## We believe

- **Trust requires judgment, and judgment is human.**
- **Agents execute; they never govern.**
- **The specification is the asset, not the model.**
- **Software is a whole cycle** — from the first idea to the product working in production.
- **A decision without a name cannot be audited.**
- **There are roles where we are needed** — product, architecture, validation.

## We value

**Trust** over speed.
**Evidence** over declaration.

That is, while there is value in the items on the right, we value the items on the left more.

## The spine

Four named decisions carry an idea to production:

- **Lifecycle Objectives (LCO)** — we know why we build and what is worth building.
- **Lifecycle Architecture (LCA)** — the architecture is proven, not drawn.
- **Initial Operational Capability (IOC)** — what was specified is built, and evidence proves it.
- **Product Release** — it works where it matters: in the hands of its users.

## We promise

**What you specify is what you get.** What is specified is built; what is built was specified.

## We refuse

To replace the people of product and engineering. scrapup is a tool, as a hammer is a tool — only
as good as the hand and the judgment that hold it.

## Signatories

- Marco Antonio Luqueti Faustino — SIGNING_DATE

To co-sign, open a pull request that adds your name to this list. The commit is your signature.
```

Replace `SIGNING_DATE` with the output of `date +%F`.

**Step 3: Run the core checks**

Run each; every expected result must hold:

```bash
# Length (≤ 450 words)
wc -w < MANIFESTO.md
# Expected: a number ≤ 450

# Implementation independence + affirmative tone (no product/runtime/vendor/competitor names)
grep -n -i -E 'claude|plugin|platform|\bADP\b|\bMCP\b|anthropic|openai|gpt|gemini|spec ?kit|kiro|tessl|superpowers|vibe' MANIFESTO.md
# Expected: no output

# Voice: "we" only, no first-person singular
grep -n -w -E 'I|my|me|mine' MANIFESTO.md
# Expected: no output

# Exposure: no trace of the removed personal story
grep -n -i -E 'pull request war|battlefield|30 (pull requests|PRs)' MANIFESTO.md
# Expected: no output

# Structure: 1 title + 7 sections
grep -c -E '^#{1,2} ' MANIFESTO.md
# Expected: 8

# Placeholder replaced
grep -n 'SIGNING_DATE' MANIFESTO.md
# Expected: no output
```

**Step 4: Do not commit yet.** The same-commit localization rule requires EN, PT, and JA together
(Task 3).

---

### Task 2: CHECKPOINT — founder approves the English core

**Step 1:** Show the founder the full `MANIFESTO.md` and the traceability table below. Ask for
approval or edits. Apply edits to `MANIFESTO.md` only, then re-run Task 1 Step 3.

| Block | Traces to (session record decision) |
|---|---|
| North star | Objective north star; 2 |
| Preamble | Founding narrative (public-tender origin); 2; 9 |
| We believe 1–6 | 2 · 3 · 13 · 7 · milestone spine · 11d |
| We value | 5 |
| The spine | 7; 8 (aspirational, no mechanics) |
| We promise | 10; 12 |
| We refuse | 11 |
| Signatories | 11e |

**Step 2:** Proceed only after explicit approval. Translations in Task 3 are made from the
**approved** EN text.

---

### Task 3: Translate the core (`MANIFESTO.pt.md`, `MANIFESTO.ja.md`) and commit all three

**Files:**
- Create: `MANIFESTO.pt.md`
- Create: `MANIFESTO.ja.md`

**Step 1: Write the structural-parity check and see it fail**

Run:
```bash
for f in MANIFESTO.md MANIFESTO.pt.md MANIFESTO.ja.md; do
  printf '%s headings=%s bullets=%s\n' "$f" \
    "$(grep -c -E '^#{1,2} ' "$f" 2>/dev/null)" "$(grep -c -E '^- ' "$f" 2>/dev/null)"
done
```
Expected: PT and JA lines report missing files / empty counts.

**Step 2: Write `MANIFESTO.pt.md`**

Translate prose only; same blocks, order, bullets, and links as EN. Keep in English: *scrapup*,
the milestone names and acronyms (*Lifecycle Objectives (LCO)*, *Lifecycle Architecture (LCA)*,
*Initial Operational Capability (IOC)*, *Product Release*), *pull request*, *commit*. Use these
fixed lines:

```markdown
# Manifesto do scrapup

🌐 [English](./MANIFESTO.md) | [日本語](./MANIFESTO.ja.md) | **Português**
```

Section headings, in order: `## Preâmbulo`, `## Nós acreditamos`, `## Nós valorizamos`,
`## A espinha`, `## Nós prometemos`, `## Nós recusamos`, `## Signatários`.
Values block: `**Confiança** acima de velocidade.` / `**Evidência** acima de declaração.`
Promise: `**O que você especifica é o que você recebe.**`
Signatory line: identical name and date to EN.

**Step 3: Write `MANIFESTO.ja.md`**

Same rules. Fixed lines:

```markdown
# scrapup マニフェスト

🌐 [English](./MANIFESTO.md) | **日本語** | [Português](./MANIFESTO.pt.md)
```

Section headings, in order: `## 前文`, `## 私たちは信じる`, `## 私たちが重んじるもの`,
`## 背骨`, `## 私たちの約束`, `## 私たちが拒むもの`, `## 署名者`.

**Step 4: Run the parity and content checks**

```bash
for f in MANIFESTO.md MANIFESTO.pt.md MANIFESTO.ja.md; do
  printf '%s headings=%s bullets=%s\n' "$f" "$(grep -c -E '^#{1,2} ' "$f")" "$(grep -c -E '^- ' "$f")"
done
# Expected: all three show headings=8 and the same bullets count (11 for the approved draft)

grep -n '🌐' MANIFESTO.md MANIFESTO.pt.md MANIFESTO.ja.md
# Expected: each file's own language is bold and unlinked; the other two are links to MANIFESTO.*.md

grep -n -i -E 'claude|plugin|\bADP\b|\bMCP\b|spec ?kit|kiro|tessl|superpowers' MANIFESTO.pt.md MANIFESTO.ja.md
# Expected: no output
```

**Step 5: Commit**

```bash
git add MANIFESTO.md MANIFESTO.pt.md MANIFESTO.ja.md
git commit -m "docs(manifesto): add the scrapup manifesto in EN, PT and JA"
git log -1 --format=%B | grep -iE 'co-authored-by|generated with'
```
Expected: commit created; last command prints nothing.

---

### Task 4: Write `PRINCIPLES.md`

**Files:**
- Create: `PRINCIPLES.md`

**Step 1: Run the traceability check and see it fail**

```bash
grep -c '^\*\*Traces to:\*\*' PRINCIPLES.md
```
Expected: `No such file or directory`.

**Step 2: Write the file with exactly this content**

```markdown
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
```

**Step 3: Run the checks**

```bash
grep -c '^### P' PRINCIPLES.md                  # Expected: 10
grep -c '^\*\*Traces to:\*\*' PRINCIPLES.md     # Expected: 10
grep -c '^\*\*Status:\*\*' PRINCIPLES.md        # Expected: 10
grep -E '^\*\*Traces to:\*\*' PRINCIPLES.md | grep -v -E '\b(B[1-6]|V[12]|PR|RF)\b'
# Expected: no output (every trace is a valid reference)
for p in skills/blueprint skills/verification-before-completion skills/commit-writer; do test -d "$p" && echo "ok $p"; done
# Expected: three "ok" lines (every enforced status names a real skill)
```

**Step 4: Commit**

```bash
git add PRINCIPLES.md
git commit -m "docs(manifesto): add the principles derived from the manifesto"
git log -1 --format=%B | grep -iE 'co-authored-by|generated with'
```
Expected: commit created; last command prints nothing.

---

### Task 5: Link the manifesto from the three READMEs

**Files:**
- Modify: `README.md:5` (insert after the tagline)
- Modify: `README.pt.md:5`
- Modify: `README.ja.md:5`

**Step 1: Verify no link exists yet**

```bash
grep -n 'MANIFESTO' README.md README.pt.md README.ja.md
```
Expected: no output.

**Step 2: Insert one blank line + one link line after line 5 of each file**

- `README.md`:
  `**[Read the manifesto](./MANIFESTO.md)** — what we believe about software, agents, and the people who build it.`
- `README.pt.md`:
  `**[Leia o manifesto](./MANIFESTO.pt.md)** — no que acreditamos sobre software, agentes e as pessoas que o constroem.`
- `README.ja.md`:
  `**[マニフェストを読む](./MANIFESTO.ja.md)** — ソフトウェア、エージェント、そしてそれをつくる人々について、私たちが信じること。`

**Step 3: Verify**

```bash
sed -n 5,7p README.md README.pt.md README.ja.md
```
Expected: in each file, line 5 is the tagline, line 6 blank, line 7 the link line above.

**Step 4: Commit (all three in the same commit)**

```bash
git add README.md README.pt.md README.ja.md
git commit -m "docs(readme): link the manifesto in EN, PT and JA"
git log -1 --format=%B | grep -iE 'co-authored-by|generated with'
```

---

### Task 6: Ship the manifesto in the npm package and the plugin zip

The READMEs now link `MANIFESTO.*.md`; both distribution channels copy the READMEs but not the
manifesto, so the links would break in the packaged copies.

**Files:**
- Modify: `package.json` (`files` array, after `"README.ja.md",`)
- Modify: `scripts/build-plugin-zip.sh:33` (the `for path in …` list)

**Step 1: Verify the gap**

```bash
grep -c 'MANIFESTO' package.json scripts/build-plugin-zip.sh
```
Expected: `package.json:0` and `scripts/build-plugin-zip.sh:0`.

**Step 2: Edit**

- `package.json` `files`: add `"MANIFESTO.md"`, `"MANIFESTO.pt.md"`, `"MANIFESTO.ja.md"`,
  `"PRINCIPLES.md"` right after `"README.ja.md",`.
- `scripts/build-plugin-zip.sh` line 33 becomes:
  ```bash
  for path in skills agents commands hooks README.md README.pt.md README.ja.md MANIFESTO.md MANIFESTO.pt.md MANIFESTO.ja.md PRINCIPLES.md LICENSE; do
  ```

**Step 3: Verify**

```bash
node -e 'const f=require("./package.json").files; console.log(["MANIFESTO.md","MANIFESTO.pt.md","MANIFESTO.ja.md","PRINCIPLES.md"].every(x=>f.includes(x)))'
# Expected: true
npm pack --dry-run 2>&1 | grep -E 'MANIFESTO|PRINCIPLES'
# Expected: four lines (the four files)
out=$(mktemp -d); zip=$(scripts/build-plugin-zip.sh v0.0.0-test "$out"); unzip -l "$zip" | grep -E 'MANIFESTO|PRINCIPLES'; rm -rf "$out"
# Expected: four lines
```

**Step 4: Commit**

```bash
git add package.json scripts/build-plugin-zip.sh
git commit -m "build: ship the manifesto and principles in the npm package and plugin zip"
git log -1 --format=%B | grep -iE 'co-authored-by|generated with'
```

---

### Task 7: Align the repo's contributor docs

**Files:**
- Modify: `CLAUDE.md:23` (Governance & docs list)
- Modify: `CLAUDE.md:37` (UP pillars row)
- Modify: `CLAUDE.md:42` (Validator "decides risk ordering")
- Modify: `CLAUDE.md:65` (localization bullet)
- Modify: `CONTRIBUTING.md:34-37` and `CONTRIBUTING.md:70`
- Modify: `.github/PULL_REQUEST_TEMPLATE.md:24`

**Step 1: Verify the stale statements are present**

```bash
grep -n -E 'Immutable\*\* — the constitution|decides risk ordering|This is the only localization surface' CLAUDE.md
```
Expected: three matches (lines 37, 42, 65).

**Step 2: Edit `CLAUDE.md`**

- Line 23: after `` `README` (trilingual), `` insert
  `` `MANIFESTO` (trilingual) + `PRINCIPLES.md` — the beliefs and the norms derived from them, ``.
- Line 37, third column: replace `**Immutable** — the constitution; inherited, not modernized` with
  `**Inherited as lineage** — vocabulary and milestone spine; degree of fidelity to be declared in an ADR (`PRINCIPLES.md` P10)`.
- Line 42: replace `decides risk ordering` with `approves the risk ordering agents propose`.
- Line 65: replace `This is the only localization surface — it does not loosen` with
  ``The same rule applies to `MANIFESTO.md` / `MANIFESTO.pt.md` / `MANIFESTO.ja.md` (nav line pointing to the `MANIFESTO.*` files). These are the only localization surfaces — they do not loosen``.
- Add a bullet at the top of `## Conventions`:
  ``- **Manifesto:** `MANIFESTO.md` states what scrapup believes; `PRINCIPLES.md` states the norms derived from it. New work MUST NOT contradict them; when it must, amend them first.``

**Step 3: Edit `CONTRIBUTING.md` and the PR template**

- `CONTRIBUTING.md:34`: change `- **README is trilingual.** \`README.md\` (English)` to
  `` - **README and MANIFESTO are trilingual.** `README.md` / `MANIFESTO.md` (English) `` and
  make the rest of the bullet refer to both pairs of `.pt.md` / `.ja.md` files.
- `CONTRIBUTING.md:70`: append ` The same applies to `MANIFESTO.md`.`
- `.github/PULL_REQUEST_TEMPLATE.md:24`: append ` (same for `MANIFESTO.md`)`.

**Step 4: Verify**

```bash
grep -n -E 'Immutable\*\* — the constitution|decides risk ordering|This is the only localization surface' CLAUDE.md
# Expected: no output
grep -c 'MANIFESTO' CLAUDE.md CONTRIBUTING.md .github/PULL_REQUEST_TEMPLATE.md
# Expected: each count ≥ 1
claude plugin validate .
# Expected: validation passes
```

**Step 5: Commit**

```bash
git add CLAUDE.md CONTRIBUTING.md .github/PULL_REQUEST_TEMPLATE.md
git commit -m "docs: align contributor docs with the manifesto"
git log -1 --format=%B | grep -iE 'co-authored-by|generated with'
```

---

### Task 8: Correct the workspace-root documents (no git)

Working directory: `~/Develop/scrapup` (not a git repo — edit only).

**Files:**
- Modify: `CLAUDE.md:22-25` (objective statement), `:39-42` (Differentiation), `:73`
  (Thesis), `:99` (pillars row), `:104-106` (Validator), `:176-179` (Localization)
- Modify: `docs/vision/2026-06-27-product-objective.md:46-49`, `:95-98`, `:123-127`
- Modify: `docs/marketing/2026-06-27-landing-page-brief.md:78-79`
- Modify: `docs/architecture/2026-07-01-sealed-tooling-anti-exfiltration.md:168-169`
- Modify: `docs/vision/2026-10-01-manifesto-brainstorm-context.md` (status line)

**Step 1: Verify the stale statements are present**

```bash
cd ~/Develop/scrapup
grep -n -E 'seal every phase milestone|UP pillars stay immutable|\*\*Immutable\*\* — the constitution|decides risk|Constitution → Specify|stop at spec-as-contract' \
  CLAUDE.md docs/vision/2026-06-27-product-objective.md docs/architecture/2026-07-01-sealed-tooling-anti-exfiltration.md
```
Expected: matches in all three files.

**Step 2: Edit**

Apply the same three substantive corrections everywhere they appear:

1. **Milestone seal:** "seal every phase milestone … nothing advances without sign-off" →
   "seal the phase milestones — LCO → LCA → IOC → Product Release (whether IOC is sealed by a
   human or by evidence alone is still open; see `scrapup/PRINCIPLES.md` P4)". Keep the
   surrounding sentence intact.
2. **Risk ordering:** "risk ordering" as a human control point → "risk ordering (agents propose
   it; humans approve it within the milestone seal)"; Validator "decides risk ordering" →
   "approves the risk ordering agents propose".
3. **UP:** "UP pillars stay immutable" / "**Immutable** — the constitution" → "the UP supplies
   lineage and vocabulary (the milestone spine); the degree of fidelity is to be declared in an
   ADR (`scrapup/PRINCIPLES.md` P10)".

Spec Kit corrections (verified 2026-10-01, v1.0.13):

- `product-objective.md:95-96`: replace `GitHub Spec Kit (specs as executable artifacts;
  Constitution → Specify → Plan → Tasks → Implement)` with `GitHub Spec Kit (three standalone
  workflows — SDD: Constitution → Specify → Plan → Tasks → Implement → Converge; bug fixing; and
  idea assessment ending in an evidence-backed go/clarify/stop decision; no release or
  production-verification phase — verified 2026-10-01, v1.0.13)`.
- `CLAUDE.md:39` and `sealed-tooling…md:168`: `stop at spec-as-contract` → `center on
  spec-as-contract run as standalone workflows`.
- `landing-page-brief.md:78`: `GitHub Spec Kit,` → `GitHub Spec Kit (which also assesses ideas,
  but has no release or production phase),`.

Anchors:

- `CLAUDE.md`, right under `## Product objective`: add
  `> Beliefs behind this objective: `scrapup/MANIFESTO.md`; derived norms: `scrapup/PRINCIPLES.md`.`
- `CLAUDE.md:176-179` (Localization): add "and the manifesto (`MANIFESTO.md` / `.pt.md` / `.ja.md`)"
  after "the repo `README`" clause.
- `product-objective.md` *Alignment hook*: append
  `The beliefs behind this objective live in `scrapup/MANIFESTO.md`; revise the objective when the manifesto changes.`
- `2026-10-01-manifesto-brainstorm-context.md`, top blockquote: change `Status: **in progress**`
  sentence to `Status: **design approved** — see `scrapup/docs/plans/2026-10-01-manifesto-design.md`.`

**Step 3: Verify**

```bash
cd ~/Develop/scrapup
grep -n -E 'seal every phase milestone|UP pillars stay immutable|\*\*Immutable\*\* — the constitution|decides risk|Constitution → Specify → Plan → Tasks → Implement\)|stop at spec-as-contract' \
  CLAUDE.md docs/vision/2026-06-27-product-objective.md docs/marketing/2026-06-27-landing-page-brief.md docs/architecture/2026-07-01-sealed-tooling-anti-exfiltration.md
# Expected: no output
grep -c 'MANIFESTO' CLAUDE.md docs/vision/2026-06-27-product-objective.md
# Expected: each ≥ 1
```

No commit (not a git repository).

---

### Task 9: Review lenses and the founder's seal

**Step 1: Dispatch three reviewers in parallel** (`subagent_type`):

| Agent | Target | Ask |
|---|---|---|
| `scrapforge:reviewer-prompt-engineering` | `PRINCIPLES.md` | Clarity and unambiguity of each MUST/SHOULD for an agent reader |
| `scrapforge:reviewer-ethics` | `MANIFESTO*.md`, `PRINCIPLES.md` | Exposure of people, misleading promises, licensing |
| `scrapforge:reviewer-homogeneity` | All changed repo files | Localization rule, nav lines, naming, README structure |

**Step 2: Re-run every check** from Tasks 1, 3, 4, 6, and 7 and keep the output as evidence.

**Step 3: CHECKPOINT — founder's seal.** Present the reviewers' findings and the evidence. The
founder reads the core in the three languages and approves. Apply any requested change in all
three languages in one commit (`docs(manifesto): …`). Nothing reaches `main` without this seal.

**Step 4:** Use /scrapforge:finishing-a-development-branch to decide PR/merge.

---

## Follow-ups (out of scope)

- Landing page (`scrapup.dev`, `/pt/`, `/ja/`): add the manifesto core — separate repository.
- ADR for UP lineage and fidelity (P10).
- Decide IOC seal mechanics (P4) and update P4, the objective, and both `CLAUDE.md` files.
- Link skills/agents to principle IDs.
