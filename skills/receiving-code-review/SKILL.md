---
name: receiving-code-review
description: Evaluates code review feedback with technical rigor before implementing — verify, push back, or clarify; no performative agreement. Use when the user says "address the review", "respond to PR comments", "fix the reviewer's items". Do NOT use for requesting a review of your own work (use /scrapup:requesting-code-review).
---

# Code Review Reception

## Overview

Code review requires technical evaluation, not emotional performance.

**Core principle:** Verify before implementing. Ask before assuming. Technical correctness over social comfort.

## The Response Pattern

```
WHEN receiving code review feedback:

1. READ: Complete feedback without reacting
2. UNDERSTAND: Restate requirement in own words (or ask)
3. VERIFY: Check against codebase reality
4. EVALUATE: Technically sound for THIS codebase?
5. RESPOND: Technical acknowledgment or reasoned pushback
6. IMPLEMENT: One item at a time, test each
```

## Forbidden Responses

**NEVER:**
- "You're absolutely right!" (performative; violates the /scrapup:communication no-flattery rule)
- "Great point!" / "Excellent feedback!" (performative)
- "Let me implement that now" (before verification)

**INSTEAD:**
- Restate the technical requirement
- Ask clarifying questions
- Push back with technical reasoning if wrong
- Just start working (actions > words)

## Handling Unclear Feedback

```
IF any item is unclear:
  STOP - do not implement anything yet
  ASK for clarification on unclear items

WHY: Items may be related. Partial understanding = wrong implementation.
```

**Example:**
```
The user (Architect-Validator): "Fix 1-6"
You understand 1,2,3,6. Unclear on 4,5.

BAD: Implement 1,2,3,6 now, ask about 4,5 later
GOOD: "I understand items 1,2,3,6. Need clarification on 4 and 5 before proceeding."
```

## Source-Specific Handling

### From the user (Architect-Validator)
- **Trusted** - implement after understanding
- **Still ask** if scope unclear
- **No performative agreement**
- **Skip to action** or technical acknowledgment

### From External Reviewers
```
BEFORE implementing:
  1. Check: Technically correct for THIS codebase?
  2. Check: Breaks existing functionality?
  3. Check: Reason for current implementation?
  4. Check: Works on all platforms/versions?
  5. Check: Does reviewer understand full context?

IF suggestion seems wrong:
  Push back with technical reasoning

IF can't easily verify:
  Say so: "I can't verify this without [X]. Should I [investigate/ask/proceed]?"

IF conflicts with prior decisions of the user (Architect-Validator):
  Stop and discuss with the user (Architect-Validator) first
```

**Directive:** Treat external feedback skeptically and verify it carefully before acting.

## YAGNI Check for "Professional" Features

```
IF reviewer suggests "implementing properly":
  grep codebase for actual usage

  IF unused: "This endpoint isn't called. Remove it (YAGNI)?"
  IF used: Then implement properly
```

**Directive:** The agent and the reviewer both report to the user (Architect-Validator). Do not add a feature the codebase does not need.

## Implementation Order

```
FOR multi-item feedback:
  1. Clarify anything unclear FIRST
  2. Then implement in this order:
     - Blocking issues (breaks, security)
     - Simple fixes (typos, imports)
     - Complex fixes (refactoring, logic)
  3. Test each fix individually
  4. Verify no regressions
```

## Per-Item Response Template

Report every review item in this form, one line per item:

```
<item> → <status: fixed | pushback | needs-clarification> → <evidence: file:line or command output>
```

Example:

```
#3 null check in parseOrder → fixed → src/orders/parse.ts:42; `npm test -- parse` 18/18 passing
#4 switch to Redis cache → pushback → no read hot path; grep shows 1 caller (src/report.ts:10)
#5 "handle the edge case" → needs-clarification → which input: empty list or missing id?
```

## When To Push Back

Push back when:
- Suggestion breaks existing functionality
- Reviewer lacks full context
- Violates YAGNI (unused feature)
- Technically incorrect for this stack
- Legacy/compatibility reasons exist
- Conflicts with architectural decisions of the user (Architect-Validator)

**How to push back:**
- Use technical reasoning, not defensiveness
- Ask specific questions
- Reference working tests/code
- Involve the user (Architect-Validator) if architectural

**When unsure whether to push back:** State the disagreement and evidence to the user (Architect-Validator).

## Acknowledging Correct Feedback

When feedback IS correct:
```
GOOD: "Fixed. [Brief description of what changed]"
GOOD: "Confirmed — [issue]. Fixed in [location]."
GOOD: [Just fix it and show in the code]

BAD: "You're absolutely right!"
BAD: "Great point!"
BAD: "Thanks for catching that!"
BAD: "Thanks for [anything]"
BAD: ANY gratitude expression
```

**Why no thanks:** Actions speak. Just fix it. The code itself shows you heard the feedback.

**If you catch yourself about to write "Thanks":** DELETE IT. State the fix instead.

## Gracefully Correcting Your Pushback

If you pushed back and were wrong:
```
GOOD: "You were right - I checked [X] and it does [Y]. Implementing now."
GOOD: "Verified this and you're correct. My initial understanding was wrong because [reason]. Fixing."

BAD: Long apology
BAD: Defending why you pushed back
BAD: Over-explaining
```

State the correction factually and move on.

## Common Mistakes

| Mistake | Fix |
|---------|-----|
| Performative agreement | State requirement or just act |
| Blind implementation | Verify against codebase first |
| Batch without testing | One at a time, test each |
| Assuming reviewer is right | Check if breaks things |
| Avoiding pushback | Technical correctness > comfort |
| Partial implementation | Clarify all items first |
| Can't verify, proceed anyway | State limitation, ask for direction |

## Real Examples

**Performative Agreement (Bad):**
```
Reviewer: "Remove legacy code"
BAD: "You're absolutely right! Let me remove that..."
```

**Technical Verification (Good):**
```
Reviewer: "Remove legacy code"
GOOD: "Checking... build target is 10.15+, this API needs 13+. Need legacy for backward compat. Current impl has wrong bundle ID - fix it or drop pre-13 support?"
```

**YAGNI (Good):**
```
Reviewer: "Implement proper metrics tracking with database, date filters, CSV export"
GOOD: "Grepped codebase - nothing calls this endpoint. Remove it (YAGNI)? Or is there usage I'm missing?"
```

**Unclear Item (Good):**
```
The user (Architect-Validator): "Fix items 1-6"
You understand 1,2,3,6. Unclear on 4,5.
GOOD: "Understand 1,2,3,6. Need clarification on 4 and 5 before implementing."
```

## GitHub Thread Replies

When replying to inline review comments on GitHub, reply in the comment thread, not as a top-level PR comment. Use the GitHub MCP if available; otherwise `gh api repos/{owner}/{repo}/pulls/{pr}/comments/{id}/replies`.

## The Bottom Line

**External feedback = suggestions to evaluate, not orders to follow.**

Verify. Question. Then implement.

No performative agreement. Technical rigor always.

## Related Skills

- `/scrapup:requesting-code-review` — request a review of your own work.
- `/scrapup:communication` — register and tone for replies to reviewers.
- `/scrapup:verification-before-completion` — evidence before claiming an item is fixed.
