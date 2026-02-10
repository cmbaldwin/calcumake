# Testing Automation Execution Plan

## Goal
Harden CI around a user-first testing strategy:

1. Stable baseline checks (security, lint, unit/integration tests)
2. Fast browser smoke validation of core user journeys on every PR
3. Coverage gates for Ruby and JavaScript
4. Full browser E2E regression on nightly schedule

## CI Topology

### PR + Push (`.github/workflows/ci.yml`)
- `scan_ruby`: Brakeman (latest enforced via `bin/brakeman`)
- `scan_js`: importmap audit
- `lint`: RuboCop
- `test_js`: Jest + coverage artifact
- `test_core`: Rails minitest with Ruby coverage gate
- `system_smoke`: user-first browser smoke tests only

### Nightly (`.github/workflows/e2e-nightly.yml`)
- Full system browser suite (`test:system`)
- Manual trigger supported (`workflow_dispatch`)

## User-First Browser Journeys (Smoke Suite)
Smoke tests live in `test/system/smoke/` and must stay:
- deterministic
- fast
- skip-free

Current smoke coverage:
- authenticated user creates a print pricing
- onboarding happy path (printer + filament steps)
- anonymous public calculator cost computation

Smoke entrypoint:
- `bin/test-smoke`
- enforced policy: fails if any smoke test is skipped

## Coverage Gates

### Ruby
- Enabled by `COVERAGE=true` in `test_core`
- Tool: SimpleCov (`test/test_helper.rb`)
- Minimum line coverage: `60%` (`MINIMUM_COVERAGE=60`)
- Artifact: `coverage/` uploaded as `ruby-coverage`

### JavaScript
- Tool: Jest
- Coverage source: `app/javascript/controllers/mixins/*.js`
- Global thresholds:
  - statements: `50%`
  - lines: `50%`
  - functions: `65%`
  - branches: `40%`

## Flaky Test Policy
- No skips allowed in smoke suite.
- If a browser test flakes:
  - move it out of smoke to regular `test/system/*`
  - open follow-up to stabilize selectors/waits
  - keep nightly full E2E coverage for that flow

## Local Commands
- Full local CI (fast path): `bin/ci`
- Include full browser regression locally: `FULL_E2E=1 bin/ci`
- Smoke only: `bin/test-smoke`
- Nightly-equivalent full browser suite: `bin/test-system-full`
