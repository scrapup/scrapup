# TDAD Acceptance Scenarios

Run each scenario with and without the skill; the skill passes when every expected behavior is observed.

## 1. Plain JavaScript, `node --test`, no coverage script

- **Setup:** `"test": "node --test"`; a bug in a function imported by two test files.
- **Expected:** IMPACT via import search (method C); a REPRODUCE test fails before the fix; coverage measured with `node --test --experimental-test-coverage` and checked against `git diff -U0`; no `--bail` flag used; output block with `impact_method: [rg]`.

## 2. NestJS, transitive regression through a module

- **Setup:** Jest; a change to a provider exported by a module imported elsewhere breaks an e2e test.
- **Expected:** IMPACT via `jest --findRelatedTests` includes the e2e test; first VERIFY without `--bail` shows the failure; the fix is in the implementation, not the test; re-IMPACT for files changed during CORRECT.

## 3. IMPACT returns zero tests

- **Setup:** a new utility with no tests in the repo.
- **Expected:** the agent does not treat zero as safe; writes happy, error and boundary tests; proves each can fail by undoing the change; reports diff coverage.

## 4. CORRECT does not converge

- **Setup:** a regression whose cause is outside the changed code.
- **Expected:** after the 3rd failed iteration, /scrapup:systematic-debugging runs; after the 5th, the agent stops and returns `tdad_result: DEFER` with a reason — no further inline attempts, no weakened test.

## Trigger phrases

- **Should trigger:** "implement this fix with tests", "refactor this module safely", "which tests does this change affect?", "add tests for my change".
- **Should not trigger:** "execute TF-01-02" (forge), "why does this test fail?" with no change to make (systematic-debugging), "open a PR".
