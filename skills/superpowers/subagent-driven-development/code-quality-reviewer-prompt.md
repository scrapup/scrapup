# Code Quality Reviewer Prompt Template

Use this template when dispatching a code quality reviewer subagent.

**Purpose:** Verify implementation is well-built (clean, tested, maintainable)

> **Supersession (scrapup):** inside the scrapup ecosystem this template is superseded by `/scrapup:multi-spec-review` (9 lenses). Use it only when running `subagent-driven-development` standalone outside the plugin AND `/scrapup:multi-spec-review` does not resolve. See the "Selection criterion" table in `SKILL.md` for the observable rule.

**Only dispatch after spec compliance review passes.**

```
Agent tool (general-purpose subagent + code-reviewer.md template):
  Use template at requesting-code-review/code-reviewer.md

  WHAT_WAS_IMPLEMENTED: [from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  DESCRIPTION: [task summary]
```

**Code reviewer returns:** Strengths, Issues (Critical/Important/Minor), Assessment
