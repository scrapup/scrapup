# Worked Examples

Load when: you need a concrete walk-through of the TDAD cycle.

## 1. Bugfix in plain JavaScript (`node --test`)

`package.json`: `"test": "node --test"`, no coverage or lint script.

**Bug:** `applyDiscount(total, discount)` must treat `discount` as a fraction (the spec says `0.1` = 10%), but it subtracts it as an absolute amount.

**SNAPSHOT** — the runner has no related-tests option, so IMPACT uses import search on the target file:

```bash
$ rg -l "require.*price|from.*price" --glob '*.test.js'
test/price.test.js
test/checkout.test.js
$ node --test test/price.test.js test/checkout.test.js
# pass 7, fail 0   → no pre-existing failures
```

**REPRODUCE** — `test/price.test.js`:

```javascript
test('returns 90 when a 0.1 discount is applied to 100', () => {
  assert.strictEqual(applyDiscount(100, 0.1), 90);
});
```

It fails with `99.9 !== 90` — the wrong output, for the right reason.

**IMPLEMENT** — `lib/price.js`:

```javascript
function applyDiscount(total, discount) {
  return total * (1 - discount); // was: total - discount
}
```

**IMPACT** — same two test files (only `lib/price.js` changed).

**VERIFY** (no `--bail`; `node --test` does not support it anyway):

```bash
$ node --test test/price.test.js test/checkout.test.js
✖ returns 90 when a 10% coupon is applied to 100   (test/checkout.test.js)
  expected 90, got -900
```

A regression: `lib/checkout.js` passes the coupon as a percentage (`coupon.percent`, e.g. `10`).

**CORRECT** — `lib/checkout.js`: `applyDiscount(subtotal, coupon.percent / 100)`. A new file changed, so re-run IMPACT for it (`rg -l "checkout" --glob '*.test.js'` → `test/checkout.test.js`), then VERIFY again: all green.

**COVERAGE** — changed lines vs uncovered lines:

```bash
$ git diff -U0 HEAD -- lib/price.js lib/checkout.js | grep '^@@'
@@ -3 +3 @@            # lib/price.js line 3
@@ -12 +12 @@          # lib/checkout.js line 12
$ node --test --experimental-test-coverage
# file            | line % | uncovered lines
# lib/price.js    | 100.00 |
# lib/checkout.js |  91.30 | 20-21
```

Lines 3 and 12 are covered; lines 20-21 are pre-existing and untouched, so they are out of scope.

**Prove the test can fail** — restore `total - discount`, run `test/price.test.js`: the REPRODUCE test fails. Restore the fix.

**SUBMIT** — full suite `node --test`: no failure outside the SNAPSHOT (none).

```text
tdad_result: SUBMIT_READY
reason: -
impact_method: [rg]
tests_run: test/price.test.js, test/checkout.test.js
pre_existing_failures: none
coverage: 100
iterations: 1
escalations: none
```

## 2. Feature with module propagation (NestJS + Jest)

**Feature:** global rate limiting via a guard registered as `APP_GUARD` in `AppModule`.

**IMPACT** — runner-native:

```bash
$ npx jest --listTests --findRelatedTests src/app.module.ts src/common/guards/rate-limit.guard.ts
src/app.module.spec.ts
src/common/guards/rate-limit.guard.spec.ts
test/app.e2e-spec.ts
test/auth.e2e-spec.ts
test/health.e2e-spec.ts
```

A global guard reaches every e2e test that boots `AppModule`; the runner found them through the import graph.

**VERIFY** (no `--bail`): `test/auth.e2e-spec.ts` fails with 429 — the limit blocks a legitimate login.

**CORRECT** — add `excludedPaths` for `/auth/login` and `/health` to `rate-limit.guard.ts`. The guard file changed again, so re-run IMPACT for it; the set is unchanged. Re-VERIFY with `--bail` while iterating, then a final pass without it: all 5 files green. Run `npm run typecheck` and `npm run lint -- <changed files>` if those scripts exist.

**COVERAGE** — `npm run test:cov -- --collectCoverageFrom=src/common/guards/rate-limit.guard.ts`, then compare the uncovered lines with `git diff -U0` for that file: the new `excludedPaths.includes(request.path)` branch is covered by a new unit test for an excluded and a non-excluded path.

**SUBMIT** — full suite: no failure outside the SNAPSHOT.
