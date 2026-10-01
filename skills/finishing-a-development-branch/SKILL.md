---
name: finishing-a-development-branch
description: Presents structured merge/PR/keep/discard options and executes the chosen integration once implementation is complete and verified. Use when the user says "finish the branch", "wrap up", "merge this". Do NOT use for writing commit messages (use /scrapup:commit-writer) or requesting review (use /scrapup:requesting-code-review).
---

# Finishing a Development Branch

**Core principle:** Verify tests → Present options → Execute choice → Clean up.

## The Process

### Step 1: Verify Tests

Run the project's test command (from `package.json`/`Makefile`/CI config). If none exists, state so and ask the user (Architect-Validator) before proceeding. Delegate the evidence requirement to `/scrapup:verification-before-completion` — report the actual command and its output, never an assumed result.

**If tests fail:**
```
Tests failing (<N> failures). Must fix before completing:

[Show failures]

Cannot proceed with merge/PR until tests pass.
```

Stop. Don't proceed to Step 2.

**If tests pass:** Continue to Step 2.

### Step 2: Determine Base Branch and Record State

```bash
# Try common base branches
git merge-base HEAD main 2>/dev/null || git merge-base HEAD master 2>/dev/null
```

If both fail, ask the user for the base branch; do not guess.

Record the branch and worktree **before any checkout** — later steps depend on these values, and `git branch --show-current` changes once you switch branches:

```bash
git branch --show-current                                  # -> <feature-branch>
git rev-parse --show-toplevel                              # -> <worktree-path>
git worktree list --porcelain | sed -n '1s/^worktree //p'  # -> <main-worktree>
```

Shell variables do not persist between tool calls: report the three values verbatim and substitute the **literal values** for `<feature-branch>`, `<worktree-path>` and `<main-worktree>` in every later command. If `<worktree-path>` differs from `<main-worktree>`, you are in a linked worktree.

### Step 3: Present Options

Present exactly these 4 options:

```
Implementation complete. What would you like to do?

1. Merge back to <base-branch> locally
2. Push and create a Pull Request
3. Keep the branch as-is (I'll handle it later)
4. Discard this work

Which option?
```

**Don't add explanation** — keep options concise.

### Step 4: Execute Choice

#### Option 1: Merge Locally

Confirm with the user before merging into a protected/default branch or pushing.

Run the merge from the main worktree — the base branch cannot be checked out inside the feature worktree:

```bash
cd "<main-worktree>"
git checkout <base-branch>
git pull

# --no-ff keeps the feature boundary visible in history; message from /scrapup:commit-writer
git merge --no-ff -m "<message>" "<feature-branch>"

# Verify tests on merged result
<test command>
```

Use `--no-ff`; any commit message via `/scrapup:commit-writer`; no agent trailers.

If tests pass on the merged result: cleanup (Step 5), which removes the worktree **before** deleting the branch.

If tests fail on the merged result: stop, do not clean up, and report the failing output. The merge is already committed locally, so `git merge --abort` no longer applies; offer `git reset --hard ORIG_HEAD` to undo it and run it only after the user confirms.

#### Option 2: Push and Create PR

Confirm with the user before pushing.

```bash
git push -u origin "<feature-branch>"
```

Open the PR as Draft by default; write the PR body via `/scrapup:communication`:

```bash
gh pr create --draft --title "<title>" --body "$(cat <<'EOF'
## Summary
<2-3 bullets of what changed>

## Test Plan
- [ ] <verification steps>
EOF
)"
```

Keep the worktree (the PR may still need the working copy).

#### Option 3: Keep As-Is

Report: "Keeping branch <name>. Worktree preserved at <path>."

**Don't cleanup worktree.**

#### Option 4: Discard

**Confirm first:**
```
This will permanently delete:
- Branch <name>
- All commits: <commit-list>
- Worktree at <path>

Type 'discard' to confirm.
```

Wait for exact confirmation. If confirmed, `cd "<main-worktree>"`. If there is no linked worktree, the feature branch is still checked out there: run `git checkout <base-branch>` first. Then go to Step 5 (force delete with `-D`).

### Step 5: Cleanup (Options 1 and 4 only)

Use the recorded literal values, not `git branch --show-current` (the current branch is now the base branch). Remove the worktree **before** deleting the branch — git refuses to delete a branch that is checked out in a worktree:

```bash
cd "<main-worktree>"

# Linked worktree only (<worktree-path> != <main-worktree>)
git worktree remove "<worktree-path>"   # Option 4 on a dirty worktree: add --force (already confirmed)

git branch -d "<feature-branch>"   # Option 1
git branch -D "<feature-branch>"   # Option 4 (unmerged work, after typed confirmation)
```

If no linked worktree exists, only delete the branch. Report completion.

## Quick Reference

| Option | Merge | Push | Keep Worktree | Cleanup Branch |
|--------|-------|------|---------------|----------------|
| 1. Merge locally | yes | - | - | yes |
| 2. Create PR | - | yes | yes | - |
| 3. Keep as-is | - | - | yes | - |
| 4. Discard | - | - | - | yes (force delete -D) |

## Red Flags and Common Mistakes

| NEVER / ALWAYS | Why |
|----------------|-----|
| NEVER proceed with failing tests; ALWAYS verify before offering options | Otherwise you merge broken code or open a failing PR |
| NEVER skip test verification on the merged result | The merge itself can break the build |
| ALWAYS present exactly 4 structured options | "What should I do next?" is ambiguous |
| NEVER delete work without typed `discard` confirmation | Discarded commits are unrecoverable in practice |
| NEVER force-push, merge into a protected/default branch or push without the user's confirmation | Outward/destructive actions belong to the user (Architect-Validator) |
| ALWAYS clean up the worktree for Options 1 and 4 only | Options 2 and 3 may still need the working copy |
| ALWAYS record branch/worktree before checkout and remove the worktree before the branch | `--show-current` changes after checkout; git blocks deleting a branch checked out in a worktree |
| NEVER add agent `Co-Authored-By` trailers; stage explicitly (never `git add .`/`-A`) | Authorship is human; implicit staging drags unrelated changes |

BAD: `git checkout main && git branch -d feature && git worktree remove <path>` from inside the feature worktree.
GOOD: record `<feature-branch>`/`<worktree-path>`/`<main-worktree>` as literal values, `cd "<main-worktree>"`, merge, `git worktree remove "<worktree-path>"`, then `git branch -d "<feature-branch>"`.

## Integration

**Called by:**
- `/scrapup:subagent-driven-development` — after all tasks complete
- `/scrapup:executing-plans` — after all batches complete

**Pairs with:**
- `/scrapup:using-git-worktrees` — cleans up the worktree created by that skill
