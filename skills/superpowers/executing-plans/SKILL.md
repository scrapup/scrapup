---
name: executing-plans
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
metadata:
  obsidian_identifier: scrapup:executing-plans
---

# Executing Plans

## Overview

Load plan, review critically, execute tasks in batches, report for review between batches.

**Core principle:** Batch execution with checkpoints for architect review.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

## The Process

### Step 1: Set Up Workspace, Load and Review Plan
1. **Isolate the workspace first.** If you are not already in an isolated worktree, use scrapup:using-git-worktrees to create one before doing anything else. Never start implementation on `main`/`master` (or the default branch) without explicit user consent.
2. Read plan file. **Observable check:** the plan file exists and contains sliced tasks, each with bite-sized steps and explicit verifications. If it does not (empty plan, no tasks, or tasks without steps/verifications), treat it as a critical gap (see Step 1.4).
3. Review critically - identify any questions or concerns about the plan. A **blocking concern** is anything that prevents you from executing a task as written: missing/contradictory steps, an unverifiable outcome, an unresolved dependency, or ambiguity that forces you to guess. Non-blocking observations can be noted and carried into the report.
4. If blocking concerns or the plan fails the observable check: Raise them with your human partner before starting.
5. If no blocking concerns: Create TodoWrite and proceed.

For executing independent tasks within the **current** session instead of a separate one with batch checkpoints, use scrapup:subagent-driven-development instead of this skill.

### Step 2: Execute Batch
**Default: first 3 tasks.** If fewer than 3 tasks remain, the batch is all remaining tasks. The partner may override the batch size. A single large or risky task may form its own batch.

For each task:
1. Mark as in_progress
2. Follow each step exactly (plan has bite-sized steps)
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
Based on feedback:
- Apply changes if needed
- Execute next batch
- Repeat until complete

### Step 5: Complete Development

After all tasks complete and verified:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use scrapup:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker mid-batch (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- The same verification fails after 3 correction attempts (persistent failure). Distinguish this from a transient failure (flaky test, environment hiccup) - retry transient failures, but STOP and escalate on persistent ones

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Between batches: just report and wait
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **scrapup:using-git-worktrees** - REQUIRED: Set up isolated workspace before starting
- **scrapup:writing-plans** - Creates the plan this skill executes
- **scrapup:finishing-a-development-branch** - Complete development after all tasks
