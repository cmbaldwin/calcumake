# CLAUDE.md

## Application Overview
**CalcuMake** - Rails 8.1.1 3D print project management with invoicing, cost tracking, and pricing calculations. Multi-currency support, Devise authentication with OAuth and email confirmation.

**Copyright**: © 2025 株式会社モアブ (MOAB Co., Ltd.)

## Development Commands
- `bin/setup` - Complete setup
- `bin/dev` - Development server
- `bin/rails test` - Run tests
- `bin/rubocop` - Style checking
- `bin/brakeman` - Security scan

## Core Architecture

### Models
- **User**: Currency/energy defaults, company info, logo, confirmable, omniauthable
- **Client**: Customer management (searchable via Ransack)
- **Printer**: Power consumption, payoff tracking
- **PrintPricing**: Job calculations (1-10 plates), linked to clients
- **Plate**: Individual build plates with time/material specs
- **Invoice**: Auto-numbered, status tracking, client integration
- **InvoiceLineItem**: Categorized cost breakdowns

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

## Internationalization
Supports 7 languages: en, ja, zh-CN, hi, es, fr, ar

**CRITICAL**: ALL new features MUST include translations for ALL 7 languages. Use `t('key')` helpers, never hardcode text.

## Database
PostgreSQL with plates table storing per-plate data. Always test with fixtures for both `print_pricings.yml` and `plates.yml`.

## Authentication
Devise with confirmable and omniauthable modules. OAuth providers: Google, GitHub, Microsoft, Facebook, Yahoo Japan, LINE. Email confirmation via Resend (noreply@calcumake.com). Rails Admin at `/admin` (requires `admin: true`).

**Local Development**: Requires `dotenv-rails` gem and `.env.local` file (see `.env.local.example`). OAuth credentials stored in 1Password with `CALCUMAKE_` prefix, used in app without prefix.

## PWA (Progressive Web App)
- Built-in Rails 8 PWA with manifest + service worker
- Auto-registration via `pwa_registration_controller.js`
- Routes: `/manifest` and `/service-worker`

## Deployment
- **Kamal** with Docker
- **Hetzner S3** for file storage
- Hooks in `.kamal/hooks/` (no file extensions)

## Testing
Minitest with Turbo Stream tests. Test both HTML and turbo_stream formats.

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
- `app/helpers/print_pricings_helper.rb` - View formatting
- `app/assets/stylesheets/application.css` - Moab theme styling
- `config/locales/` - All 7 language files
- `.env.local` - OAuth credentials (gitignored, see `.env.local.example`)

## Documentation Context Reference

**OAuth Setup:** `docs/OAUTH_SETUP_GUIDE.md`
**Landing Page:** `docs/LANDING_PAGE_PLAN.md`
**Turbo Framework:** `docs/TURBO_REFERENCE.md` | `docs/TURBO_CHEATSHEET.md`

*Reference documentation only when specific context is required.*