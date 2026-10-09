---
name: executing-plans
description: Executes a written implementation plan (from /scrapup:writing-plans) in a separate session, in batches with human review checkpoints between batches. Use when the user says "execute the plan", "run this plan", "implement docs/plans/<file>.md". Do NOT use for same-session subagent execution (use /scrapup:subagent-driven-development), SDD TF/US tasks (use /scrapup:forge), or writing the plan (use /scrapup:writing-plans).
---

# Executing Plans

**Core principle:** Batch execution with checkpoints for review by the user (Architect-Validator).

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## Trigger Tests

**Should trigger:**
- "Execute the plan in docs/plans/2026-09-30-auth.md" (new session, batch checkpoints).
- "Run this plan, stop after each batch for my review."

**Should NOT trigger:**
- "Execute the plan here, one subagent per task" → /scrapup:subagent-driven-development.
- "Implement TF-03 from tasks.md" / "execute US-2" → /scrapup:forge.
- "Write a plan for this feature" → /scrapup:writing-plans.

## The Process

### Step 1: Set Up Workspace, Load and Review Plan
1. **Isolate the workspace first.** If you are not already in an isolated worktree, use /scrapup:using-git-worktrees to create one before doing anything else. Never start implementation on `main`/`master` (or the default branch) without explicit consent from the user (Architect-Validator).
2. Read plan file. **Observable check:** the plan file exists and contains sliced tasks, each with bite-sized steps and explicit verifications. If it does not (empty plan, no tasks, or tasks without steps/verifications), treat it as a critical gap (see Step 1.4).
3. Review critically - identify any questions or concerns about the plan. A **blocking concern** is anything that prevents you from executing a task as written: missing/contradictory steps, an unverifiable outcome, an unresolved dependency, or ambiguity that forces you to guess. Non-blocking observations can be noted and carried into the report.
4. If blocking concerns or the plan fails the observable check: raise them with the user (Architect-Validator) before starting.
5. If no blocking concerns: create a TodoWrite list with one item per plan task, then proceed.

### Step 2: Execute Batch
**Default: first 3 tasks.** If fewer than 3 tasks remain, the batch is all remaining tasks. The user (Architect-Validator) may override the batch size. A single large or risky task may form its own batch.

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps). If a step is destructive or irreversible (force-push, data deletion, prod/remote changes, history rewrite), confirm with the user (Architect-Validator) before running it, even if the plan says so.
3. Run verifications as specified
4. Mark as completed

### Step 3: Report
When batch complete, report at minimum:
- **Completed tasks** in the batch, by id/title
- **Verification status** per task: the command run and its pass/fail result
- **What changed**: files touched and a one-line summary of each change
- **Next batch**: a preview of the tasks queued next
- Then say: "Ready for feedback."

### Step 4: Continue
Based on feedback from the user (Architect-Validator):
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:
- **REQUIRED SUB-SKILL:** /scrapup:finishing-a-development-branch

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch: missing dependency, a verification fails persistently (see below), or an unclear instruction
- Plan has critical gaps preventing starting
- You don't understand an instruction
- The same verification fails after 3 correction attempts (persistent failure). Distinguish this from a transient failure (flaky test, environment hiccup) - retry transient failures, but STOP and escalate on persistent ones

A test that fails intentionally in a TDD step (e.g., "Run it to make sure it fails") is the expected outcome, not a blocker.

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- The user (Architect-Validator) updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait

## Integration

**Required workflow skills:**
- **/scrapup:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **/scrapup:writing-plans** - Creates the plan this skill executes
- **/scrapup:finishing-a-development-branch** - Complete development after all tasks
