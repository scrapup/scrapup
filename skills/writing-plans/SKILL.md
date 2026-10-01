---
name: writing-plans
description: Writes a bite-sized, test-first implementation plan to docs/plans/ from an approved design or requirements, before any code is touched. Use when the user says "write the implementation plan", "plan this out", or after /scrapup:brainstorming selects direct work. Do NOT use for SDD spec/plan/tasks (use /scrapup:blueprint), idea exploration (use /scrapup:brainstorming), or executing a plan (use /scrapup:executing-plans or /scrapup:subagent-driven-development).
---

# Writing Plans

## Overview

**Your task (the model writing this plan):** Produce a comprehensive implementation plan. Document everything the implementer needs: which files to touch for each task, complete code, testing, docs they might need to check, how to test it. Lay out the whole plan as bite-sized tasks. Enforce DRY, YAGNI, test-first (/scrapup:test-driven-agentic-development), frequent commits.

**The plan's reader (your premise):** Assume zero codebase context and weak test-design instinct. Assume a skilled developer who knows almost nothing about our toolset or problem domain. Everything they need must be on the page — they will not infer it.

**Context:** Run in a dedicated worktree; if none exists, create one via /scrapup:using-git-worktrees.

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`. If the file already exists, append `-v2` (then `-v3`, ...); never overwrite.

**Boundary with SDD blueprint:** This skill produces a generic implementation plan under `docs/plans/`. It is NOT the Spec-Driven Development flow — formal SDD artifacts (spec, plan, tasks) live under `docs/specs/` and are owned by /scrapup:blueprint. If the work is ≥5 tasks / high impact, or a versioned spec contract is required → /scrapup:blueprint instead of writing a plan here.

## Trigger Tests

**Should trigger:**
- "Write the implementation plan for the design we just approved."
- /scrapup:brainstorming concluded with direct work (no SDD) and a design doc exists.

**Should NOT trigger:**
- "Specify this feature" / "create spec, plan and tasks" / "write single-tasks.md" → /scrapup:blueprint.
- "Let's explore options for this idea" → /scrapup:brainstorming.
- "Execute docs/plans/<file>.md" → /scrapup:executing-plans or /scrapup:subagent-driven-development.

## Before Starting

Read the design doc / spec (e.g. `docs/plans/YYYY-MM-DD-<topic>-design.md` from /scrapup:brainstorming); record its path in the plan header as `**Source:**`.

## When Requirements Are Insufficient

Do not write a plan on top of guesses. Stop and return to /scrapup:brainstorming when:

- The spec is ambiguous or a key decision is missing — architecture, stack, data model, or layout.
- A file path, command, or contract cannot be grounded in the actual codebase.

Never invent file paths, commands, or architecture to fill a gap. A plan built on invented details is worse than no plan. Resolve the gap first, then write.

## Bite-Sized Task Granularity

**Each step is one action (2-5 minutes):**
- "Write the failing test" - step
- "Run it to make sure it fails" - step
- "Implement the minimal code to make the test pass" - step
- "Run the tests and make sure they pass" - step
- "Commit" - step

**BAD** (vague step — the implementer must guess):

```markdown
**Step 3:** Add validation to the email field.
```

**GOOD** (complete code, exact path, nothing to infer):

````markdown
**Step 3: Write minimal implementation** in `src/users/validate-email.ts`

```ts
export function validateEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
```
````

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** Execute with /scrapup:subagent-driven-development (same session) or /scrapup:executing-plans (separate session).

**Source:** [path to the design doc / spec this plan derives from]

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `src/exact/path/to/file.ts`
- Modify: `src/exact/path/to/existing.ts:123-145`
- Test: `test/exact/path/to/file.spec.ts`

**Step 1: Write the failing test**

```ts
import { specificFunction } from '../../src/exact/path/to/file';

describe('specificFunction', () => {
  it('returns expected for input', () => {
    expect(specificFunction(input)).toEqual(expected);
  });
});
```

**Step 2: Run test to verify it fails**

Run: `npx jest test/exact/path/to/file.spec.ts -t "returns expected for input"`
Expected: FAIL with "specificFunction is not a function"

**Step 3: Write minimal implementation**

```ts
export function specificFunction(input: Input): Output {
  return expected;
}
```

**Step 4: Run test to verify it passes**

Run: `npx jest test/exact/path/to/file.spec.ts -t "returns expected for input"`
Expected: PASS

**Step 5: Commit**

```bash
git add test/exact/path/to/file.spec.ts src/exact/path/to/file.ts
git commit -m "feat: add specific feature"
```
````

## Self-Check Before Handoff

Before offering the execution choice, verify the plan against this checklist:

- [ ] Every file path and line range was confirmed against the real codebase (Read/LSP).
- [ ] Every command is exact and paired with expected output.
- [ ] Each task is bite-sized (one action, 2-5 minutes) and follows test-first ordering.
- [ ] Every step contains complete code (no "add validation"-style steps).
- [ ] No invented paths, commands, or architecture — every detail is grounded.
- [ ] Skills are referenced in their namespaced form `/scrapup:<skill>`.
- [ ] The plan header is present, includes `**Source:**`, and references both execution skills.

If any item fails, fix it before handoff.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with /scrapup:executing-plans, batch execution with checkpoints

**Which approach?"**

If no user is available (e.g., invoked as a subagent), return the plan path and stop.

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use /scrapup:subagent-driven-development
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses /scrapup:executing-plans
