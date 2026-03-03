# UX Stability Program — Priority 1 Design

**Date:** 2026-03-02
**PRD:** `.milhouse/prd.json` v2026.02.16
**Scope:** Priority 1 stories (US-001 through US-005, US-010)

## Phase 1: PR Cleanup (Green Baseline)

Update all gems directly on master, close dependabot PRs. Merge feature PR #133 after fixing its CI failures.

| PR | Action |
|----|--------|
| #117 aws-sdk-s3, #119 turbo-rails, #122 thruster, #123 stripe, #128 bootsnap, #129 view_component, #132 selenium-webdriver, #134 solid_queue | Close after `bundle update` |
| #135 actions/upload-artifact 4→7 | Merge (GitHub Actions) |
| #131 devise 4.9→5.0 | Review changelog, update, test carefully |
| #120 lexxy 0.1→0.7 | Update Gemfile constraint to `~> 0.7.0.beta` |
| #133 PrinterProfile fix | Fix lint+test failures, merge |

Gate: `bin/ci` passes on master.

## Phase 2: Priority 1 Stories

All stories follow test-first development per US-010.

### US-001: Baseline Documentation

Capture current state of warnings and funnel paths. Document in implementation notes as context for subsequent stories. No code changes.

### US-002: Cookie Consent Not Blocking Sign-up

**Finding:** Cookie banner is `position-fixed bottom-0` z-index 9999. Sign-up form is centered. No obvious blocking detected in static analysis.

**Approach:** Write system test verifying sign-up submit clickable with banner present. If test passes, story satisfied. If not, fix via `pointer-events` or z-index adjustment.

**Files:** `test/system/authentication_test.rb`, potentially `app/views/shared/_cookie_consent.html.erb`

### US-003: Sign-up Validation Feedback

**Finding:** Error display uses `#error_explanation` div rendered by Devise partial.

**Approach:** Write system test for invalid email/password/confirmation flow. Verify error messages are visible. Improve styling if needed.

**Files:** `test/system/authentication_test.rb`, potentially `app/views/devise/shared/_error_messages.html.erb`

### US-004: Mobile Nav CTA Reachability

**Finding:** CTAs (Sign Up, Calculate Now) collapse into hamburger menu on mobile (<992px). No tests cover mobile toggle behavior.

**Approach:** Write failing mobile system test at 375x667 verifying nav toggle and CTA access. Fix by ensuring mobile CTA visibility — either always-visible button bar (`d-lg-none`) or verify hamburger toggle + CTA path works reliably.

**Files:** `test/system/landing_page_test.rb`, `app/views/shared/_navbar.html.erb`, `app/assets/stylesheets/application.css`

### US-005: Calculator Default Initialization

**Finding:** `storage_mixin.js` line 103 fires `console.warn("Calculation default not found")` on every first visit with empty localStorage. Expected behavior, not an error.

**Approach:** Write failing Jest test for empty localStorage initialization. Change `loadCalculation()` to treat missing 'default' as normal first-visit state (return false silently, no warning).

**Files:** `test/javascript/controllers/mixins/storage_mixin.test.js`, `app/javascript/controllers/mixins/storage_mixin.js`

### US-010: Quality Gates

Enforced as a cross-cutting concern:
- Every story gets a failing test before implementation
- `npm test` and `bin/rails test` run during development
- `bin/ci` passes as final gate

## Testing Strategy

- **Jest:** US-005 (storage mixin warning cleanup)
- **System tests (Capybara):** US-002, US-003, US-004
- **All assertions use `I18n.t()`** per CLAUDE.md
- **No hardcoded English text** in selectors
- **`bin/ci`** as final pre-merge gate
