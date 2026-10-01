---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always. Triggers on "done", "fixed", "tests pass", "ready to merge". Do NOT use for diagnosing failures (use /scrapup:systematic-debugging) or requesting review (use /scrapup:requesting-code-review).
---

# Verification Before Completion

## Purpose

Never claim work is complete without fresh verification evidence — that is an unverified claim, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in the current turn, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
   - Derive the REAL command from the project's source of truth
     (package.json scripts, Makefile, CI config) — do not assume a
     generic default. If no command resolves, go to "Unverifiable Claims".
   - Do not run package.json scripts that deploy, publish or migrate
     without user confirmation.
2. RUN: Execute the FULL command (fresh, complete)
   - If the tool exists but cannot run (missing, no network/credentials),
     go to "Unverifiable Claims" — do NOT assume success.
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = unverified claim, not verification
```

## Gate Output

When this skill runs as a completion gate, emit the decision in this fixed shape so the caller consumes the verdict instead of parsing prose. The consumer is `/scrapup:forge`, which reads the `GATE:` line: `PASS` → proceed; `FAIL` → correction loop; `ESCALATE` → ask the user. In standalone mode (no orchestrator), emit the same table and `GATE:` line.

| verification | command | exit code | evidence (output excerpt) | result |
|--------------|---------|-----------|---------------------------|--------|
| {what was checked} | {exact command run} | {0, non-zero, or N/A} | {relevant output lines, e.g. "34 passed, 0 failed"} | PASS \| FAIL \| UNVERIFIABLE |

End with a single final verdict line:

```
GATE: PASS | FAIL | ESCALATE
```

- `GATE: PASS` only when every row is PASS.
- Any FAIL row → `GATE: FAIL`.
- At least one UNVERIFIABLE row and no FAIL row → `GATE: ESCALATE`. The orchestrator asks the user; only the user may accept the abstention. Never silently treat UNVERIFIABLE as PASS.

## Unverifiable Claims

A claim is unverifiable when no objective command can confirm it, or when the verifying tool cannot run. Do not assert success — abstain and report.

| Situation | Required behavior |
|-----------|-------------------|
| No objective verification command exists (docs-only change, design decision) | State explicitly "not verifiable by command" and give the reason. Do not claim success. Yields `GATE: ESCALATE` (not FAIL), unless a verification command exists (e.g., a docs linter or link checker). |
| Verification tool exists but cannot run (missing binary, no network, no credentials) | Report as a BLOCKER with the cause. Do not assume the check would pass. |

In the Gate Output, mark such rows `UNVERIFIABLE` with exit code `N/A` and the reason in the `evidence` cell. Escalate to the user (directly, or via the orchestrator) rather than proceeding on assumption.

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff matches the task scope | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Wanting to close the task quickly before evidence exists
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "Long session, close it out" | Session length ≠ evidence |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
BAD:  "Should pass now" / "Looks correct"
GOOD: [Run test command] [See: 34/34 pass] "All tests pass"
```

**Regression tests (TDD Red-Green):**
```
BAD:  "I've written a regression test" (without red-green verification)
GOOD: Write → Run (pass) → Revert fix via `git stash` → Run (MUST FAIL) → `git stash pop` → Run (pass)
```

Never revert with `git checkout --` or `git reset --hard` — they discard work irrecoverably.

**Build:**
```
BAD:  "Linter passed" (linter doesn't check compilation)
GOOD: [Run build] [See: exit 0] "Build passes"
```

**Requirements:**
```
BAD:  "Tests pass, phase complete"
GOOD: Re-read plan → Create checklist → Verify each → Report gaps or completion
```

**Agent delegation:**
```
BAD:  Trust agent report
GOOD: Agent reports success → Check VCS diff matches task scope → Verify changes → Report actual state
```

## Why This Matters

Skipping verification has repeatedly caused:
- Trust broken — the Validator rejects the claim and the milestone cannot be sealed
- Undefined functions shipped that would crash
- Missing requirements shipped as incomplete features
- Time wasted on false completion → redirect → rework
- Violates the project principle *Delivery with evidence*

## When To Apply

**ALWAYS before:**
- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
- Moving to next task
- Delegating to agents

**Rule applies to:**
- Exact phrases
- Paraphrases and synonyms
- Implications of success
- ANY communication suggesting completion/correctness

## Trigger Tests

| Prompt / situation | Should trigger? |
|--------------------|-----------------|
| About to reply "done, tests pass" after editing code | Yes |
| User asks "is it fixed? ready to merge?" | Yes |
| `/scrapup:forge` finishing a task and needing the `GATE:` verdict | Yes |
| "Tests are failing, find out why" | No — use `/scrapup:systematic-debugging` |
| "Request a review of this branch" | No — use `/scrapup:requesting-code-review` |
| "Explain how this module works" | No — no completion claim involved |

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
