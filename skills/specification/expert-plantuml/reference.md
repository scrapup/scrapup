# Referência de sintaxe PlantUML e C4

Resumo por tipo de diagrama. Documentação completa: [plantuml.com](https://plantuml.com/) e [C4-PlantUML](https://plantuml-stdlib.github.io/C4-PlantUML/).

---

## Sequência

- **Participantes:** `participant "Nome" as alias`, `actor Nome`
- **Mensagens:** `A -> B: texto` (sólido), `A --> B: texto` (tracejado)
- **Blocos:** `alt condição` / `else` / `endif`, `opt condição` / `end`, `loop` / `end`
- **Ativação:** `activate A`, `deactivate A` (após mensagem)
- **Notas:** `note left of A: texto`, `note over A, B: texto`
- **Numeração:** `autonumber`

Doc: [plantuml.com/sequence-diagram](https://plantuml.com/sequence-diagram)

---

## Caso de uso

- **Use case:** `(Nome)` ou `usecase "Nome" as alias`
- **Ator:** `:Nome:` ou `actor Nome`
- **Associação:** `ator --> (usecase)`
- **Include:** `(A) .> (B) : include`
- **Extends:** `(A) <|-- (B)` ou `(B) <|-- (A)` para extends

Doc: [plantuml.com/use-case-diagram](https://plantuml.com/use-case-diagram)

---

## Classe

- **Classe:** `class Nome { }` com campos/métodos `+` `-` `#`; `abstract class`, `interface`
- **Relações:** `<|--` extensão, `*--` composição, `o--` agregação, `-->` dependência, `..>` realização
- **Cardinalidade:** `"1" *-- "n" Classe : contém`
- **Package:** `package nome { }`

Doc: [plantuml.com/class-diagram](https://plantuml.com/class-diagram)

---

## Objeto

- **Objeto:** `object nome` ou `object "Nome" as alias`
- **Campos:** `objeto : campo = valor`
- **Relações:** mesmos símbolos do class (composição, agregação, etc.)

Doc: [plantuml.com/object-diagram](https://plantuml.com/object-diagram)

---

## Atividade (beta)

- **Ação:** `:texto;`
- **Fluxo:** `start`, `stop` ou `end`
- **Condicional:** `if (cond) then (sim)` / `else (não)` / `endif`
- **Repetição:** `repeat` / `repeat while (cond) is (sim) not (não)`
- **While:** `while (cond)` / `endwhile`
- **Paralelo:** `fork` / `fork again` / `end fork` ou `end merge`
- **Partição:** `partition "Nome" { }`
- **Swimlane:** `|nome|` antes da ação

Doc: [plantuml.com/activity-diagram-beta](https://plantuml.com/activity-diagram-beta)

---

## Componente (UML)

- **Componente:** `[Nome]` ou `component Nome`
- **Interface:** `() Nome` ou `interface Nome`
- **Uso:** `..>`, associação `--`

Doc: [plantuml.com/component-diagram](https://plantuml.com/component-diagram)

---

## Deployment

- **Nó:** `node Nome`, `cloud Nome`, `database Nome`, `artifact Nome`
- **Aninhamento:** `node Nome { artifact X }`
- **Conexões:** `--`, `-->`, `..>`

Doc: [plantuml.com/deployment-diagram](https://plantuml.com/deployment-diagram)

---

## Estado

- **Início/fim:** `[*]`
- **Estado:** `state Nome` ou `state Nome { }` (composto)
- **Transição:** `Estado1 --> Estado2 : evento`
- **História:** `[H]` ou `[H*]` (deep history)

Doc: [plantuml.com/state-diagram](https://plantuml.com/state-diagram)

---

## Timing

- **Participante:** `concise "Nome" as C`, `robust "Nome" as R`, `binary "Nome" as B`, `clock "Nome" as Clk with period N`
- **Estados:** `@0 C is Estado`, `@100 C is OutroEstado`
- **Relativo:** `@+50 C is Estado`

Doc: [plantuml.com/timing-diagram](https://plantuml.com/timing-diagram)

---

## C4-PlantUML

### Inclusão

```plantuml
!include <C4/C4_Context>   ' ou C4_Container, C4_Component, C4_Deployment, C4_Dynamic, C4_Sequence
```

Ou via URL: `!include https://raw.githubusercontent.com/plantuml-stdlib/C4-PlantUML/master/C4_Container.puml`

### Context / Landscape

- `Person(alias, "Label", "?desc")`, `Person_Ext(...)`
- `System(alias, "Label", "?desc")`, `System_Ext(...)`, `SystemDb`, `SystemQueue`
- `Boundary(alias, "Label") { }`, `Enterprise_Boundary`, `System_Boundary`
- `Rel(from, to, "label", "?techn")`

### Container

- `Container(alias, "Label", "?techn", "?desc")`, `ContainerDb`, `ContainerQueue`
- `Container_Boundary(alias, "Label") { }`
- `Rel`, `Rel_R`, `Rel_L`, `Rel_U`, `Rel_D`

### Component

- `Component(alias, "Label", "?techn", "?desc")`, `ComponentDb`, `ComponentQueue`
- `Container_Boundary` para agrupar componentes
- `Rel` entre componentes

### Deployment

- `Deployment_Node(alias, "Label", "?type", "?desc")` ou `Node(...)`
- Containers dentro de nós

### Layout e legenda

- `LAYOUT_WITH_LEGEND()` ou `SHOW_LEGEND()` — legenda com elementos e relações
- `HIDE_STEREOTYPE()` — esconder estereótipos

Doc: [plantuml-stdlib.github.io/C4-PlantUML](https://plantuml-stdlib.github.io/C4-PlantUML/)
