# Test Authoring

Load when: IMPACT returned zero tests, or new/changed behavior needs coverage (COVERAGE step of `SKILL.md`).

Keep the rules minimal: verbose red-green-refactor procedure is what increased regressions in the TDAD study. What matters is a test that is written, passing, able to fail, and covering the change before the commit.

## Before or after the implementation

| Scenario | Order |
|---|---|
| Bugfix | **Before** — the REPRODUCE step: a failing test that the fix turns green. |
| New feature with clear observable behavior (new endpoint, documented calculation rule) | **Before** — the specification test, then implement until it passes. |
| Refactor without behavior change | **After**, only if current coverage is insufficient; existing tests are the contract. |
| Complex side effects (integration, time, I/O) | Minimal skeleton first, then a test on the observable contract, not on the implementation. |
| Glue or configuration without own logic | **After**, as an integration or e2e test; do not invent unit tests for a chain of calls. |

## Scope per test type

| Type | Required when | Check |
|---|---|---|
| Unit | Always, if the project has unit tests | Every new or changed function/method has a matching test |
| E2E | Endpoints or flows added or changed | Every new/changed route has an e2e test |
| Integration | Interactions between modules change in this patch | Every new/changed integration has a test |

## Structure: Arrange, Act, Assert

```javascript
test('returns the subtotal minus the discount when discount > 0', () => {
  const items = [{ price: 100, quantity: 2 }];

  const total = calculateTotal(items, 0.1);

  assert.strictEqual(total, 180);
});
```

- **Arrange:** data, dependencies, mocks. If it grows larger than act + assert, extract a factory or fixture.
- **Act:** one call to the subject. Two acts in one test are two tests.
- **Assert:** the observable contract. Prefer exact values (`toBe`, `toEqual`, `strictEqual`) over `toBeTruthy`/`toBeDefined` on objects.

## Naming

- `test('<expected result> when <condition>')` / `it(...)`; `describe('<unit or behavior>')`.
- Match the language already used by the project's tests.
- Forbidden: `should work`, `test 1`, `case 1` — a name that does not state the contract means the test does not either.

## One test, one behavior

Each test covers one observable path: happy, error and boundary are three tests. Use `it.each`/table tests only for the same act with varying inputs and outputs, never with per-case logic in the body.

## Questions for every new unit

- What if the input is `null`, `undefined`, empty, or the wrong type?
- What if an injected dependency throws, returns `null`, or times out?
- What about boundary values (zero, negative, maximum, empty string)?
- Does every branch and guard clause have at least one test that reaches it?

## Anti-patterns

| Anti-pattern | Why |
|---|---|
| Testing implementation (spying on private methods, asserting internal call order) | Breaks on every legitimate refactor; test the contract. |
| Mocks on mocks until no real code runs | The test is at the wrong level; move it to integration. |
| Weak assertion (`toBeTruthy` on a complex object) | Passes with a wrong value. |
| Large setup repeated in every test | Use `beforeEach` only when the setup is identical; otherwise an explicit factory. |
| A test that exists only to raise line coverage | If it cannot fail on a real regression, it is not a test. |
| Tests depending on each other's order | Execution order may change. |
| Real time (`setTimeout`, `new Date()`) in assertions | Use fake timers or an injected clock; otherwise flaky. |
| Shared mutable state between tests (singletons, module variables, a reused NestJS `TestingModule`) | Recreate fixtures per `describe`; reset mocks in `beforeEach`. |
| Updating snapshots to make a failing test pass | Treat as weakening a test unless the patch states why the new snapshot is the intended contract. |

## Prove the test can fail

After a new test passes, undo the fix or the new branch (keep the change safe with `git stash` if needed), run the test, confirm it fails, and restore the code. If it still passes, it does not measure the change: fix the test before counting it.

## Relation to the cycle

New tests go back to VERIFY together with the impacted tests. If a new test fails, correct the implementation, not the test — unless the test measures something other than the intended contract.
