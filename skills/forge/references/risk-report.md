# Pre-Execution Risk Report

Load when: section 4.3 of `SKILL.md`.

Before executing, generate a risk report for the user. At this point the agent already has: toolchain checked, artifacts read, placeholders resolved, baseline recorded, TFs extracted with dependencies mapped.

## Current data

Query mcp-saga (`task_list` + `task_get` with dependencies) for structured per-TF data: status, dependencies, notes, blockers. Use it as the basis of the analysis instead of re-reading `tasks.md`.

## Historical data

Query mcp-saga for earlier executions to calibrate the analysis:

1. `activity_log` — status change history, real time between `in_progress` and `done` per TF.
2. `note_search` type `technical` — recurring failure patterns, integration problems, `guardrail:` notes.
3. `note_search` type `progress` — earlier session summaries: what worked, what failed.
4. `tracker_search` by technology keywords, e.g. "jwt", "zod", "prisma migrate", "rabbitmq".

| Historical data | How it calibrates | Example |
|---|---|---|
| Real vs estimated time | Adjusts the time estimate | Guard TFs took 15 min on average, not 8 |
| TFs that failed in earlier projects | Identifies risk patterns | "Prisma migration failed twice with MySQL offline" |
| Most frequent error types | Prioritizes mitigations | "60% of validation failures are lint, not tests" |
| Post-commit validation cycles | Estimates real cost | "UseCase TFs use 4-5 cycles on average" |

With no history (first use of mcp-saga or a new project): say the analysis has no historical data and use the technical analysis only.

## Per-TF analysis

- **Complexity:** distinct concepts, files, dependencies.
- **Type:** code (TDAD) vs infra/config (DoD).
- **Technical risks:** new libraries, undocumented patterns, integration with external systems.
- **External data:** credentials, IPs, third-party tokens.
- **History:** similar TFs in earlier projects, real time, failure patterns.

## Report content

1. **Estimated success probability** (%), calibrated by history when available.
2. **High-risk TFs** with justification and similar failure patterns found in history.
3. **Mitigation suggestions:** slice a complex TF into sub-TFs; provide more context (e.g. reference an existing guard in the project); resolve a pending external dependency; reorder parallelization waves.
4. **Parallelization waves** with the TFs in each.
5. **Estimated execution time**, calibrated by real times of earlier executions.

## User decision

Present the report and ask:

- "Do you want to take actions before continuing?" (slice TFs, provide context, resolve dependencies)
- "Do you want to adjust the test/lint commands recorded in section 0?"
- "Do you want to remove any TF from this execution?"
- "Do you want to proceed as is?"
