---
name: verification-before-completion
description: Use when about to claim work is complete, fixed, or passing, before committing or creating PRs - requires running verification commands and confirming output before making any success claims; evidence before assertions always
metadata:
  obsidian_identifier: scrapup:verification-before-completion
---

# Verification Before Completion

## Purpose

Never claim work is complete without fresh verification evidence — that is dishonesty, not efficiency.

**Core principle:** Evidence before claims, always.

**Violating the letter of this rule is violating the spirit of this rule.**

## The Iron Law

```
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE
```

If you haven't run the verification command in this message, you cannot claim it passes.

## The Gate Function

```
BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim?
   - Derive the REAL command from the project's source of truth
     (package.json scripts, Makefile, CI config) — do not assume a
     generic default. If no command resolves, go to "Unverifiable Claims".
2. RUN: Execute the FULL command (fresh, complete)
   - If the tool exists but cannot run (missing, no network/credentials),
     go to "Unverifiable Claims" — do NOT assume success.
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

Skip any step = lying, not verifying
```

## Gate Output

When this skill runs as a completion gate consumed by an orchestrator
(`/scrapup:scrapup-forge`, `/scrapup:test-driven-agentic-development`),
emit the decision in this fixed shape so the caller consumes the verdict
instead of parsing prose:

| verification | command | exit code | result |
|--------------|---------|-----------|--------|
| {what was checked} | {exact command run} | {0, non-zero, or N/A} | PASS \| FAIL \| UNVERIFIABLE |

End with a single final verdict line:

```
GATE: PASS | FAIL
```

- `GATE: PASS` only when every row is PASS.
- Any FAIL row → `GATE: FAIL`.
- Any UNVERIFIABLE row → `GATE: FAIL` unless the orchestrator has accepted
  the abstention (see "Unverifiable Claims"); never silently treat
  UNVERIFIABLE as PASS.

## Unverifiable Claims

A claim is unverifiable when no objective command can confirm it, or when
the verifying tool cannot run. Do not assert success — abstain and report.

| Situation | Required behavior |
|-----------|-------------------|
| No objective verification command exists (doc-only change, design decision) | State explicitly "not verifiable by command" and give the reason. Do not claim success. |
| Verification tool exists but cannot run (missing binary, no network, no credentials) | Report as a BLOCKER with the cause. Do not assume the check would pass. |

In the Gate Output, mark such rows `UNVERIFIABLE` with exit code `N/A` and
the reason in the `verification` cell. Escalate the blocker to the
orchestrator or user rather than proceeding on assumption.

## Common Failures

| Claim | Requires | Not Sufficient |
|-------|----------|----------------|
| Tests pass | Test command output: 0 failures | Previous run, "should pass" |
| Linter clean | Linter output: 0 errors | Partial check, extrapolation |
| Build succeeds | Build command: exit 0 | Linter passing, logs look good |
| Bug fixed | Test original symptom: passes | Code changed, assumed fixed |
| Regression test works | Red-green cycle verified | Test passes once |
| Agent completed | VCS diff shows changes | Agent reports "success" |
| Requirements met | Line-by-line checklist | Tests passing |

## Red Flags - STOP

- Using "should", "probably", "seems to"
- Expressing satisfaction before verification ("Great!", "Perfect!", "Done!", etc.)
- About to commit/push/PR without verification
- Trusting agent success reports
- Relying on partial verification
- Thinking "just this once"
- Tired and wanting work over
- **ANY wording implying success without having run verification**

## Rationalization Prevention

| Excuse | Reality |
|--------|---------|
| "Should work now" | RUN the verification |
| "I'm confident" | Confidence ≠ evidence |
| "Just this once" | No exceptions |
| "Linter passed" | Linter ≠ compiler |
| "Agent said success" | Verify independently |
| "I'm tired" | Exhaustion ≠ excuse |
| "Partial check is enough" | Partial proves nothing |
| "Different words so rule doesn't apply" | Spirit over letter |

## Key Patterns

**Tests:**
```
✅ [Run test command] [See: 34/34 pass] "All tests pass"
❌ "Should pass now" / "Looks correct"
```

**Regression tests (TDD Red-Green):**
```
✅ Write → Run (pass) → Revert fix → Run (MUST FAIL) → Restore → Run (pass)
❌ "I've written a regression test" (without red-green verification)
```

**Build:**
```
✅ [Run build] [See: exit 0] "Build passes"
❌ "Linter passed" (linter doesn't check compilation)
```

**Requirements:**
```
✅ Re-read plan → Create checklist → Verify each → Report gaps or completion
❌ "Tests pass, phase complete"
```

**Agent delegation:**
```
✅ Agent reports success → Check VCS diff → Verify changes → Report actual state
❌ Trust agent report
```

## Why This Matters

Skipping verification has repeatedly caused:
- Trust broken — the human partner said "I don't believe you"
- Undefined functions shipped that would crash
- Missing requirements shipped as incomplete features
- Time wasted on false completion → redirect → rework
- Violation of the core value: "Honesty is a core value. If you lie, you'll be replaced."

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

## The Bottom Line

**No shortcuts for verification.**

Run the command. Read the output. THEN claim the result.

This is non-negotiable.
