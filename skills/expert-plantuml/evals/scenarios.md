# expert-plantuml — evaluation scenarios

Run each scenario with and without the skill loaded (baseline) and compare against the expected outcome.

## Trigger tests

| Prompt | Should activate |
|--------|-----------------|
| "Create a C4 component diagram for the order service" | Yes |
| "Draw a sequence diagram for the login flow with success and failure" | Yes |
| "Fix this PlantUML, it says Some diagram description contains errors" | Yes |
| "Write the spec and plan for the checkout feature" | No — /scrapup:blueprint |
| "Render this diagram to PNG" | No — out of scope |

## Scenarios

### S1 — C4 L3 from a plan

- **Input:** a `plan.md` excerpt listing a NestJS controller, a use case, a Prisma repository, PostgreSQL and an external payment API.
- **Expected:** fenced `plantuml` block; `!include <C4/C4_Component>`; `title`; one `Component` per listed element and nothing else; `System_Ext` for the payment API; only `Rel(...)` relationships; `SHOW_LEGEND()`.
- **Fail if:** any component or technology not present in the plan appears, or manual `-->` arrows are used.

### S2 — Sequence with success and failure

- **Input:** "Client calls POST /orders; the API persists the order; on DB failure it returns 503."
- **Expected:** `alt Success` / `else Database failure` / `end`; `title`; participants declared with aliases.
- **Fail if:** the block is closed with `endif`.

### S3 — Fix a broken C4 diagram

- **Input:** a C4 container diagram that uses `!include <C4/C4_Component>` and a `Rel` pointing to an undeclared alias.
- **Expected:** include corrected to `C4_Container`; the `Rel` fixed or the missing element flagged as `TBD`; the fix explained per line; validation status declared ("checked with `plantuml -checkonly`" or "syntax not validated locally").

### S4 — Missing information

- **Input:** "Draw the container diagram of our platform" with no spec, plan or code in context.
- **Expected:** the skill asks for the containers/technologies before drawing (no context at all). When context exists but a single element is missing, it draws that element with a `TBD` label and lists the TBDs after the diagram.
- **Fail if:** containers or technologies are invented and presented as fact.

### S5 — Output as a file

- **Input:** "Save the order state machine diagram as a file" with the order states listed in context.
- **Expected:** a state diagram written to `docs/diagrams/<kebab-name>.puml` (or the repository's existing diagrams folder); `title`; validation status reported.
- **Fail if:** delivered only inline, or an existing `.puml` is overwritten without asking.

### S6 — Type tie-breaker

- **Input:** "Show the deployment of the API" with the infrastructure described in context.
- **Expected:** C4 Deployment (`!include <C4/C4_Deployment>`, `Deployment_Node`), `SHOW_LEGEND()`.
- **Fail if:** UML `node`/`artifact` notation is used without an explicit UML request.
