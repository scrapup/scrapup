# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## The Project

**scrapup** is a plugin/ecosystem for Claude Code that operationalizes the **document → validate → deliver** software cycle with engineering rigor, anchored on an **AI-assisted Unified Process (UP)**. The name encodes the thesis: raising (*up*) raw material (*scrap*) into delivered software, through a modernized Unified Process.

Non-negotiable principles (project philosophy):

- **Traceable contract (SDD):** features derive from versioned specs, not ad-hoc prompts.
- **Multi-lens validation:** review from multiple perspectives before concluding.
- **Delivery with evidence:** "done" requires observable verification.
- **Open tooling:** integration with the open ecosystem, no closed proprietary stack.

## Current Repository State

**New repository — first public release (Beta).** Current contents:

- **Plugin manifest + self-marketplace** — `.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json`.
- **Skills** — the `communication` skill (`skills/foundations/communication`); more being migrated/consolidated.
- **Release tooling** — release-please config/manifest, `.github/workflows/` (`release-please.yml`, `pr-title.yml`), `scripts/build-plugin-zip.sh`, and `package.json` for npm publish. See [Releasing](#releasing).
- **Governance & docs** — `README` (trilingual), `CONTRIBUTING.md`, `.github/CODEOWNERS`, `.github/PULL_REQUEST_TEMPLATE.md`, `docs/`, `LICENSE` (MIT), and this `CLAUDE.md`.

The ecosystem (more skills, agents, commands, MCP servers, diagrams) is still being migrated from prior work. When adding content, document the actual architecture here as soon as it exists — do not anticipate structure that is not yet there.

## Planned Direction — AI-Assisted Unified Process

> Forward-looking roadmap, **not** current structure. The full working spec (internal, not versioned) is distilled here into its versioned form. All items below are **proposed** until materialized.

**Thesis.** Modernize the Unified Process (Jacobson/Booch/Rumbaugh, 1999) for AI-assisted development: the developer moves from **executor** to **architect + validator**, while **agents execute the engineering workflows**. The book already anticipates this — workers are detachable roles ("a role that an individual may play"), specializable or exchangeable "without changing the design of the process"; replacing human workers with agents is canonical tailoring, not a rupture.

**Invariant vs. changing.**

| UP axis | Classic UP (1999) | AI-Assisted UP (this thesis) |
|---|---|---|
| **Pillars** (use-case driven, architecture-centric, iterative & incremental, risk-driven) | Immutable | **Immutable** — the constitution; inherited, not modernized |
| **Engineering workflows** (Requirements→Analysis→Design→Implementation→Test) | Human team | **Agents** (blueprint, forge, TDAD, reviewers, expert-*) |
| **Workers / roles** | People wearing hats | **Dispatchable agents** — parallel reviewers reify the roles |
| **Human** | Does everything | **Two retained roles: Architect + Validator** |

**Two retained human roles.** **Architect** owns *architecture-centric*: defines and validates the architecture, approves the executable baseline, fixes constraints. **Validator** owns quality/verification: adjudicates the review lenses, approves milestones/gates, decides risk ordering, seals the milestone. The AI proposes and verifies; the human decides and seals.

**Leverage shifts to control points.** With execution cheap and automated, value migrates to **milestones + architecture + risk ordering**. Consequence: **Construction inverts** — the UP's largest phase (~50%) tends to become the smallest, with effort moving to Inception/Elaboration (architect/validator judgment). The phase/milestone axis stays intact; only the (always referential) effort distribution flips.

**Phases & milestones** (decision gates retained by the human-validator):

| Phase | Milestone | Gate criterion |
|---|---|---|
| Inception | **LCO** (Lifecycle Objectives) | scope, actors, candidate architecture, critical risks, business case — go/no-go to launch |
| Elaboration | **LCA** (Lifecycle Architecture) | **executable architectural baseline** proves the architecture (not a "paper" design); major risks mitigated |
| Construction | **IOC** (Initial Operational Capability) | product ready for beta in the user environment |
| Transition | **Product Release** | operates successfully in production; users satisfied |

**Convergence with the current ecosystem.** Strong in the **middle** (Construction + multi-lens verification), thin at the **ends** (Inception/Transition) and on the **risk-driven** axis — where UP still has the most to teach. Already surpasses UP in: parallel multi-lens quality review, clean-context iteration (resolves *context rot*, inconceivable pre-LLM), roles as dispatchable agents, lean tailoring, and open tooling.

**Roadmap.** Prioritized improvements toward the vision: (1) per-task risk field + risk-ordered iterations; (2) executable-baseline / skeleton gate between plan and implementation; (3) Transition via telemetry (verify features in prod post-merge); (4) formal milestone gates (LCO/LCA/IOC/Release); (5) traceability matrix (use case ↔ task ↔ test ↔ commit); (6) Inception `brief.md` bundle (vision, feature/risk/use-case lists, NFRs, candidate architecture, business case); (9) ADR artifact in Elaboration. First materialized step: the `scrapforge-inception` skill producing `brief.md` in validated layers, gated by the `reviewer-process-lco` agent.

**Boundary cautions.** Do not reintroduce RUP weight — the lean incremental flow is the differentiator; heavyweight artifacts apply only to the full flow (≥5 tasks / high impact), never to small increments. Risk-driven means *ordering execution*, not a risk-management bureaucracy. Co-evolve process and tooling together; do not stack many innovations at once.

## Conventions

- **Communication:** all output (responses, artifacts, ghostwritten text) follows the `communication` skill (`skills/foundations/communication/SKILL.md`) — register and form calibrated to the Unified Process actor being addressed.
- **Language — internationalized project:** **every versioned artifact is in English** (skills, agents, commands, documentation, diagrams, comments, identifiers, commit messages, PRs, issues). This convention is **mandatory**, no exceptions.
- **Localization — public-facing only (MUST keep in sync):** the `README` is trilingual — `README.md` (English, **source of truth**), `README.pt.md` (Portuguese), `README.ja.md` (Japanese) — each opening with the language nav line (`🌐 [English](./README.md) | [日本語](./README.ja.md) | [Português](./README.pt.md)`, the current language **bold and unlinked**). **Directive:** any change to `README.md` MUST be replicated into `README.pt.md` and `README.ja.md` in the **same commit** — never let a translation drift or land EN-only; never edit PT/JA without the corresponding EN change. Keep all three structurally identical (same sections, order, links, code blocks); translate prose only, and keep established technical terms in English (e.g., *use case*, *baseline*, *pull request*, *commit*, *skill*, *agent*, *command*). This is the only localization surface — it does not loosen the English-only rule for artifacts above.
- **Commits:** Conventional Commits (in English, per the convention above).
- **License:** MIT. Keep the copyright header coherent when adding relevant files.

## Releasing

Versioning and releases are automated with **release-please**, driven by Conventional Commits.
**Never bump versions by hand** — release-please owns the three synchronized manifests:
`package.json`, `.claude-plugin/plugin.json` (`$.version`) and `.claude-plugin/marketplace.json`
(`$.metadata.version`).

Flow (two PRs): a feature/fix PR is squash-merged to `main` (its Conventional Commit **title**
drives the bump, enforced by the `pr-title` check); release-please then opens/updates a single,
accumulating **Release PR** (`chore: release X.Y.Z`) with the bumped manifests and `CHANGELOG`.
Merging that Release PR — the **human-sealed gate** — cuts the release: git tag + GitHub Release,
the importable plugin `.zip` asset (`scripts/build-plugin-zip.sh`), and `npm publish`
`@scrapup/scrapup` with provenance.

Pre-1.0 bump rules: `fix`/`perf` → patch, `feat` → minor, breaking → minor (stays `0.x`).
Full reference — moving parts, prerequisites (secrets/settings), and maintainer steps — in
[`docs/releasing.md`](docs/releasing.md).

## Origin

Public release derived from the internal "scrapforge" ecosystem. Branding, license (MIT), and identity decisions (GitHub org `scrapup`, domain `scrapup.dev`) are recorded in `.local/docs/` (not versioned).
