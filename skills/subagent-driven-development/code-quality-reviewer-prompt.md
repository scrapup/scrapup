# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

**Only dispatch after spec compliance review passes.**

```
Agent tool (general-purpose subagent + code-reviewer.md template):
  Use template at ../requesting-code-review/code-reviewer.md (/scrapup:requesting-code-review)

  WHAT_WAS_IMPLEMENTED: [one-line title of the task, from implementer's report]
  PLAN_REFERENCE: Task N from [plan-file] (paste the full task text)
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  DESCRIPTION: [details: scope, key decisions, files changed]
```

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment (`Ready to merge: Yes | No | With fixes | No changes | Invalid range`)

**Mapping:** any Critical or Important issue → implementer fixes, then re-review; otherwise proceed.
