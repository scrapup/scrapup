# PlantUML and C4 syntax reference

Summary per diagram type. Full documentation: [plantuml.com](https://plantuml.com/) and [C4-PlantUML](https://plantuml-stdlib.github.io/C4-PlantUML/).

---

## Sequence

- **Participants:** `participant "Name" as alias`, `actor Name`
- **Messages:** `A -> B: text` (solid), `A --> B: text` (dashed)
- **Blocks:** `alt condition` / `else other` / `end`; `opt condition` / `end`; `loop` / `end`
- **Activation:** `activate A`, `deactivate A` (after a message)
- **Notes:** `note left of A: text`, `note over A, B: text`
- **Numbering:** `autonumber`

Doc: [plantuml.com/sequence-diagram](https://plantuml.com/sequence-diagram)

---

## Use case

- **Use case:** `(Name)` or `usecase "Name" as alias`
- **Actor:** `:Name:` or `actor Name`
- **Association:** `actor --> (use case)`
- **Include:** `(A) .> (B) : <<include>>` — A always includes B
- **Extend:** `(B) .> (A) : <<extend>>` — B optionally extends A
- **Generalization:** `(Child) --|> (Parent)`

Doc: [plantuml.com/use-case-diagram](https://plantuml.com/use-case-diagram)

---

## Class

- **Class:** `class Name { }` with fields/methods `+` `-` `#`; `abstract class`, `interface`
- **Relationships:** `<|--` inheritance, `..|>` realization, `*--` composition, `o--` aggregation, `-->` association, `..>` dependency
- **Cardinality:** `"1" *-- "n" Class : contains`
- **Package:** `package name { }`

Doc: [plantuml.com/class-diagram](https://plantuml.com/class-diagram)

---

## Object

- **Object:** `object name` or `object "Name" as alias`
- **Fields:** `object : field = value`
- **Relationships:** same symbols as class diagrams (composition, aggregation, etc.)

Doc: [plantuml.com/object-diagram](https://plantuml.com/object-diagram)

---

## Activity (beta syntax)

- **Action:** `:text;`
- **Flow:** `start`, `stop` or `end`
- **Conditional:** `if (cond) then (yes)` / `else (no)` / `endif`
- **Repeat:** `repeat` / `repeat while (cond) is (yes) not (no)`
- **While:** `while (cond)` / `endwhile`
- **Parallel:** `fork` / `fork again` / `end fork` or `end merge`
- **Partition:** `partition "Name" { }`
- **Swimlane:** `|name|` before the action

Doc: [plantuml.com/activity-diagram-beta](https://plantuml.com/activity-diagram-beta)

---

## Component (UML)

- **Component:** `[Name]` or `component Name`
- **Interface:** `() Name` or `interface Name`
- **Use:** `..>`; association `--`

Doc: [plantuml.com/component-diagram](https://plantuml.com/component-diagram)

---

## Deployment (UML)

- **Node:** `node Name`, `cloud Name`, `database Name`, `artifact Name`
- **Nesting:** `node Name { artifact X }`
- **Connections:** `--`, `-->`, `..>`

Doc: [plantuml.com/deployment-diagram](https://plantuml.com/deployment-diagram)

---

## State

- **Start/end:** `[*]`
- **State:** `state Name` or `state Name { }` (composite)
- **Transition:** `State1 --> State2 : event`
- **History:** `[H]` or `[H*]` (deep history)

Doc: [plantuml.com/state-diagram](https://plantuml.com/state-diagram)

---

## Timing

- **Participant:** `concise "Name" as C`, `robust "Name" as R`, `binary "Name" as B`, `clock "Name" as Clk with period N`
- **States:** `@0 C is State`, `@100 C is OtherState`
- **Relative:** `@+50 C is State`

Doc: [plantuml.com/timing-diagram](https://plantuml.com/timing-diagram)

---

## C4-PlantUML

### Include

```plantuml
!include <C4/C4_Context>   ' or C4_Container, C4_Component, C4_Deployment, C4_Dynamic, C4_Sequence
```

Only when the stdlib is unavailable, use a pinned release tag (never `master`): `!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/v2.14.0/C4_Container.puml`

### Context / Landscape

- `Person(alias, "Label", "?desc")`, `Person_Ext(...)`
- `System(alias, "Label", "?desc")`, `System_Ext(...)`, `SystemDb`, `SystemQueue`
- `Boundary(alias, "Label") { }`, `Enterprise_Boundary`, `System_Boundary`
- `Rel(from, to, "label", "?techn")`

### Container

- `Container(alias, "Label", "?techn", "?desc")`, `ContainerDb`, `ContainerQueue`, `Container_Ext`
- `Container_Boundary(alias, "Label") { }`
- `Rel`, `Rel_R`, `Rel_L`, `Rel_U`, `Rel_D`

### Component

- `Component(alias, "Label", "?techn", "?desc")`, `ComponentDb`, `ComponentQueue`
- `Container_Boundary` to group components
- `Rel` between components

### Deployment

- `Deployment_Node(alias, "Label", "?type", "?desc")` or `Node(...)`
- Containers nested inside nodes

### Layout and legend

- `SHOW_LEGEND()` (always in C4 diagrams) or `LAYOUT_WITH_LEGEND()`
- `LAYOUT_LEFT_RIGHT()`, `LAYOUT_TOP_DOWN()`
- `HIDE_STEREOTYPE()` — hide stereotypes

Doc: [plantuml-stdlib.github.io/C4-PlantUML](https://plantuml-stdlib.github.io/C4-PlantUML/)
