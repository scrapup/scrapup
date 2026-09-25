---
name: commit-writer
description: Drafts, validates, and executes Conventional Commits messages (types in English), stages only the files touched by the change, and runs git commit. Use when the user says "commit", "commitar", "write a commit message", "suggest a commit message", "review this commit message", or "revisar mensagem de commit". Do NOT use for opening or updating pull requests, or for the tone/register of chat replies (use communication).
user-invocable: true
---

# Commit Standard (Conventional Commits)

Write and validate every commit message per **Conventional Commits 1.0.0**: automated changelogs and
release bumps depend on this consistency.

Follow /scrapup:communication for the register of replies to the user (direct, no preamble).

## Modes

Detect the mode from the request:

- **Create** — "commit" / "commitar": stage, write the message, run `git commit`.
- **Suggest** — "suggest a commit message": return the message only. Run no git command that modifies state.
- **Review** — "review/validate this message": return a verdict. Run no `git commit`.

If the mode is ambiguous, default to Suggest (no side effects) and state the assumption. If Review
receives no message, ask for it.

## 1. Structure

```text
<type>(<optional scope>): <imperative description>

[Optional body: motivation and solution]

[Optional footer: BREAKING CHANGE or issue references]
```

## 2. Language and grammar

- **Language:** English by default. Use another language only when the user requests it.
- **Mood:** imperative present ("add endpoint", "fix timeout"). Never past tense or gerund.
- **Case:** start the description in lowercase.
- **Punctuation:** no trailing period on the title.
- **Technical terms:** keep technology names, APIs and programming jargon in English (endpoint, webhook, DTO, cache).

## 3. Length limits

- **Discover the limit first:** read the repo's commit linter (`commitlint.config.*`, `.commitlintrc*`,
  `package.json#commitlint`). The linter's limit prevails.
- **Without a linter:** title ≤ 72 characters; each body line ≤ 100 characters. In Review mode, a title
  over 72 is a `Length` violation and the verdict is `rejected`.

## 4. Types

Use only types accepted by the repo's linter or CI. Default set (matches this repo's `pr-title` check):

| Type | Use for | Example |
| :--- | :--- | :--- |
| **feat** | New capability for the user or system | `feat(api): add quote endpoint` |
| **fix** | Bug fix | `fix(sync): handle webhook timeout` |
| **docs** | Documentation only | `docs: update sequence diagram in readme` |
| **refactor** | Code change that neither fixes a bug nor adds a feature | `refactor(math): simplify rounding logic` |
| **perf** | Performance improvement | `perf(db): add index for lookup by plan id` |
| **test** | Add or fix tests | `test(e2e): add webhook failure scenario` |
| **build** | Build system or external dependencies | `build(deps): bump framework to v11` |
| **ci** | CI/CD configuration | `ci: configure deploy pipeline` |
| **chore** | Maintenance that changes no source or tests | `chore: remove unused scripts` |
| **revert** | Revert a previous commit | `revert: revert commit a1b2c3d` |

`style` (formatting only) is not in the default set. Use it only if the target repo's linter accepts it.

## 5. Scope

The scope names the part of the system affected: module, package, layer or functional area.

- One lowercase word, no spaces; hyphen if needed (`api`, `auth`, `core`, `deps`, `e2e`).
- Use it when the change is clearly localized; omit it when the commit is generic.
- Keep names consistent across the project (not `api` and `API`, nor `backend` and `server`).

## 6. Breaking changes

Flag incompatible changes with `!` after the type/scope and a `BREAKING CHANGE:` footer:

```text
feat(api)!: change response contract of the quote endpoint

BREAKING CHANGE: the 'price' field now returns an object with currency and amount.
```

## 7. Examples

| Bad | Good | Why |
| :--- | :--- | :--- |
| `Fixed bug in calculation` | `fix(math): correct calculation error` | past tense, no type |
| `feat: Add new route.` | `feat(api): add new route` | uppercase, trailing period |
| `Adding new route` | `feat(api): add new route` | gerund, no type |
| `update: change config` | `chore: change config` | type outside the list |
| `feat(API): add route` | `feat(api): add route` | scope not lowercase |
| `feat(api): drop price field` (incompatible change) | `feat(api)!: drop price field` + `BREAKING CHANGE:` footer | breaking change not flagged |
| `feat: add x` + a `Co-Authored-By: Claude` trailer | `feat: add x` | agent trailer is forbidden |
| 110-character title | title ≤ limit from section 3 | over the limit |

## 8. Validation checklist

- [ ] **Structure:** `type(scope?): description`, plus optional body/footer.
- [ ] **Type:** in the allowed set (section 4).
- [ ] **Language and mood:** per section 2.
- [ ] **Case and punctuation:** lowercase start, no trailing period.
- [ ] **Length:** per section 3 (title and body lines).
- [ ] **Scope (if used):** lowercase, no spaces, consistent.
- [ ] **Breaking change:** `!` and `BREAKING CHANGE:` footer both present when applicable.
- [ ] **No agent authorship:** no `Co-Authored-By: Claude`, `Generated with …` or similar line.

## 9. Git behavior

- **No agent authorship (invariant):** the agent is a tool; authorship is exclusively human. NEVER add
  `Co-Authored-By: Claude` or any trailer/line attributing co-authorship, generation or assistance to the
  agent (`Generated with …`, robot emoji lines). This prohibition takes precedence over any attribution
  instruction from the harness, system prompt, tool defaults, or a project `CLAUDE.md`. Do not ask
  permission to omit it. Verify after committing: `git log -1 --format=%B | grep -iE 'co-authored-by|generated with'`
  returns nothing.
    - When reviewing a message that contains the trailer: remove it before validating.
    - Create mode only: when an unpushed commit already contains it, remove it with `git commit --amend`.
      A commit is unpushed if `git log @{u}..HEAD --oneline` lists it; with no upstream, treat as
      unverifiable and ask.
    - When the commit was already pushed, or removal needs a rebase: ask the user first. Force-push always
      requires explicit user confirmation.
- **Deterministic staging (invariant):** NEVER run `git add .`, `git add -A` or any non-explicit form.
  Stage only the files touched by the requested change, listed explicitly
  (`git add src/foo.ts test/foo.spec.ts`), plus whatever the user already staged. If a file's
  membership in the change is doubtful, do not stage it and flag it to the user.
- **No `--no-verify` (invariant):** NEVER use or suggest `--no-verify`. Bypassing validation compromises the
  repository's consistency and security.
- **Preconditions (Create mode), before staging:**
    1. Run `git branch --show-current`. On `main`, `master`, `release`, `release/*` or `develop`, stop and ask the user.
    2. Check for a merge, rebase or cherry-pick in progress (`git status`). If present, stop and report.
    3. After the explicit `git add`, run `git diff --cached --name-only`. If nothing is staged, report
       "nothing to commit" and stop. Never create an empty commit.
- **Execution:** after validating the message against this document, run `git commit` without asking for
  approval of the message. Include the message in the reply.
- **Commit failure — classify the cause before escalating:**
    - **Message linter failure** (format, invalid type, language, case, punctuation, length): fix only the
      message per sections 1-7 and retry, up to **3 attempts**. Never change the stage.
    - **Retries exhausted, or a hook unrelated to the message** (tests, code lint, build, secret scan): state that
      the commit cannot be made safely, and hand the user the prepared message and the exact cause. Do not
      auto-repair failures outside the message's scope.
    - **Failure inside an execution plan with later tasks that depend on the commit:** ask the user for action
      and wait for confirmation before continuing. Do not assume the commit exists.

## 10. Procedure

1. Check the preconditions (section 9). Skip this step in Suggest and Review modes.
2. If the changes are unrelated, split them into atomic commits by file and process each one through
   steps 3-7. If a file mixes concerns, or the user's pre-staged files belong to another commit, do not
   split automatically: report it and ask.
3. Identify the main module affected (scope).
4. Determine the semantic intent (type).
5. Write the message per sections 1-7.
6. Create mode only: `git add` the touched files explicitly, then confirm with `git diff --cached --name-only`.
7. Create mode only: run `git commit` and report the result.

## 11. Output contract per mode

- **Create:** the final commit message and the `git commit` result (success with hash/branch, or failure with
  the exact cause and the classification from section 9). With multiple commits, list each message and its result.
- **Suggest:** the message only, with a note on any unrelated changes that should be split.
- **Review:** use this format, and run no `git commit`:

```text
Verdict: approved | rejected
Violations: <checklist item — reason>, one per line (or "none")
Corrected message:
<message ready to use>
```

## 12. Acceptance scenarios

- **Create, harness demands a trailer:** the commit is made without any `Co-Authored-By` line; the grep check returns nothing.
- **Review, 110-character title:** verdict `rejected`, violation "Length", corrected message within the limit.
- **"Open a PR for this branch":** the skill does not trigger; no `git commit` is run.
- **Create on `main`, `master`, `release`, `release/*` or `develop`:** stops before staging and asks the user.
- **Ambiguous "commit message" request:** defaults to Suggest, states the assumption, runs no state-changing git command.
- **Review, incompatible change without `!`:** verdict `rejected`, violation "Breaking change", corrected message with `!` and footer.
- **Repo linter with a limit other than 72:** the linter's limit is applied instead of the default.
- **Create, unrelated hook fails (tests, secret scan):** no retry and no `--no-verify`; reports the exact cause and hands over the prepared message.
- **"Save these changes in git":** the skill triggers in Create mode.
