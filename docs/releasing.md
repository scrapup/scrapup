# Releasing scrapup

Versioning and releases are automated with [release-please](https://github.com/googleapis/release-please).
Versions are computed from [Conventional Commits](https://www.conventionalcommits.org/) — maintainers
do **not** bump versions by hand. A release ships three things from a single merge: a GitHub Release
(tag + `CHANGELOG`), the importable plugin `.zip`, and the npm package `@scrapup/scrapup`.

## Moving parts

| File | Role |
|---|---|
| `release-please-config.json` | How to version: `release-type: node`, pre-1.0 bump rules, and `extra-files` that sync the version into the plugin manifests. |
| `.release-please-manifest.json` | The current version (release-please reads and rewrites it). |
| `.github/workflows/release-please.yml` | Orchestrates: opens/updates the Release PR; on release, builds the `.zip`, attaches it, and publishes to npm. |
| `scripts/build-plugin-zip.sh` | Packages the importable plugin `.zip` (manifest at the zip root). |
| `.github/workflows/pr-title.yml` | Validates the PR title as a Conventional Commit (the squash commit that release-please parses). |
| `package.json` | npm package version + publish metadata (provenance). |

The version is mirrored into **three manifests**, all kept in sync by release-please:
`package.json`, `.claude-plugin/plugin.json` (`$.version`), and `.claude-plugin/marketplace.json`
(`$.metadata.version`).

## How the version is computed

While in `0.x` (config: `bump-minor-pre-major: true`, `bump-patch-for-minor-pre-major: false`):

| Commit | Bump | Example |
|---|---|---|
| `fix:` / `perf:` | patch | 0.2.0 → 0.2.1 |
| `feat:` | minor | 0.2.1 → 0.3.0 |
| `feat!:` / `BREAKING CHANGE:` | minor (stays `0.x`) | 0.3.0 → 0.4.0 |
| `docs:` / `chore:` / `ci:` / `refactor:` / `test:` / `build:` | none | — |

After `1.0.0`, the usual SemVer applies: `feat` → minor, `fix` → patch, breaking → major.

## The flow (two PRs)

```
feature/fix PR ── squash ──▶ main
                               └─ release-please opens/updates ONE "Release PR"
                                  (chore: release X.Y.Z) accumulating all changes
                                  + CHANGELOG, with the three manifests bumped

merge the Release PR ──▶ release:
   ├─ git tag vX.Y.Z + GitHub Release + CHANGELOG
   ├─ build scrapup-vX.Y.Z.zip → attach as a Release asset
   └─ npm publish @scrapup/scrapup (provenance)
```

- Your feature PR title must be a Conventional Commit — it becomes the squash commit and drives
  the bump. The `pr-title` check enforces it.
- The **Release PR is a single, living PR**: more merges to `main` update the same PR (version and
  `CHANGELOG` recomputed). It is the human-sealed gate — nothing publishes until a maintainer merges it.
- Do **not** push to the `release-please--branches/main` branch; release-please force-pushes it.

## Cutting a release (maintainer)

1. Merge the feature/fix PRs into `main`.
2. Review the open **Release PR** — confirm the proposed version and `CHANGELOG`.
3. Merge it. The workflow publishes the GitHub Release, the `.zip`, and the npm package.

### Force a specific version

Add a footer to a commit (or the Release PR) body:

```
Release-As: 1.0.0
```

## Prerequisites (one-time, repo/org settings)

- **Actions → Workflow permissions:** the workflow grants write via its `permissions:` block; the
  org default may stay read-only. **"Allow GitHub Actions to create and approve pull requests"**
  must be enabled (so release-please can open the Release PR).
- **npm:** secret `NPM_TOKEN` (granular token, scope `@scrapup`, write, bypass 2FA) — or migrate to
  **OIDC Trusted Publishing** (no token, no rotation; `id-token: write` is already set).
- **Public repo** — required for npm provenance.
- **Merge strategy:** squash merge with "Default to pull request title".
- **Branch protection** on `main` requiring the `pr-title` check.

## How a release is consumed

```bash
# npm — installs and registers the plugin
npm install -g @scrapup/scrapup

# plugin marketplace (git, no npm)
/plugin marketplace add scrapup/scrapup
/plugin install scrapup

# the .zip asset (session-only)
claude --plugin-dir ./scrapup-vX.Y.Z.zip
claude --plugin-url https://github.com/scrapup/scrapup/releases/download/vX.Y.Z/scrapup-vX.Y.Z.zip
```
