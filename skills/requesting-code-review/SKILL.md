---
name: requesting-code-review
description: Dispatches a reviewer subagent over a git SHA range using the code-reviewer.md template and acts on its findings. Use when a task or feature is complete or before merging; triggers on "request code review", "review my changes". Do NOT use for responding to review feedback (use /scrapup:receiving-code-review).
---

# Requesting Code Review

Dispatch a code-reviewer subagent (general-purpose Agent with the template [`code-reviewer.md`](code-reviewer.md)) to catch issues before they cascade.

**Boundaries (when to use something else):**
- For a multi-perspective review, dispatch several reviewers in parallel via /scrapup:dispatching-parallel-agents.
- Receiving and acting on review feedback addressed to you: use /scrapup:receiving-code-review (the counterpart to this skill).

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- After each task in /scrapup:subagent-driven-development
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**Range guards (resolve before dispatch):**
- **Initial commit / no `HEAD~1`:** `git rev-parse HEAD~1` fails. Use the empty-tree object as base: `BASE_SHA=$(git hash-object -t tree /dev/null)` (yields `4b825dc...`), which diffs the whole first commit.
- **Empty range:** if `git diff --stat $BASE_SHA..$HEAD_SHA` is empty, do **not** dispatch and do **not** invent issues — report `Ready to merge: No changes` (range `$BASE_SHA..$HEAD_SHA`) and stop.
- **Range too large for one review:** if the diff exceeds the reviewer's analyzable window, the reviewer declares the limitation in its Assessment and reviews the highest-risk files first (see [`code-reviewer.md`](code-reviewer.md)); do not silently truncate without disclosure.

**2. Dispatch code-reviewer subagent:**

Use the Agent tool (general-purpose subagent), filling the template at [`code-reviewer.md`](code-reviewer.md)

**Placeholders** (names must match the template [`code-reviewer.md`](code-reviewer.md) exactly):
- `{WHAT_WAS_IMPLEMENTED}` - One-line title of what you just built
- `{PLAN_REFERENCE}` - What it should do (plan/requirements reference)
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit
- `{DESCRIPTION}` - Details of the change (scope, key decisions, files touched)

**3. Act on feedback:**
- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back only with **reproducible evidence** (see termination criterion below) — never with opinion alone

**Push-back criterion and termination (bounds autonomous loops):**
- Push back **only** when you hold reproducible evidence the issue is wrong: a passing test, or a code snippet at `file:line` that demonstrates the behavior. Without such evidence, treat the issue as valid and fix it.
- **One round max.** If the disagreement persists after a single re-review round, do **not** iterate further: record both positions (reviewer's claim and your evidence) and escalate to the user (Architect-Validator) for the decision.

## Example

```
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git rev-parse HEAD~1)  # commit before Task 2
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code-reviewer subagent: general-purpose Agent + code-reviewer.md template]
  WHAT_WAS_IMPLEMENTED: Verification and repair functions for conversation index
  PLAN_REFERENCE: Task 2 from docs/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important (Should Fix): Missing progress indicators (indexer.ts:130)
    Minor (Nice to Have): Magic number (100) for reporting interval (indexer.ts:118)
  Assessment: Ready to merge: With fixes

You: [Fix progress indicators]
[Continue to Task 3]
```

## Integration with Workflows

**/scrapup:subagent-driven-development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task

**/scrapup:executing-plans:**
- Review after each batch (3 tasks)
- Get feedback, apply, continue

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback

**If reviewer wrong:**
- Push back only with reproducible evidence: a passing test or a `file:line` snippet that proves the behavior
- One round max — if the disagreement persists, record both positions and escalate to the user (Architect-Validator) (see "How to Request" step 3)
