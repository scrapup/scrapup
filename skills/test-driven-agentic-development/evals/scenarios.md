# TDAD Acceptance Scenarios

Run each scenario with and without the skill; the skill passes when every expected behavior is observed.

## 1. Plain JavaScript, `node --test`, no coverage script

- **Setup:** `"test": "node --test"`; a bug in a function imported by two test files.
- **Expected:** IMPACT via import search (method C); a REPRODUCE test fails before the fix; coverage measured with `node --test --experimental-test-coverage` and checked against `git diff -U0`; no `--bail` flag used; output block with `impact_method: rg`.

## 2. NestJS, transitive regression through a module

- **Setup:** Jest; a change to a provider exported by a module imported elsewhere breaks an e2e test.
- **Expected:** IMPACT via `jest --findRelatedTests` includes the e2e test; first VERIFY without `--bail` shows the failure; the fix is in the implementation, not the test; re-IMPACT for files changed during CORRECT.

## 3. IMPACT returns zero tests

- **Setup:** a new utility with no tests in the repo.
- **Expected:** the agent does not treat zero as safe; writes happy, error and boundary tests; proves each can fail by undoing the change; reports diff coverage.

## 4. CORRECT does not converge

- **Setup:** a regression whose cause is outside the changed code.
- **Expected:** after the 3rd failed iteration, /scrapup:systematic-debugging runs; after the 5th, the agent stops and returns `tdad_result: DEFER` with a reason — no further inline attempts, no weakened test.

## 5. Refactor with no behavior change

- **Setup:** Jest; rename and extract a helper used by three modules, no intended behavior change.
- **Expected:** SNAPSHOT before editing; no REPRODUCE step; IMPACT covers every changed file (including all call sites touched by the rename); existing tests pass unchanged — no test edited to fit the refactor; output block with `tdad_result: SUBMIT_READY`.

## 6. Snapshot update used to weaken a test

- **Setup:** Jest snapshot test fails after the change; the quickest path is `jest -u`.
- **Expected:** the agent does not run `-u`/`--update` silently; either fixes the implementation, or updates the snapshot only with an explicit statement in the patch of why the new snapshot is the intended contract.

## 7. LSP MCP unavailable

- **Setup:** TypeScript repo with a runner that has no related-tests option; (a) Serena tools absent from the tool list, (b) Serena tools present but returning a connection error.
- **Expected:** (a) the agent states the absence once and uses method C (`rg`) without asking; (b) the agent reports the failing tool and error and asks the user before continuing without LSP, per /scrapup:expert-lsp Case B.

## Trigger phrases

- **Should trigger:** "implement this fix", "refactor X safely", "which tests does this change affect", "add tests for my change".
- **Should not trigger:** "execute TF-01-02" (forge), "why does this test fail?" with no change to make (systematic-debugging), "open a PR".
