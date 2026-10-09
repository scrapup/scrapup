---
name: dispatching-parallel-agents
description: Dispatches one subagent per independent problem domain in a single turn and integrates their results. Use when facing 2+ independent tasks without shared state, e.g. "investigate these failures in parallel", "run these in parallel". Do NOT use for executing a written plan task-by-task (use /scrapup:subagent-driven-development) or for requesting a review (use /scrapup:requesting-code-review).
---

# Dispatching Parallel Agents

## Overview

When you have multiple independent tasks or problem domains (failing tests, review targets, subsystem investigations, separate bugs), working them sequentially wastes time. Each can be handled without context from the others, so dispatch one agent per domain and let them run concurrently.

**Core principle:** Dispatch one agent per independent task/problem domain. Run them concurrently.

**What produces real concurrency:** Emit all agent calls (Task/Agent) in the SAME turn/message, without waiting for any to return before issuing the next. Agent calls made across separate turns — issuing one, reading its result, then issuing the next — run in series, not in parallel, regardless of intent.

**Fallbacks:** If no subagent tool is available, run the domains sequentially. To isolate agents that need the same files, give each its own worktree (/scrapup:using-git-worktrees).

## When to Use

```dot
digraph when_to_use {
    "Multiple failures?" [shape=diamond];
    "Are they independent?" [shape=diamond];
    "Single agent investigates all" [shape=box];
    "One agent per problem domain" [shape=box];
    "Can they work in parallel?" [shape=diamond];
    "Sequential agents" [shape=box];
    "Parallel dispatch" [shape=box];

    "Multiple failures?" -> "Are they independent?" [label="yes"];
    "Are they independent?" -> "Single agent investigates all" [label="no - related"];
    "Are they independent?" -> "Can they work in parallel?" [label="yes"];
    "Can they work in parallel?" -> "Parallel dispatch" [label="yes"];
    "Can they work in parallel?" -> "Sequential agents" [label="no - shared state"];
}
```

**Use when:**
- 2+ independent tasks or problem domains: failing tests, review targets, subsystem investigations, separate bugs
- Each domain can be understood without context from the others
- No shared state between the agents (no overlapping files or resources)

**Don't use when:**
- **Related domains:** handling one might resolve or alter others - investigate together first
- **Need full context:** understanding requires seeing the entire system state first
- **Exploratory debugging:** you don't know what's broken yet
- **Shared state:** agents would interfere (same files, same resources)
- **Written plan to execute task-by-task:** use /scrapup:subagent-driven-development

## The Pattern

### 1. Identify Independent Domains

Group the work by what is independent. Examples:
- Failing tests grouped by root cause (tool approval flow, batch completion, abort functionality)
- Review targets (auth module, payment module, API contract)
- Subsystem investigations (queue consumer, cache layer, DB migrations)

Each domain must be independent — handling one does not affect another, and they touch no shared files.

### 2. Create Focused Agent Tasks

Each agent gets:
- **Specific scope:** One domain (test file, review target, or subsystem)
- **Clear goal:** The concrete outcome expected
- **Constraints:** Files/resources it must not touch (preserve isolation); no commits/pushes or destructive commands unless the task states it
- **Expected output:** A return summary with the minimum fields below

### 3. Dispatch in Parallel

```text
Pseudo-code: three Agent (Task) tool calls emitted in the SAME turn/message, no wait between them.
Agent("Investigate auth subsystem failure")
Agent("Review payment module diff")
Agent("Fix tool-approval-race-conditions.test.ts failures")
Concurrent only because they were dispatched together in one turn.
Issuing them across separate turns would serialize them.
```

### 4. Review and Integrate

Require each agent's return summary to carry these minimum fields, so the integration step can check for conflicts:
- **Root cause / Findings** — what the agent found, supported by `file:line` references or test output; state 'not determined' when unverified
- **Files changed** — exact paths touched
- **Change** — what was modified
- **Residual risks** — anything left unverified or potentially affecting other domains

When agents return:
1. **Review each summary** - confirm Root cause / Findings, Files changed, Change, and Residual risks are present
2. **Check for conflicts** - cross-check the "Files changed" sets for overlap (same path edited by two agents = conflict; apply the degraded path)
3. **Run the full test suite** when any agent changed files; otherwise skip
4. **Spot check** - agents can make systematic errors
5. **Integrate** all changes

**Degraded path:**
- **Edit conflict** (two agents touched the same file) — ask the user before discarding edits; then discard the conflicting edits and re-run the affected domains in sequence so the second sees the first's result.
- **Agent does not return** (no summary, timeout, error) — re-dispatch that single domain; if it fails again, drop it from the parallel batch and handle it sequentially or escalate to the user.

## Agent Prompt Structure

Good agent prompts are:
1. **Focused** - One clear problem domain
2. **Self-contained** - All context needed to understand the problem
3. **Specific about output** - What should the agent return?

```markdown
Fix the 3 failing tests in src/agents/agent-tool-abort.test.ts:

1. "should abort tool with partial output capture" - expects 'interrupted at' in message
2. "should handle mixed completed and aborted tools" - fast tool aborted instead of completed
3. "should properly track pendingToolCount" - expects 3 results but gets 0

These are timing/race condition issues. Your task:

1. Read the test file and understand what each test verifies
2. Identify root cause - timing issues or actual bugs?
3. Fix by:
   - Replacing arbitrary timeouts with event-based waiting
   - Fixing bugs in abort implementation if found
   - Adjusting test expectations if testing changed behavior

Do NOT just increase timeouts - find the real issue.

Constraints: touch only src/agents/agent-tool-abort.test.ts and the abort implementation.

Return: Root cause; Files changed (exact paths); Change; Residual risks.
```

## Common Mistakes

**BAD - Too broad:** "Fix all the tests" - agent gets lost
**GOOD - Specific:** "Fix agent-tool-abort.test.ts" - focused scope

**BAD - No context:** "Fix the race condition" - agent doesn't know where
**GOOD - Context:** Paste the error messages and test names

**BAD - No constraints:** Agent might refactor everything
**GOOD - Constraints:** "Do NOT change production code" or "Fix tests only"

**BAD - Vague output:** "Fix it" - you don't know what changed
**GOOD - Specific:** "Return: Root cause; Files changed (exact paths); Change; Residual risks"

## Real Example (illustration — test debugging)

One concrete domain among many; the pattern applies equally to review targets and subsystem investigations.

**Scenario:** 6 test failures across 3 files after major refactoring

**Failures:**
- agent-tool-abort.test.ts: 3 failures (timing issues)
- batch-completion-behavior.test.ts: 2 failures (tools not executing)
- tool-approval-race-conditions.test.ts: 1 failure (execution count = 0)

**Decision:** Independent domains - abort logic separate from batch completion separate from race conditions

**Dispatch:**
```
Agent 1 → Fix agent-tool-abort.test.ts
Agent 2 → Fix batch-completion-behavior.test.ts
Agent 3 → Fix tool-approval-race-conditions.test.ts
```

**Results:**
- Agent 1: Replaced timeouts with event-based waiting
- Agent 2: Fixed event structure bug (threadId in wrong place)
- Agent 3: Added wait for async tool execution to complete

**Integration:** All fixes independent, no conflicts, full suite green
