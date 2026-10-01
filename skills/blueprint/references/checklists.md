# Per-Phase Checklists

Create every item as a todo in the agent's checklist tool when the phase starts.

**Existing Documentation Analysis (if docs were provided or SDD artifacts exist — review mode):**
- [ ] Read every document provided by the user
- [ ] Build the inventory (file, type, main content)
- [ ] Classify content per SDD phase (coverage % per phase)
- [ ] Analyze internal consistency (contradictions, ambiguities)
- [ ] Validate adherence to the Ironclad Philosophy (4 principles)
- [ ] Detect knowledge gaps per phase
- [ ] Generate the structured report and present it to the user
- [ ] Request missing information per the Blocking Information Rule (`SKILL.md`, **Discovery Mode**)
- [ ] Review mode: preserve every existing ID (`BR-XX`, `US-XX`, `TF-XX-YY`); output the section 4 report only
- [ ] Recommend next steps (produce spec/plan/tasks or resolve gaps)

**Artifact Production (no prior SDD):**
- [ ] Docs analysis (step 0, if the user provided existing documentation)
- [ ] Brainstorming with the user (/scrapup:brainstorming): explore intent, context, approaches
- [ ] Analyze the workspace: code, configs, schemas, routes, modules, tests
- [ ] Refinement loop: ask the user per the Blocking Information Rule until the Discovery Mode criterion is met
- [ ] Impact triage: choose between the incremental (<= 5 TF) and the full flow
- [ ] Produce the right artifact: `single-tasks.md` or start the full flow
- [ ] Limit gate: check that `single-tasks.md` does not exceed 5 TF
- [ ] Present to the user and wait for approval

**Phase 1 (spec.md):**
- [ ] Discovery Mode — check for sufficient information
- [ ] Fill every section of the template
- [ ] Validate Zero Trust in the edge cases
- [ ] Present to the user and wait for approval

**Phase 2 (plan.md):**
- [ ] Check prerequisites (approved spec.md, volume defined)
- [ ] Generate PlantUML diagrams (/scrapup:expert-plantuml): C4 L2 (Containers), C4 L3 (Components), Sequence (success + failure), Envelope/Traceability (if there is a queue)
- [ ] Define IDL contracts (OpenAPI/AsyncAPI)
- [ ] Document the resilience strategy
- [ ] Define observability metrics, logs and traces
- [ ] Present to the user and wait for approval

**Phase 3 — `tasks.md` (full flow):**
- [ ] Check prerequisites (`plan.md` approved with DTOs and schemas)
- [ ] Define User Stories (value deliverables)
- [ ] Ask the user for the first User Story ID and the Epic reference (`Epic: none (incremental)` if none), and derive the IDs of the new User Stories sequentially (see **User Story Identifiers** in `SKILL.md`)
- [ ] Include per-US diagrams proportional to scope — C4 L2 + Sequence when there is more than one container, a non-trivial failure or messaging; a single-flow US needs only Sequence (reuse/adapt the plan.md diagrams)
- [ ] Sequence Tasks topologically inside each User Story (`TF-XX-YY` inherits `XX` from the US, `YY` locally sequential)
- [ ] Generate each Task in the full format (Task template)
- [ ] Include Execution Guidance per Task (section 4); decide per TF whether to add the optional decomposition hint (section 4.7)
- [ ] Present to the user and wait for approval

**`single-tasks.md` (incremental flow):**
- [ ] Confirm the fit: low impact, few files/snippets; **at most 5 TF** — otherwise switch to the full flow
- [ ] Minimal discovery: clarify only blocking doubts (no `spec.md` / `plan.md`)
- [ ] Ask the user for the first User Story ID (even with a single new US) and the Epic reference — see **User Story Identifiers** in `SKILL.md`
- [ ] Write each TF **self-contained** (full template): files, criteria, DoD, Execution Guidance
- [ ] **Brief** US narrative; detail concentrated in the TFs
- [ ] PlantUML diagrams only if needed
- [ ] Present to the user and wait for approval of `single-tasks.md`
