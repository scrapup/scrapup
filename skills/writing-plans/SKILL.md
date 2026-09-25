---
name: writing-plans
description: Use when you have a spec or requirements for a multi-step task, before touching code
---

# Writing Plans

## Overview

**Your task (the model writing this plan):** Produce a comprehensive implementation plan. Document everything the implementer needs: which files to touch for each task, complete code, testing, docs they might need to check, how to test it. Lay out the whole plan as bite-sized tasks. Enforce DRY, YAGNI, TDD, frequent commits.

**The plan's reader (your premise):** Write for an implementer who has zero context for this codebase and questionable taste. Assume they are a skilled developer, but know almost nothing about our toolset or problem domain, and don't know good test design very well. Everything they need must be on the page — they will not infer it.

**Announce at start:** "I'm using the writing-plans skill to create the implementation plan."

**Context:** This should be run in a dedicated worktree (created by the /scrapup:brainstorming skill).

**Save plans to:** `docs/plans/YYYY-MM-DD-<feature-name>.md`

**Boundary with SDD blueprint:** This skill produces a generic implementation plan under `docs/plans/`. It is NOT the Spec-Driven Development flow — formal SDD artifacts (spec, plan, tasks) live under `docs/specs/` and are owned by /scrapup:blueprint. If the work calls for SDD artifacts, defer to /scrapup:blueprint instead of writing a plan here.

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

## Plan Document Header

**Every plan MUST start with this header:**

```markdown
# [Feature Name] Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use /scrapup:executing-plans to implement this plan task-by-task.

**Goal:** [One sentence describing what this builds]

**Architecture:** [2-3 sentences about approach]

**Tech Stack:** [Key technologies/libraries]

```

## Task Structure

````markdown
### Task N: [Component Name]

**Files:**
- Create: `exact/path/to/file.py`
- Modify: `exact/path/to/existing.py:123-145`
- Test: `tests/exact/path/to/test.py`

**Step 1: Write the failing test**

```python
def test_specific_behavior():
    result = function(input)
    assert result == expected
```

**Step 2: Run test to verify it fails**

Run: `pytest tests/path/test.py::test_name -v`
Expected: FAIL with "function not defined"

**Step 3: Write minimal implementation**

```python
def function(input):
    return expected
```

**Step 4: Run test to verify it passes**

Run: `pytest tests/path/test.py::test_name -v`
Expected: PASS

**Step 5: Commit**

```bash
git add tests/path/test.py src/path/file.py
git commit -m "feat: add specific feature"
```
````

## Remember
- Exact file paths always — verify every path and line range against the real codebase (Read/LSP) before it enters the plan; never write a path or `file.py:123-145` range you have not confirmed exists
- Complete code in plan (not "add validation")
- Exact commands with expected output
- Reference relevant skills by their namespaced form `/scrapup:{skill}` (e.g. "Use /scrapup:executing-plans")
- DRY, YAGNI, TDD, frequent commits

## Self-Check Before Handoff

Before offering the execution choice, verify the plan against this checklist:

- [ ] Every file path and line range was confirmed against the real codebase (Read/LSP).
- [ ] Every command is exact and paired with expected output.
- [ ] Each task is bite-sized (one action, 2-5 minutes) and follows test-first ordering.
- [ ] No invented paths, commands, or architecture — every detail is grounded.
- [ ] The plan header is present and references /scrapup:executing-plans.

If any item fails, fix it before handoff.

## Execution Handoff

After saving the plan, offer execution choice:

**"Plan complete and saved to `docs/plans/<filename>.md`. Two execution options:**

**1. Subagent-Driven (this session)** - I dispatch fresh subagent per task, review between tasks, fast iteration

**2. Parallel Session (separate)** - Open new session with /scrapup:executing-plans, batch execution with checkpoints

**Which approach?"**

**If Subagent-Driven chosen:**
- **REQUIRED SUB-SKILL:** Use /scrapup:subagent-driven-development
- Stay in this session
- Fresh subagent per task + code review

**If Parallel Session chosen:**
- Guide them to open new session in worktree
- **REQUIRED SUB-SKILL:** New session uses /scrapup:executing-plans
