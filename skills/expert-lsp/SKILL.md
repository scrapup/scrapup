---
name: expert-lsp
description: "Defines the integration rules and canonical recipes (R1-R4) for semantic navigation and symbol-level editing of JavaScript/TypeScript code through a language server (Serena MCP). Use when the user says \"find who calls this\", \"which tests does this symbol affect\", \"rename this symbol across the codebase\", \"show the structure of this file\", or when locating symbols, mapping references/impact, editing by symbol (replace/insert/rename), or reading language server diagnostics instead of grep or whole-file reads. Do NOT use for non-code files, non-JS/TS repos without a language server, or literal text search."
user-invocable: true
---

# Expert LSP — Semantic Code Navigation and Editing Rules

## Goal

Semantic code analysis (symbols, references, call hierarchy, diagnostics) and symbol-level editing via a language server, instead of `grep` or whole-file reads. Primary focus: **JavaScript and TypeScript**.

## When to use

Trigger **before** falling back to `grep`/`rg` or whole-file reads whenever the task involves understanding or changing JS/TS code:

- Locate the definition/declaration of a function, class, method or type.
- Find **who uses/calls** a symbol — impact, safe refactoring.
- Find the implementations of an interface/abstraction.
- Read only the **skeleton** of a file before diving in.
- Edit at symbol level without rewriting the file (replace/insert/rename).
- Get language server diagnostics for a file.

Do not use for: non-code files (markdown, config JSON), repositories without a supported language server, or when a literal text search is enough.

## Mandatory precondition: server and active project

The Serena MCP server is a **user-configured prerequisite**; it is not bundled with this plugin. The tool prefix depends on the installed server name; discover it from the available tool list. The tool names in the recipes below (`find_symbol`, `find_referencing_symbols`, …) are normative; only the prefix varies.

Semantic operations require an **active project** on the server. Ensure it before any tool:

1. With `--project-from-cwd`, the server auto-detects the project from the cwd's `.git`/`.serena/project.yml`.
2. If no project is active, or the wrong one is, activate it by the repo path/name (project activation).
3. On a repo new to the backend, the first access indexes through the language server (initial latency); later operations are fast.
4. When in doubt, confirm the active project/language (configuration inspection).

## Canonical recipes (JS/TS)

Reusable procedures that other skills **reference by ID** instead of reimplementing.

### R1 — Locate / understand code (navigate by symbol)

1. `get_symbols_overview` on the file → skeleton (top-level symbols), without reading the whole file.
2. `find_symbol` by name/name-path → go to the target symbol.
3. `find_declaration` → definition (go-to-definition) when the starting point is a usage.
4. `find_implementations` → when the target is an interface/abstraction and you need the concrete implementations.

### R2 — Find references / impact analysis (who uses it)

For each **changed public symbol** (exported function, class, method, type):

1. `find_referencing_symbols` on the symbol → real referencers (resolves re-exports/barrel files, ignores homonyms).
2. Chain `find_referencing_symbols` on the referencers to capture the **transitive** ones. Stop condition: chain until **no new referencers appear outside the already visited set**, capped at **3 hops**.
3. Filter the referencing files by the project's test globs (`*.spec.ts`, `*.e2e-spec.ts`, `*.test.js`, …) when the goal is the set of impacted tests.

**Output:** a deduplicated list of **impacted test file paths** (each path once, even when reached through multiple paths).

Advantage over `rg`/grep by name: removes false positives (homonyms) and false negatives (re-exports/barrels → missed transitive references).

### R3 — Edit at symbol level

1. `replace_symbol_body` → replace a symbol's body without rewriting the file.
2. `insert_after_symbol` / `insert_before_symbol` → insert relative to the definition.
3. `rename_symbol` → rename across the codebase (language server refactoring), never a textual find-and-replace.

### R4 — Post-edit diagnostics

`get_diagnostics_for_file` on the changed file → language server errors/warnings (e.g., a type break) right after the change.

## Ecosystem integration

Consumers reference R1-R4 by ID; each consumer owns its own policy for when to apply them. R2 implements method B (LSP) of TDAD IMPACT; /scrapup:test-driven-agentic-development owns the method order.

## MCP unavailability and fallback

Distinguish **three cases** — the handling differs:

**Case 0 — Serena tools absent from the tool list:** the server is not configured for this user. State it once and fall back to `rg`/Read.

**Case A — automatic fallback (no question):** the language is not supported by the language server, or the repo legitimately has no applicable server. LSP does not apply here. State it and fall back to `rg`/Read.

**Case B — Serena tools present but failing (should work):** connection error, timeout, server down, or the project does not activate in a JS/TS repo where LSP should operate. **Do not silently continue without the server.** Before any fallback:

1. Report the factual symptom (which tool, which error).
2. **Ask the user** which action to take, offering options:
   - reconnect/restart the server (e.g., `/reload-plugins` or re-activate the project);
   - continue this task with the `rg`/Read fallback (accepted degradation, with the precision loss stated);
   - abort the task.
3. Proceed only **after the answer**. The choice holds for the current task; re-evaluate if the symptom reappears.

Never treat Case B as Case A: falling back to `rg` on your own when the server is only temporarily unavailable hides an environment failure and degrades precision without the user knowing.

## Mandatory rules

1. Activate the correct project before any semantic tool.
2. Prefer semantic tools over `grep`/whole-file reads when the target is a JS/TS symbol.
3. Rename via `rename_symbol`, not a textual find-and-replace.
4. Edit via `replace_symbol_body`/`insert_*` instead of rewriting the file.
5. Fallback per the "MCP unavailability and fallback" section: Cases 0 and A are automatic; **Case B requires asking the user before continuing without the server**. Never fail — or degrade — silently.
6. Do not use Serena's `execute_shell_command` to run tests/builds; that belongs to the native shell tools and the caller's test gate (e.g., /scrapup:forge).

## Anti-patterns

- Running `rg "import.*Service"` for impact when `find_referencing_symbols` is available.
- Reading a whole file just to locate a function (`get_symbols_overview` + `find_symbol` suffice).
- Editing via fragile string matching where `replace_symbol_body` makes the surgical edit.
- Running semantic tools without an active project (empty/wrong results).
