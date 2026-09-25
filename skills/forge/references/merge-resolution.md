# Spec-Driven Merge Conflict Resolution

Load when: section 5 of `SKILL.md`, a `git merge --no-ff {worktree-branch}` produced a conflict.

The agent holds the SDD artifacts (`spec.md`, `plan.md`, `tasks.md` or `single-tasks.md`) with the full specification of each TF. Use them as the source of truth to resolve the conflict; escalating to the user is not the first step.

**Principle:** if the agent has enough specification to implement, it has enough to decide the merge.

## Flow

1. The merge results in a conflict.
2. List conflicting files: `git diff --name-only --diff-filter=U`.
3. For each conflicting file:
   a. Read the conflicted content (markers `<<<<<<<`, `=======`, `>>>>>>>`).
   b. Consult the SDD artifacts: which TF touched this file and with what intent.
   c. Consult mcp-saga: `task_get` of both TFs for notes, commit messages and implementation context.
   d. Combine both implementations respecting the specification: the result must satisfy the requirements of BOTH TFs.
   e. If both TFs change the same function/method: compose the changes (TF-A adds field X, TF-B adds field Y → the result has both).
   f. If the TFs are genuinely contradictory (one removes what the other adds): the specification of the TF with higher priority in the dependency graph prevails; at equal priority, consult `spec.md` for the intended behavior.
4. Resolve in the file (edit directly, remove the markers).
5. `git add {resolved-file}` (explicit).
6. Run the impacted tests via TDAD (/scrapup:test-driven-agentic-development) to verify the resolution did not break either TF.
7. If tests fail: adjust the resolution and re-verify (max 3 cycles; see **Iteration limits** in `SKILL.md`).
8. If it does not converge after 3 cycles: **then** escalate to the user with full context (file, conflict, both TFs, the attempted resolution, failing tests).
9. After all conflicts are resolved: `git commit` (merge commit), message via /scrapup:commit-writer.
10. Record in mcp-saga: `comment_add` on both TFs describing the resolved conflict and how.
