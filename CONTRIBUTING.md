# Contributing to scrapup

Thanks for your interest in scrapup — an open, AI-assisted Unified Process for engineering
teams. This guide covers how to set up, the conventions we enforce, and how changes flow to a
release. Contributions are expected to honor the project's principles: a **traceable contract
(SDD)**, **multi-lens validation**, and **delivery with evidence**.

## Ways to contribute

- **Issues** — report bugs, propose enhancements, or open an RFC for a larger change.
- **Pull requests** — fixes, new skills/agents/commands, documentation, tooling.

For anything non-trivial, open an issue first so the direction can be agreed before implementation.

## Development setup

> Requires [Claude Code](https://claude.com/claude-code).

```bash
git clone git@github.com:scrapup/scrapup.git
cd scrapup
claude --plugin-dir ./scrapup        # load the plugin for the session
claude plugin validate .             # validate the plugin/marketplace manifests
```

## Conventions

These are enforced — PRs that break them will be asked to change.

### Language

- **Every versioned artifact is in English** — code, skills, agents, commands, docs, diagrams,
  identifiers, comments, commit messages, PRs, issues. No exceptions.
- **README is trilingual.** `README.md` (English) is the source of truth; `README.pt.md` and
  `README.ja.md` must be updated **in the same commit**, kept structurally identical. Translate
  prose only; keep established technical terms in English (*use case*, *baseline*, *commit*,
  *skill*, *agent*, …).

### Commits

- **[Conventional Commits](https://www.conventionalcommits.org/)**, in English:
  `type(scope): subject` — e.g. `feat(skills): add inception brief layer`.
- Types: `feat`, `fix`, `docs`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`, `revert`.
- Breaking changes: add `!` or a `BREAKING CHANGE:` footer.
- Keep commits **atomic** — one coherent change per commit.

### Branching & pull requests

1. Branch from `main` (e.g. `feat/...`, `fix/...`).
2. Open a PR against `main`. Fill in the [PR template](.github/PULL_REQUEST_TEMPLATE.md).
3. The **PR title must be a Conventional Commit** — with squash merge it becomes the commit on
   `main` and drives versioning. The `pr-title` check enforces this.
4. Reviews follow [CODEOWNERS](.github/CODEOWNERS). Address feedback before merge.
5. PRs are **squash-merged** using the PR title.

### Versioning & releases

- Versioning is automated with **release-please** — **do not bump versions manually**. It owns
  `package.json`, `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
- After merges to `main`, release-please opens/updates a **Release PR** that accumulates changes
  and the `CHANGELOG`. Merging that Release PR cuts the release: tag, GitHub Release, plugin
  `.zip`, and `npm publish`.

## Before opening a PR

- Run `claude plugin validate .` and ensure it passes.
- Include **evidence** in the PR (command output, validation results) — "done" requires
  observable verification.
- If you changed `README.md`, confirm `README.pt.md` and `README.ja.md` are in sync.

## License

By contributing, you agree that your contributions are licensed under the [MIT License](LICENSE).
