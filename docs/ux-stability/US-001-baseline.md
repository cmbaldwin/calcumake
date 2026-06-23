# US-001 Baseline: Public Funnel + Warning Stability

Date: 2026-03-06
PRD reference: `.milhouse/prd.json` (US-001)

## Scope
Baseline for anonymous user funnel and warning noise across:
- `/`
- `/3d-print-pricing-calculator`
- `/users/sign_up`
- `/blog`
- `/support`

## Funnel Baseline (Desktop + Mobile)

| Route | Funnel role | Primary code path | Desktop baseline evidence | Mobile baseline evidence |
|---|---|---|---|---|
| `/` | Top-of-funnel landing and CTA entry | `config/routes.rb` (`root "pages#landing"), `app/controllers/pages_controller.rb#landing`, `app/views/pages/landing.html.erb` | Landing contains CTA links to sign-up and calculator; nav contains links to sign-up, calculator, blog, support (`.playwright-cli/page-2026-02-16T00-50-03-097Z.yml`) | Collapsed nav shows `Toggle navigation`; CTA buttons remain present in hero (`.playwright-cli/page-2026-02-16T02-05-54-003Z.yml`) |
| `/3d-print-pricing-calculator` | Public calculator experience + conversion CTA to sign-up | `config/routes.rb` (`get "3d-print-pricing-calculator"`), `app/controllers/pages_controller.rb#pricing_calculator`, `app/views/pages/pricing_calculator.html.erb` | Calculator renders saved-calculation selector, storage message, and sign-up link (`.playwright-cli/page-2026-02-16T00-50-28-030Z.yml`) | Calculator remains reachable from mobile nav flow (shared navbar behavior; mobile toggle evidence in `.playwright-cli/page-2026-02-16T02-06-08-610Z.yml`) |
| `/users/sign_up` | Account creation conversion target | Devise registrations route/view, `app/views/devise/registrations/new.html.erb` | Sign-up is linked from landing nav and primary CTAs (same funnel traces above) | Sign-up remains reachable through expanded mobile nav (`.playwright-cli/page-2026-02-16T02-06-08-610Z.yml`) |
| `/blog` | Trust/SEO content funnel | `config/routes.rb` (`get "blog"` scoped by locale), `app/controllers/articles_controller.rb#index`, `app/views/articles/index.html.erb` | Blog linked in global nav and present in desktop funnel traversal traces (`.playwright-cli/page-2026-02-16T00-50-03-097Z.yml`) | Blog remains present in expanded mobile nav list (`.playwright-cli/page-2026-02-16T02-06-08-610Z.yml`) |
| `/support` | Trust + contact/support conversion endpoint | `config/routes.rb` (`get "support"`), `app/controllers/legal_controller.rb#support`, `app/views/legal/support.html.erb` | Support page renders contact card + FAQ (`.playwright-cli/page-2026-02-16T02-05-16-691Z.yml`) | Support remains present in expanded mobile nav list (`.playwright-cli/page-2026-02-16T02-06-08-610Z.yml`) |

## Warning Baseline

### W-001 Storage default warning (calculator first-load)
- Baseline warning text:
  - `Calculation default not found`
- Baseline evidence:
  - `.playwright-cli/console-2026-02-16T00-50-02-683Z.log`
- Route context:
  - Observed during calculator flow (`/3d-print-pricing-calculator`)

### W-002 CSS preload warning on public pages
- Baseline warning text:
  - `The resource .../assets/application-...css was preloaded using link preload but not used within a few seconds from the window's load event...`
- Baseline evidence:
  - `.playwright-cli/console-2026-02-16T00-50-02-683Z.log` (`/3d-print-pricing-calculator`, `/users/sign_up`)
  - `.playwright-cli/console-2026-02-16T02-00-55-455Z.log` (`/blog`, `/support`)
  - `.playwright-cli/console-2026-02-16T02-05-17-832Z.log` (`/blog`, `/support`)
- Current preload-related implementation to track:
  - `app/views/layouts/application.html.erb` includes async stylesheet preload usage (`<link rel="preload" ... as="style" onload=...>`) and app stylesheet tag.

## Expected Post-Fix Target (for subsequent stories)

- `/`, `/3d-print-pricing-calculator`, `/users/sign_up`, `/blog`, `/support`:
  - No known baseline warning signatures in browser console during normal anonymous flow.
- Calculator first visit with empty storage:
  - No warning-level log for expected empty/default state.
  - Warning/error logs remain only for malformed data or true runtime failures.
- CSS loading:
  - No benign preload-not-used warnings for `application.css` on targeted funnel pages.

## Reproducible Testing Approach

1. Run app in test-like local mode (`bin/dev` or equivalent local server).
2. Capture desktop flow for all five routes:
   - Visit in order: `/` -> `/3d-print-pricing-calculator` -> `/users/sign_up` -> `/blog` -> `/support`.
   - Save DOM snapshots (Playwright page dump) and console logs.
3. Capture mobile flow with viewport `375x667`:
   - Repeat same route order.
   - Explicitly open navbar (`Toggle navigation`) and verify links to calculator/sign-up/blog/support.
4. For warning assertions:
   - Record warning count and warning text per route.
   - Track two signatures above as baseline comparators.
5. Regression gate for follow-up stories:
   - Compare warning signatures/route coverage against this document.
   - Treat new warning signatures in anonymous funnel as regressions unless intentionally introduced.

## Notes for Subsequent Stories
- This file is the baseline reference for US-002 through US-009 warning/funnel checks.
- Existing system/Jest tests already provide supporting coverage patterns for mobile responsiveness and storage behavior:
  - `test/system/landing_page_test.rb`
  - `test/system/pricing_calculator_test.rb`
  - `test/javascript/controllers/mixins/storage_mixin.test.js`
