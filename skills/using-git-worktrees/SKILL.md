---
name: using-git-worktrees
description: Creates isolated git worktrees with directory selection, gitignore safety check, dependency setup and baseline test verification. Use when the user says "create a worktree", "isolate this work", or before parallel plan execution. Do NOT use for removing worktrees or merging (use /scrapup:finishing-a-development-branch) or for sequential tasks on a single branch.
---

# Using Git Worktrees

**Core principle:** Systematic directory selection + safety verification = reliable isolation.

## Directory Selection Process

Follow this priority order:

### 1. Check Existing Directories

```bash
# Check in priority order
ls -d .worktrees 2>/dev/null     # Preferred (hidden)
ls -d worktrees 2>/dev/null      # Alternative
```

**If found:** Use that directory. If both exist, `.worktrees` wins.

### 2. Check CLAUDE.md

```bash
grep -i "worktree.*director" CLAUDE.md 2>/dev/null
```

**If a single, unambiguous preference is specified:** Use it without asking.

**If ambiguous** (multiple matches, conflicting locations, or a preference in another CLAUDE.md): ask the user (Architect-Validator).

### 3. Ask the User

If no directory exists and no CLAUDE.md preference, ask the user (Architect-Validator):

```
No worktree directory found. Where should I create worktrees?

1. .worktrees/ (project-local, hidden)
2. ~/.config/scrapup/worktrees/<project-name>/ (global location)

Which would you prefer?
```

## Safety Verification

### For Project-Local Directories (.worktrees or worktrees)

**MUST verify directory is ignored before creating worktree:**

```bash
# Check if directory is ignored (respects local, global, and system gitignore)
# Check the directory you will actually use (<dir> = .worktrees or worktrees)
git check-ignore -q <dir>
```

**If not ignored:** add `<dir>/` to `.gitignore`, stage only that file (`git add .gitignore`), and ask the user before committing; never commit on the default branch without consent.

**Why critical:** Prevents accidentally committing worktree contents to repository.

### For Global Directory (~/.config/scrapup/worktrees/$project/)

No .gitignore verification needed — outside project entirely.

## Creation Steps

Shell variables do not persist between tool calls. Run Steps 1-2 in a **single** Bash call with the values set as literals at the top, and afterwards use the resulting absolute path in every command (a `cd` does not carry over to the next call).

### 1. Detect Project Name and Branch Name

Define `BRANCH_NAME` from the task (e.g. `feature/<task-slug>`); if the task does not imply one, ask the user. `LOCATION` is the directory chosen above: `.worktrees`, `worktrees` or `global`.

### 2. Create Worktree (single Bash call)

```bash
LOCATION=<.worktrees|worktrees|global>
BRANCH_NAME=<branch-name>
project=$(basename "$(git rev-parse --show-toplevel)")

# Stop if the branch already exists (see Failure Handling)
git show-ref --verify --quiet "refs/heads/$BRANCH_NAME" && { echo "branch exists"; exit 1; }

# Determine full path
case $LOCATION in
  .worktrees|worktrees)
    path="$LOCATION/$BRANCH_NAME"
    ;;
  global)
    path="$HOME/.config/scrapup/worktrees/$project/$BRANCH_NAME"
    ;;
esac

# Create worktree with new branch
git worktree add "$path" -b "$BRANCH_NAME" && cd "$path" && pwd   # report this absolute path
```

BAD: `path="~/.config/..."` — a quoted `~` is not expanded and creates a literal `~` directory.
GOOD: `path="$HOME/.config/scrapup/worktrees/$project/$BRANCH_NAME"`.

### 3. Run Project Setup

Auto-detect from project files. For Node projects, detect the package manager from the lockfile and delegate setup to `/scrapup:setup-node-env`:

| Lockfile / manifest | Setup |
|---------------------|-------|
| `pnpm-lock.yaml` | `pnpm install` (via `/scrapup:setup-node-env`) |
| `yarn.lock` | `yarn install` (via `/scrapup:setup-node-env`) |
| `package-lock.json` / `package.json` | `npm install` (via `/scrapup:setup-node-env`) |
| `Cargo.toml` | `cargo build` |
| `poetry.lock` / `pyproject.toml` | `poetry install` |
| `requirements.txt` | `pip install -r requirements.txt` |
| `go.mod` | `go mod download` |
| none of the above | Skip dependency install |

### 4. Verify Clean Baseline

Run the project's test command (from `package.json`/`Makefile`/CI config) to ensure the worktree starts clean.

**If tests fail:** Report failures, ask whether to proceed or investigate.

**If tests pass:** Report ready.

**If no test suite exists:** report "no test suite found" and do not claim a clean baseline.

### 5. Report Location

```
Worktree ready at <full-path>
Tests passing (<N> tests, 0 failures)
Ready to implement <feature-name>
```

## Failure Handling

| Failure | Action |
|---------|--------|
| Branch `$BRANCH_NAME` already exists | Do not reuse or overwrite; report it and ask the user for a new name or whether to attach a worktree to the existing branch |
| Worktree path already exists | Do not delete it; check `git worktree list`, report and ask the user |
| `git worktree add` fails | Report the exact error; do not retry with `--force`; escalate to the user |
| Dependency setup fails | Report the error; for Node, defer to `/scrapup:setup-node-env`; escalate if unresolved |
| No test suite | Report "no test suite found"; do not claim a clean baseline |

## Quick Reference and Red Flags

| Situation | Action | Why |
|-----------|--------|-----|
| `.worktrees/` exists | Use it (verify ignored) | Existing convention wins |
| `worktrees/` exists | Use it (verify ignored) | Existing convention wins |
| Both exist | Use `.worktrees/` | Hidden directory is preferred |
| Neither exists | Check CLAUDE.md → ask the user | NEVER assume a location — it breaks project conventions |
| CLAUDE.md ambiguous | Ask the user | Guessing between conflicting preferences is an architecture decision |
| Directory not ignored | Add to `.gitignore`, stage only that file, ask before committing | NEVER create a project-local worktree unignored — its contents get tracked and pollute `git status` |
| Tests fail during baseline | Report failures + ask | NEVER proceed silently — you cannot distinguish new bugs from pre-existing ones |
| No test suite | Report "no test suite found" | NEVER claim a clean baseline without evidence |
| Setup commands | Auto-detect from lockfile/manifest | NEVER hardcode — breaks on projects using other tools |

## Example Workflow

```
[Check .worktrees/ - exists]
[Verify ignored - git check-ignore confirms .worktrees/ is ignored]
[BRANCH_NAME=feature/auth - verify branch does not exist]
[Create worktree: git worktree add .worktrees/feature/auth -b feature/auth]
[Detect package-lock.json - setup via /scrapup:setup-node-env]
[Run npm test - 47 passing]

Worktree ready at /path/to/project/.worktrees/feature/auth
Tests passing (47 tests, 0 failures)
Ready to implement auth feature
```

## Integration

**Called by:**
- `/scrapup:subagent-driven-development` — REQUIRED before executing tasks (isolated workspace per the skill's own contract)
- `/scrapup:executing-plans` — REQUIRED before executing tasks
- `/scrapup:forge` — REQUIRED only for independent tasks run in parallel (US mode); sequential execution works on a branch, without a worktree
- Any skill needing an isolated workspace

> A worktree is required for **parallel execution isolation**, not for every task. Sequential flows (sequential forge) and `/scrapup:test-driven-agentic-development` (agnostic) do not require it.

**Pairs with:**
- `/scrapup:finishing-a-development-branch` — REQUIRED for cleanup after work is complete
