# scrapup

🌐 **English** | [日本語](./README.ja.md) | [Português](./README.pt.md)

> From informational scrap to forged delivery — software built by an **AI-assisted Unified Process**.

**scrapup** is an ecosystem of *skills*, *agents*, and *commands* for [Claude Code](https://claude.com/claude-code) that operationalizes the **document → validate → deliver** cycle with engineering rigor. The name carries the project's thesis: raising (*up*) raw material (*scrap*) into delivered software, through a modernized, agent-assisted **Unified Process (UP)** — where the developer is repositioned from **executor** to **architect and validator**, while agents run the engineering workflows.

## Why it exists

AI-driven work tends to produce fast and fragile results. scrapup imposes a contract along the way:

- **Traceable contract (SDD):** every feature derives from a versioned spec, not a loose prompt.
- **Multi-lens validation:** review from multiple perspectives (quality, security, architecture, observability…) before concluding.
- **Delivery with evidence:** nothing is "done" without observable verification.
- **Open tooling:** integration with the open ecosystem, no closed proprietary stack.

## Approach

scrapup keeps the **Unified Process pillars** as an unchanging constitution and modernizes only *who* does the work:

- **The pillars stay** — use-case driven, architecture-centric, iterative & incremental, risk-driven.
- **Agents run the engineering workflows** — Requirements → Analysis → Design → Implementation → Test.
- **The human keeps two roles** — **Architect** (owns the architecture and the executable baseline) and **Validator** (adjudicates multi-lens review and seals each phase milestone: LCO → LCA → IOC → Product Release).

Because execution becomes cheap and automated, the leverage shifts to the **control points** — architecture, milestones, and risk ordering — which is exactly where the architect/validator works.

## Status

**Beta — first public release.** scrapup is configured as an installable Claude Code plugin; the ecosystem is being consolidated here from prior work, and the artifact catalog grows incrementally. Published so far: the `communication` skill (`skills/foundations/communication`) — the output register and form doctrine for every Unified Process stakeholder.

## Installation

> Requires [Claude Code](https://claude.com/claude-code).

```bash
/plugin marketplace add scrapup/scrapup
/plugin install scrapup
# Restart the session to discover skills, agents, commands, and MCP servers
```

Local development:

```bash
git clone git@github.com:scrapup/scrapup.git
claude --plugin-dir ./scrapup
```

## License

[MIT](LICENSE) © 2026 scrapup

## Author

Marco Antonio Luqueti Faustino.
