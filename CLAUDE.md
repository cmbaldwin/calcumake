# CLAUDE.md

## Application Overview
**CalcuMake** - Rails 8.1.1 3D print project management with invoicing, cost tracking, and pricing calculations. Multi-currency support, Devise authentication with OAuth and email confirmation.

**Copyright**: © 2025 株式会社モアブ (MOAB Co., Ltd.)

## Development Commands
- `bin/setup` - Complete setup
- `bin/dev` - Development server
- `bin/ci` - Run all CI checks locally (security, linting, tests) - **RUN BEFORE PUSHING**
- `bin/rails test` - Run Rails tests (1,075 tests in ~3.5s)
- `npm test` - Run JavaScript tests
- `bin/rubocop` - Style checking
- `bin/brakeman` - Security scan
- `bin/sync-translations` - Sync and auto-translate missing keys (uses OpenRouter API if key available)
- `bin/translate-locales` - Direct automated translation via OpenRouter API (requires OPENROUTER_TRANSLATION_KEY)
- `bin/force-retranslate` - Clear cache for English placeholder values to force re-translation
- `bin/check-translations` - Scan code for missing translation keys and hardcoded strings

## Git & PR Merge Policy
**IMPORTANT**: When merging PRs, use `gh pr merge <number> --merge` to preserve commit history and keep branch references. Do NOT use `--squash` or `--delete-branch` unless explicitly requested. This maintains valuable context for understanding how features were built and makes it easier to reference past work.

## Core Architecture

### Models
- **User**: Currency/energy defaults, company info, logo, confirmable, omniauthable
- **Client**: Customer management (searchable via Ransack)
- **Printer**: Power consumption, payoff tracking
- **PrintPricing**: Job calculations (1-10 plates), linked to clients
- **Plate**: Individual build plates with time/material specs
- **Invoice**: Auto-numbered, status tracking, client integration
- **InvoiceLineItem**: Categorized cost breakdowns

### Public Features
- **Advanced Pricing Calculator** (`/3d-print-pricing-calculator`) - No-signup SPA for lead generation
  - Multi-plate calculations (up to 10 plates)
  - Multiple filaments per plate (up to 16)
  - Real-time cost breakdowns (filament, electricity, labor, machine, other)
  - PDF export with professional formatting (jsPDF + html2canvas)
  - CSV export for spreadsheet compatibility
  - Auto-save to localStorage every 10 seconds
  - Strategic CTAs to drive account creation

### Multi-Plate System
Each PrintPricing contains 1-10 plates. Use `build` → `save!` pattern:

```ruby
pricing = user.print_pricings.build(job_name: "Job", printer: printer)
pricing.plates.build(printing_time_hours: 2, filament_weight: 50.0, ...)
pricing.save!
```

**Never access** old attributes like `pricing.printing_time_hours` (removed). Use `pricing.plates.sum(&:filament_weight)`.

### Key Patterns
- Nested attributes: `plates_attributes`, `plate_filaments_attributes`
- Dynamic forms via Stimulus outlets: `nested_form_controller` → `dynamic_list_controller`
- Filament management: `filament_list_controller` → `dynamic_list_controller`
- Calculations sum across all plates
- Always build at least one plate with at least one filament for tests

## Frontend Stack
- **Stimulus** for interactions
- **Turbo** for SPA-like behavior
- **Bootstrap 5** pure implementation
- **Import Maps** for JS modules

### Critical Turbo Frame Pattern
Never replace frames directly - wrap content:

```erb
<%= turbo_frame_tag "stats_cards" do %>
  <div id="stats_cards_content">
    <%= render "component" %>
  </div>
<% end %>

<!-- Update content, not frame -->
<%= turbo_stream.replace "stats_cards_content" do %>
  <%= render "component" %>
<% end %>
```

### JavaScript Modules
- **Rails 8 importmap-only project** - NO Node.js, npm, or yarn
- Uses CDN imports for external libraries (Bootstrap, jsPDF, html2canvas)
- Stimulus controllers loaded via `pin_all_from` with `preload: false`
- Test JavaScript through browser/Rails server at localhost:3000 with `bin/dev`
- UMD versions for importmap compatibility
- Rails Admin uses separate importmap (`config/importmap.rails_admin.rb`)
- Never pin `rails_admin` in main importmap

### Stimulus Architecture
- Use **outlets** and **events** for controller communication, not inheritance
- Controllers connect in order: `connect()` → `outletConnected()` → initialize functionality
- Wait for outlet connections before accessing outlet targets
- Limits: 10 plates max, 16 filaments per plate, minimum 1 of each

### Modal Pattern (Turbo + Stimulus)
**Custom Event-Based Modal System** for creating records within forms:

**Controllers:**
- `modal_controller.js` - Manages Bootstrap modal lifecycle and loading states
- `modal_link_controller.js` - Dispatches custom `open-modal` event on link click

**Pattern:**
```erb
<!-- Link to open modal -->
<%= link_to new_resource_path(format: :turbo_stream),
    data: {
      controller: "modal-link",
      action: "click->modal-link#open",
      turbo_frame: "modal_content"
    } %>
```

**Key Behaviors:**
1. Modal link dispatches `open-modal` custom event (document-level)
2. Modal controller listens for event and shows loading spinner immediately
3. Turbo frame loads content into `modal_content` frame
4. Success: Turbo stream updates specific dropdown + closes modal
5. Error: Modal stays open showing validation errors

**Turbo Stream Response Pattern:**
```erb
# Update specific dropdown only (not full page reload)
<%= turbo_stream.update "resource_select_frame" do %>
  <%= render_select_with_new_option %>
<% end %>

# Close modal via JavaScript
<%= turbo_stream.append "modal" do %>
  <script>
    bootstrap.Modal.getInstance(document.getElementById('modal'))?.hide()
  </script>
<% end %>
```

**Active Implementations:**
- Clients in invoice forms → updates `client_select_frame`
- Printers in print pricing forms → updates `printer_select_frame`
- Filaments in plate fields → updates all `[data-filament-select-frame]` (multiple instances)

## Performance & Caching

### Caching Strategy
CalcuMake uses multi-layer caching for optimal performance:
- **Rails Fragment Caching**: View components and expensive calculations
- **SolidCache**: Production-ready database-backed cache (via Mission Control)
- **Cloudflare CDN**: Static assets and page caching
- **Browser Caching**: Long-term asset storage

See [docs/CACHING_STRATEGY.md](docs/CACHING_STRATEGY.md) for comprehensive guide.

### Critical Caching Patterns

**1. Always Eager Load Associations:**
```ruby
# ❌ BAD - N+1 queries
@print_pricings = current_user.print_pricings.all

# ✅ GOOD - Single query
@print_pricings = current_user.print_pricings.includes(:plates, :printer, :client)
```

**2. Cache Expensive Calculations with Automatic Invalidation:**
```ruby
# ❌ BAD - Recalculate every render
def total_filament_cost
  plates.sum { |p| p.filament_weight * p.filament_cost_per_gram }
end

# ❌ BAD - Time-based expiration doesn't reflect changes
def total_filament_cost
  Rails.cache.fetch("print_pricing/#{id}/filament_cost", expires_in: 1.hour) do
    plates.sum { |p| p.filament_weight * p.filament_cost_per_gram }
  end
end

# ✅ GOOD - Cache key includes record state for automatic invalidation
def total_filament_cost
  # Cache key includes id + updated_at so any change to the record invalidates cache
  Rails.cache.fetch(["print_pricing", id, "filament_cost", updated_at]) do
    plates.sum { |p| p.filament_weight * p.filament_cost_per_gram }
  end
end

# ✅ BEST - Include dependent records in cache key
def total_filament_cost
  # Invalidates when pricing OR any plate OR any filament changes
  cache_key = [
    "print_pricing", id, updated_at,
    plates.maximum(:updated_at),
    plates.joins(:plate_filaments).maximum("plate_filaments.updated_at")
  ]
  Rails.cache.fetch(cache_key) do
    plates.sum { |p| p.filament_weight * p.filament_cost_per_gram }
  end
end
```

**3. Fragment Cache View Components with Proper Cache Keys:**
```erb
<%# ❌ BAD - Render expensive component every time %>
<%= render "stats_cards" %>

<%# ❌ BAD - Time-based expiration doesn't reflect changes %>
<% cache "stats_cards", expires_in: 1.hour do %>
  <%= render "stats_cards" %>
<% end %>

<%# ✅ GOOD - Cache key includes user and dependent record timestamps %>
<% cache ["stats_cards", current_user.id, current_user.updated_at, current_user.print_pricings.maximum(:updated_at)] do %>
  <%= render "stats_cards" %>
<% end %>

<%# ✅ BEST - Use cache_key_with_version for automatic invalidation %>
<% cache [current_user, "stats_cards", current_user.print_pricings.maximum(:updated_at)] do %>
  <%= render "stats_cards" %>
<% end %>
```

**4. Cache Invalidation Strategy:**

**Preferred: Automatic Invalidation via Cache Keys (No Manual Clearing Needed)**
```ruby
# When using cache keys with updated_at, no manual clearing needed!
# The timestamp changes automatically trigger new cache keys

class PrintPricing < ApplicationRecord
  # Touch parent records to cascade cache invalidation
  belongs_to :user, touch: true
  has_many :plates, dependent: :destroy

  # No after_save callback needed - cache keys handle it
end

class Plate < ApplicationRecord
  belongs_to :print_pricing, touch: true  # Updates print_pricing.updated_at
  has_many :plate_filaments, dependent: :destroy
end

class PlateFilament < ApplicationRecord
  belongs_to :plate, touch: true  # Updates plate.updated_at → print_pricing.updated_at
end
```

**Alternative: Manual Cache Clearing (Only When Necessary)**
```ruby
# Use only when automatic cache keys aren't practical
class PrintPricing < ApplicationRecord
  after_save :clear_cost_cache
  after_touch :clear_cost_cache

  private

  def clear_cost_cache
    # Clear specific cache key (must match fetch key exactly)
    Rails.cache.delete(["print_pricing", id, "filament_cost", updated_at])
    # Problem: This won't work because updated_at changes on save!
    # Better to use the automatic approach above
  end
end
```

**Best Practice: Touch Associations**
```ruby
# Always use touch: true to cascade invalidation
class Filament < ApplicationRecord
  has_many :plate_filaments

  after_update :touch_related_print_pricings

  private

  def touch_related_print_pricings
    # When filament price changes, invalidate all print pricings using it
    plate_filaments.each { |pf| pf.plate.touch }
  end
end
```

### Performance Benchmarks
Target metrics after caching implementation:
- Dashboard load: <200ms (from 500-800ms)
- Index pages: <150ms (from 300-500ms)
- Cache hit rate: >85%
- Database queries per page: <20 (from 100+)

---

## ViewComponent Standards

### When to Use ViewComponents

**✅ Use ViewComponents for:**
1. Repeated UI patterns (cards, badges, buttons)
2. Components with conditional logic
3. Testable view logic
4. Shared components across features
5. Components with complex HTML structure

**❌ Don't Use ViewComponents for:**
1. One-off simple partials
2. Pure content pages
3. Form fields (use form builders)
4. Trivial wrappers around single HTML tags

### ViewComponent Structure

```ruby
# app/components/stats_card_component.rb
class StatsCardComponent < ViewComponent::Base
  def initialize(title:, value:, icon: nil, trend: nil)
    @title = title
    @value = value
    @icon = icon
    @trend = trend
  end

  # Add helper methods for view logic
  def trend_class
    return unless @trend
    @trend.positive? ? "text-success" : "text-danger"
  end
end
```

```erb
<%# app/components/stats_card_component.html.erb %>
<div class="card stat-card">
  <div class="card-body">
    <% if @icon %>
      <i class="<%= @icon %> stat-icon"></i>
    <% end %>
    <h6 class="text-muted"><%= @title %></h6>
    <h3 class="mb-0"><%= @value %></h3>
    <% if @trend %>
      <small class="<%= trend_class %>">
        <%= number_to_percentage(@trend, precision: 1) %>
      </small>
    <% end %>
  </div>
</div>
```

```ruby
# test/components/stats_card_component_test.rb
require "test_helper"

class StatsCardComponentTest < ViewComponent::TestCase
  test "renders with required attributes" do
    render_inline(StatsCardComponent.new(title: "Revenue", value: "$1,234"))

    assert_selector "h6", text: "Revenue"
    assert_selector "h3", text: "$1,234"
  end

  test "shows positive trend in green" do
    render_inline(StatsCardComponent.new(title: "Growth", value: "10%", trend: 5.2))

    assert_selector "small.text-success"
  end
end
```

### Component Organization

```
app/
├── components/
│   ├── shared/              # App-wide components
│   │   ├── stats_card_component.rb
│   │   ├── stats_card_component.html.erb
│   │   └── modal_component.rb
│   ├── print_pricings/      # Feature-specific components
│   │   ├── plate_card_component.rb
│   │   └── cost_breakdown_component.rb
│   └── invoices/
│       └── line_item_component.rb
test/
└── components/              # Component tests (required!)
    ├── shared/
    │   └── stats_card_component_test.rb
    └── print_pricings/
        └── plate_card_component_test.rb
```

### Migration Priority

**Phase 1 (Quick Wins):**
1. `StatsCardComponent` - 5x repetition eliminated
2. `UsageStatsComponent` - 4x repetition eliminated
3. `BadgeComponent` - Universal badge patterns
4. `ButtonComponent` - Consistent button styling
5. `OAuthIconComponent` - Replace 35-line SVG helper

**Phase 2 (Helper Refactoring):**
6. Migrate `content_tag` calls to components
7. Form helpers to components

**Phase 3 (Complex Features):**
8. Advanced calculator components
9. Invoice line item components
10. Print pricing form components

### Testing Requirements

**CRITICAL:** All ViewComponents MUST have corresponding tests.

```ruby
# Minimum test coverage:
# 1. Render with required attributes
# 2. Conditional logic branches
# 3. Helper method behavior
# 4. Edge cases (nil, empty, invalid)

class MyComponentTest < ViewComponent::TestCase
  test "renders successfully" do
    render_inline(MyComponent.new(required: "value"))
    assert_selector "div.my-component"
  end

  test "handles nil optional attributes" do
    render_inline(MyComponent.new(required: "value", optional: nil))
    refute_selector ".optional-content"
  end
end
```

### ViewComponent Caching

Combine ViewComponents with fragment caching:

```erb
<% cache [@user, @print_pricing] do %>
  <%= render StatsCardComponent.new(
    title: "Total Cost",
    value: number_to_currency(@print_pricing.total_cost)
  ) %>
<% end %>
```

---

## Internationalization
Supports 7 languages: en, ja, zh-CN, hi, es, fr, ar

**CRITICAL**: Only maintain English source files in `config/locales/en/` and `config/locales/devise.en.yml` - all other locales are auto-translated.

### Translation File Structure

**English Source Files** (manually maintained):
```
config/locales/
├── en/                          # Split by domain for maintainability
│   ├── activerecord.yml         # Model validations & errors
│   ├── navigation.yml           # Nav, actions, flash, common
│   ├── print_pricings.yml       # Print pricing features
│   ├── printers.yml             # Printer management
│   ├── invoices.yml             # Invoice features
│   ├── filaments.yml            # Filament management
│   ├── clients.yml              # Client management
│   ├── profile.yml              # User profile & settings
│   ├── currency.yml             # Currency & energy
│   ├── application.yml          # App-wide strings
│   ├── support.yml              # Support page
│   ├── legal.yml                # Legal pages
│   ├── landing.yml              # Landing page & marketing
│   ├── subscriptions.yml        # Subscription features
│   └── gdpr.yml                 # GDPR & privacy
└── devise.en.yml                # Devise authentication
```

**Auto-Generated Files** (single file per language):
- `ja.yml`, `es.yml`, `fr.yml`, `ar.yml`, `hi.yml`, `zh-CN.yml`

### Automated Translation System

**Development Workflow** (Local):
1. Add new keys to files in `config/locales/en/` or `config/locales/devise.en.yml`
2. Run `bin/sync-translations` (requires API key for automated translation)
3. Test with `bin/rails test` to ensure nothing broke

**Production Workflow** (Deployment):
1. Add new keys to English master files
2. Commit and push changes
3. Pre-build hook automatically translates all missing keys via OpenRouter API
4. Translations committed automatically before deployment

**Translation Scripts**:

`bin/sync-translations` - Intelligent wrapper script:
- **With API key**: Calls `bin/translate-locales` for automated translation
- **Without API key**: Exits with error (we no longer use English placeholders)
- Merges all `en/*.yml` files before translation
- Auto-detects missing keys across all 6 languages

`bin/translate-locales` - OpenRouter API integration via `open_router` gem:
- **Model**: Google Gemini 2.0 Flash (`google/gemini-2.0-flash-001`) - extremely fast and cost-effective
- **Implementation**: Uses official `open_router` Ruby gem (v0.3.3) for clean, maintainable API calls
- **Batch processing**: 50 keys per request for optimal performance
- **Smart caching**: Stores translations in `tmp/translation_cache/` to avoid re-translating
- **Validation**: Ensures interpolation variables (%{name}, etc.) are preserved
- **JSON parsing**: Handles both JSON and plain-text translation responses
- **Resume capability**: Can restart from cache if interrupted
- **Total keys**: 1,074 keys across 6 languages (ja, es, fr, ar, hi, zh-CN)

**Key Features**:
- Preserves interpolation variables (`%{variable}`)
- Maintains HTML tags and ERB syntax
- Validates translation quality before writing
- Context-aware for 3D printing terminology
- Automatic deployment integration via pre-build hook

**Environment Variables**:
- `OPENROUTER_TRANSLATION_KEY` - API key for automated translations (stored in 1Password)
- Set locally for testing: `export OPENROUTER_TRANSLATION_KEY='your-key'`
- Automatically available in deployment via Kamal secrets

**Merging Translation Conflicts**: When merging branches with locale file conflicts, use `bin/merge-locale-yml` for semantic YAML merging (see `docs/TRANSLATION_MERGE_WORKFLOW.md` for full workflow).

## Database
PostgreSQL with plates table storing per-plate data. Always test with fixtures for both `print_pricings.yml` and `plates.yml`.

## Performance & Caching
**Multi-Layer Caching Strategy** for maximum performance:

### Cache Infrastructure
- **SolidCache** - Database-backed cache store (production)
- **Cloudflare CDN** - Edge caching for static assets and public pages
- **Fragment Caching** - View-level caching for expensive components
- **Counter Caches** - Eliminate COUNT(*) queries on models
- **HTTP Caching** - Browser and CDN caching via headers

### Critical Caching Patterns

**1. Usage Dashboard Caching** (Every authenticated page)
```ruby
# Cache user stats for 5 minutes
user.cached_usage_stats  # Returns { print_pricings: 10, invoices: 5, ... }
```

**2. Fragment Caching** (Expensive components)
```erb
<%# Cache with auto-invalidation on model changes %>
<% cache ["stats_cards", current_user, @pricings.maximum(:updated_at)] do %>
  <%= render "shared/components/stats_cards" %>
<% end %>

<%# Cache individual cards %>
<% cache ["pricing_card", pricing] do %>
  <%= render "shared/components/pricing_card", pricing: pricing %>
<% end %>
```

**3. Eager Loading** (Prevent N+1 queries)
```ruby
# ALWAYS eager load associations
@pricings = current_user.print_pricings
  .includes(plates: [:plate_filaments, :filament])
  .order(created_at: :desc)
```

**4. Counter Caches** (Eliminate COUNT queries)
```ruby
# Use counter_cache: true on associations
belongs_to :user, counter_cache: true
has_many :plates, counter_cache: true

# Access via cached column instead of .count
user.print_pricings_count  # ← Fast (column read)
user.print_pricings.count   # ← Slow (SELECT COUNT(*))
```

### Developer Guidelines

**When to Cache:**
✅ Expensive calculations (> 50ms)
✅ COUNT/SUM/AVG aggregations
✅ Collections that rarely change
✅ Public pages and static content
✅ User-specific stats with 5-10 minute TTL

**Cache Key Patterns:**
```ruby
# Fragment cache
cache [model]  # Uses cache_key_with_version (auto-invalidates)
cache ["namespace", model, timestamp], expires_in: 5.minutes

# Application cache
Rails.cache.fetch("key", expires_in: 5.minutes) { expensive_operation }
```

**Invalidation Strategy:**
- **Automatic**: Rails invalidates when `updated_at` changes
- **Touch associations**: Add `touch: true` to invalidate parent caches
- **Manual**: Use callbacks for complex invalidation
- **Versioning**: Change cache key for structural changes (`_v2`)

### Common Pitfalls

❌ **Don't** cache frequently changing data
❌ **Don't** cache without expiration (memory bloat)
❌ **Don't** forget to eager load associations
❌ **Don't** use `.count` when counter cache exists

**Testing Caches:**
```bash
# Enable caching in development
rails dev:cache

# Check fragment cache logging (already enabled)
# Logs show: "Read fragment views/..." or "Write fragment views/..."
```

**Reference:** See `docs/CACHING_STRATEGY.md` for comprehensive implementation guide.

## Authentication
Devise with confirmable and omniauthable modules. OAuth providers: Google, GitHub, Microsoft, Facebook, Yahoo Japan, LINE. Email confirmation via Resend (noreply@calcumake.com). Rails Admin at `/admin` (requires `admin: true`).

**Local Development**: Requires `dotenv-rails` gem and `.env.local` file (see `.env.local.example`). OAuth credentials stored in 1Password with `CALCUMAKE_` prefix, used in app without prefix.

## PWA (Progressive Web App)
- Built-in Rails 8 PWA with manifest + service worker
- Auto-registration via `pwa_registration_controller.js`
- Routes: `/manifest` and `/service-worker`

## Subscription System (Stripe)
- **Plans**: Free (trial), Startup (¥150/mo), Pro (¥1,500/mo)
- **Implementation**: PR #26 merged - Stripe Checkout with webhooks
- **Status**: ~95% complete, needs API credentials configuration
- **Controllers**: `SubscriptionsController`, `Webhooks::StripeController`
- **Testing**: WebMock stubs for unit tests, Stripe Sandbox for integration
- **Sandbox Mode**: Uses NEW Stripe Sandbox system (not legacy test mode)
- **Credentials needed**: `publishable_key`, `secret_key`, `webhook_secret`, `startup_price_id`, `pro_price_id`
- **Configuration**: See `config/initializers/stripe.rb` for setup
- **Development**: `bin/dev` runs Rails + Stripe webhook forwarding via foreman
- **Webhook Testing**: Stripe CLI forwards to `localhost:3000/webhooks/stripe`
- **Test Cards**: Use `4242 4242 4242 4242` (Visa) or `pm_card_visa` payment method ID

## Deployment
- **Kamal** with Docker
- **Hetzner S3** for file storage
- Hooks in `.kamal/hooks/` (no file extensions)
- **Pre-build hook** runs Rails tests + Jest tests before deployment (blocks deployment on failure)

## Testing

**Hybrid Testing Strategy** for maximum speed:

### Test Frameworks
- **Minitest** (Rails) - Unit/integration tests (1,068 tests in ~3.5s)
- **Jest** (JavaScript) - Unit tests for Stimulus mixins (20 tests in ~0.3s)
- **Capybara** (System) - End-to-end browser tests (slower, use sparingly)

### Running Tests

**Before Every Push:**
```bash
bin/ci  # Runs all CI checks: security, linting, Rails tests, Jest tests
```

**Individual Test Suites:**
```bash
bin/rails test           # Rails tests only (~3.5s)
npm test                 # JavaScript tests only (~0.3s)
npm run test:watch       # Watch mode for JS tests
bin/rails test:system    # System tests (slow)
```

### JavaScript Testing (Jest)

CalcuMake uses **Jest for JavaScript unit tests** with no build step in production:
- Tests run locally and in CI
- NOT deployed to production (dev dependency only)
- Importmaps serve JS files directly in production

**What's Tested:**
- `calculator_mixin.js` - Cost calculation formulas
- `storage_mixin.js` - localStorage operations
- Pure functions only (DOM manipulation tested in system tests)

**Example Test:**
```javascript
import { CalculatorMixin } from 'controllers/mixins/calculator_mixin.js'

test('calculateFilamentCost sums multiple filaments', () => {
  const mockController = Object.assign({}, CalculatorMixin)
  const plateData = {
    filaments: [
      { weight: 100, pricePerKg: 25 },
      { weight: 50, pricePerKg: 30 }
    ]
  }

  const cost = mockController.calculateFilamentCost(plateData)

  expect(cost).toBeCloseTo(4.0) // (100/1000 * 25) + (50/1000 * 30)
})
```

### Test Organization

```
test/
├── components/       # ViewComponent tests (Minitest)
├── controllers/      # Controller tests (Minitest)
├── helpers/          # Helper tests (Minitest)
├── javascript/       # JavaScript tests (Jest)
│   └── controllers/
│       └── mixins/
├── models/           # Model tests (Minitest)
└── system/           # System tests (Capybara)
```

### CI/CD
- **GitHub Actions** runs all tests on every push (parallel jobs)
- **Kamal pre-build hook** runs all tests before deployment (blocks on failure)
- No Node.js required in production (importmaps only)

**Deployment Safety:** Tests run in 3 places:
1. **Locally** - `bin/ci` before pushing
2. **GitHub Actions** - On every push/PR
3. **Pre-deployment** - Kamal pre-build hook before Docker build

**See [docs/TESTING_GUIDE.md](docs/TESTING_GUIDE.md) for comprehensive testing documentation.**

## Design Standards
**Moab Desert Theme** - Compact design system inspired by Utah's natural landscapes:
- **Color Palette**: Deep red primary (#c8102e), sandstone orange secondary (#d2691e), desert sage success (#9caf88)
- **Typography**: 15-25% smaller than standard Bootstrap
- **Spacing**: 25-40% reduction from standard
- **Buttons**: Universal `0.6rem 1.2rem` padding, gradient backgrounds
- **Cards**: Glass-morphism effect with backdrop-filter and subtle shadows
- **Forms**: Authentication forms constrained to 28rem max-width, centered on large screens
- **Responsive**: Mobile-first with container adjustments

## Code Standards & Tools
- **Ruby Style**: Omakase Ruby style guide with Rubocop
- **CSS**: Bootstrap 5 CDN + custom CSS variables for theming
- **Testing**: Minitest with parallel workers, system tests via Capybara/Selenium
- **Security**: Brakeman static analysis, CSP headers, CSRF protection
- **SEO**: Comprehensive meta tags, structured data, sitemap generation
- **Performance**: Asset pipeline with Propshaft, CDN imports, PWA caching

## Key Files
- `app/models/user.rb` - User model with Devise confirmable + omniauthable
- `app/models/client.rb` - Client management model
- `app/models/plate.rb` - Individual plate model
- `app/helpers/oauth_helper.rb` - OAuth provider configuration
- `app/helpers/application_helper.rb` - OAuth buttons and icons for views
- `app/views/devise/shared/_oauth_buttons.html.erb` - OAuth login buttons partial
- `app/javascript/controllers/nested_form_controller.js` - Dynamic plate management
- `app/javascript/controllers/modal_controller.js` - Modal lifecycle management
- `app/javascript/controllers/modal_link_controller.js` - Modal open event dispatcher
- `app/javascript/controllers/advanced_calculator_controller.js` - Public pricing calculator SPA
- `app/views/shared/_modal.html.erb` - Reusable modal component
- `app/views/pages/pricing_calculator.html.erb` - Advanced calculator public page
- `app/helpers/print_pricings_helper.rb` - View formatting
- `app/assets/stylesheets/application.css` - Moab theme styling
- `config/locales/en/*.yml` - English master translations split by domain (manually maintained)
- `config/locales/devise.en.yml` - English Devise translations (manually maintained)
- `config/locales/*.yml` - Auto-translated locale files (ja, es, fr, ar, hi, zh-CN) - single combined files
- `bin/split-translations` - Helper to split en.yml into domain files (one-time use)
- `bin/sync-translations` - Translation wrapper (auto-detects API key)
- `bin/translate-locales` - Automated translation via OpenRouter API (merges en/ files before translating)
- `.kamal/hooks/pre-build` - Deployment hook (runs translations + tests + auto-commit)
- `.env.local` - OAuth credentials (gitignored, see `.env.local.example`)

## Documentation Context Reference

### Active Documentation
**Performance & Caching:** `docs/CACHING_STRATEGY.md` | `docs/CACHING_PHASE_1_PLAN.md` - Multi-layer caching architecture and implementation guide
**ViewComponents:** `docs/VIEWCOMPONENT_RESEARCH.md` | `docs/VIEWCOMPONENT_MIGRATION_ROADMAP.md` - Component architecture and migration plan
**PR Merge Strategy:** `docs/PR_MERGE_STRATEGY.md` - Systematic testing and production deployment plan
**OAuth Setup:** `docs/OAUTH_SETUP_GUIDE.md`
**Stripe Integration:** `docs/STRIPE_SETUP.md`
**Landing Page:** `docs/LANDING_PAGE_PLAN.md`
**Turbo Framework:** `docs/TURBO_REFERENCE.md` | `docs/TURBO_CHEATSHEET.md`
**Modal Pattern:** `docs/MODAL_IMPLEMENTATION.md` - Complete guide for custom event-based modal system
**Translation System:** `docs/AUTOMATED_TRANSLATION_SYSTEM.md` - OpenRouter API automated translations
**Translation Workflow:** `docs/TRANSLATION_MERGE_WORKFLOW.md` - Locale file merging and sync procedures
**Caching Strategy:** `docs/CACHING_STRATEGY.md` - Comprehensive multi-layer caching implementation guide

### Historical Context (Archive)
When additional context is needed for historical decisions or completed features:
- **Monetization & Legal:** `docs/archive/2025-11-05-monetization-legal-compliance-report.md` - Complete legal compliance analysis for paid plans, privacy policies, and subscription system
- **Feature Status:** `docs/archive/MONETIZATION_UPDATE_SUMMARY.md`, `docs/archive/TRANSLATION_STATUS.md` - Historical implementation records
- **Future Plans:** `docs/archive/ADSENSE_PREPARATION.md` - Prepared but not implemented features

*Reference documentation only when specific context is required.*
## Recent Updates

### 2025-11-18: Production-Ready & Revenue-Enabled ✅
- **All tests passing**: 425 runs, 1,457 assertions, 0 failures, 0 errors
- **Advanced calculator launched**: `/3d-print-pricing-calculator` - full-featured SPA with PDF/CSV export
- **Multi-plate support**: Up to 10 plates with 16 filaments each, real-time calculations
- **Export functionality**: Professional PDF generation with jsPDF, CSV export for spreadsheets
- **Stripe production webhooks**: Configured and active at `https://calcumake.com/webhooks/stripe`
- **Revenue-ready**: Subscription system fully operational (¥150 Startup, ¥1,500 Pro)
- **SEO optimized**: Strategic route, meta tags, structured data for search engines
- **Fully internationalized**: 7 languages with automated translation system

### 2025-11-16: Translation Files Refactored
- **Split English translations** from single `en.yml` (1,365 lines) into 15 domain-specific files in `config/locales/en/`
- **Updated `bin/translate-locales`** to automatically merge all `en/*.yml` files before translation
- **Benefits**: Easier to edit, less prone to YAML corruption, better organization, easier code reviews

### 2025-01-16: Translation System Refactored to use `open_router` Gem
- Replaced manual HTTP calls with official `open_router` Ruby gem (v0.3.3)
- Switched to **Gemini 2.0 Flash** (`google/gemini-2.0-flash-001`)
- All 1,074 keys successfully translated across 6 languages (ja, es, fr, ar, hi, zh-CN)
- Translation cache in `tmp/translation_cache/` for efficiency
- Fail-fast: exits with error code 1 if translations fail (no silent fallbacks)
