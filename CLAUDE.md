# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Application Overview

**3DP** is a comprehensive Rails 8.0 3D print project management software that includes invoicing, manual cost tracking, and pricing calculations for 3D print jobs. The application provides complete project lifecycle management from initial pricing through delivery, with user authentication via Devise and multi-currency support with configurable energy costs.

## Development Commands

### Setup and Development
- `bin/setup` - Complete project setup (installs dependencies, prepares database, starts server)
- `bin/dev` - Start development server
- `bin/rails server` - Start Rails server manually
- `bin/rails console` - Rails console
- `bin/rails db:migrate` - Run database migrations
- `bin/rails db:prepare` - Prepare database (create/migrate/seed as needed)

### Testing and Quality
- `bin/rails test` - Run all tests
- `bin/rails test test/models/user_test.rb` - Run specific test file
- `bin/brakeman` - Security vulnerability scanning
- `bin/rubocop` - Ruby code style checking (Omakase Rails style)

## Core Architecture

### Models and Relationships
- **User**: Authenticated users with default currency and energy cost settings
- **Printer**: User-owned 3D printers with power consumption, cost, and payoff tracking
- **PrintPricing**: Individual print job calculations with comprehensive cost breakdown

```
User (1) -> (many) Printers
User (1) -> (many) PrintPricings
```

### Key Pricing Calculation Components
The `PrintPricing` model handles complex cost calculations including:
- Filament costs (based on weight, spool price, markup)
- Electricity costs (power consumption × time × energy rate)
- Labor costs (prep and post-processing time)
- Machine upkeep costs (depreciation and repair factors)
- VAT and final pricing calculations

### Currency Support
Multi-currency support via `CurrencyHelper`:
- Supports USD, EUR, GBP, JPY, CAD, AUD
- Different decimal precision per currency (e.g., JPY has 0 decimals)
- Format and validation utilities

### Printer Management
- 23 predefined manufacturers (Prusa, Bambu Lab, Creality, etc.)
- Payoff tracking with `paid_off?` and `months_to_payoff` methods
- Automatic date tracking for purchase date

## Frontend Technology Stack
- **Stimulus** (Hotwire) for JavaScript interactions
- **Turbo** for SPA-like navigation and real-time updates
- **Turbo Streams** for partial page updates (used in print times increment/decrement)
- **Import Maps** for JavaScript module management
- **Propshaft** for asset pipeline

### Turbo Streams Implementation
The application uses Turbo Streams for seamless real-time updates:
- **Print Times Tracking**: Increment/decrement buttons update values without page reload
- **Controller Actions**: Both `increment_times_printed` and `decrement_times_printed` respond to Turbo Stream requests
- **Partial Updates**: Uses `_times_printed_control.html.erb` partial for targeted DOM updates
- **Fallback Support**: HTML format responses for non-JavaScript clients

## Database
- **PostgreSQL** as primary database
- User profile settings stored in users table
- Comprehensive pricing data with decimal precision for financial calculations

## Authentication & Authorization
- **Devise** handles user authentication
- All main features require authenticated users
- User-specific data isolation (users can only access their own printers/pricings)

## Deployment
- **Kamal** deployment configuration available
- **Docker** containerization support
- **Thruster** for production HTTP acceleration

### Kamal Hooks
Kamal automatically executes hooks during deployment stages. To customize deployment behavior:
- Create bash scripts in `.kamal/hooks/` directory (no file extensions)
- Hook files are named after deployment stages: `pre-build`, `post-build`, `pre-deploy`, `post-deploy`
- **Important**: Do NOT add `hooks:` section to `config/deploy.yml` - Kamal automatically finds and executes hook files
- Example: `.kamal/hooks/pre-build` runs before Docker image build

## Internationalization (i18n)

The application supports multiple languages with comprehensive translation coverage:

### Supported Languages
- **English** (en) - Default
- **Japanese** (ja) - 日本語
- **Mandarin Chinese** (zh-CN) - 中文（简体）
- **Hindi** (hi) - हिंदी
- **Spanish** (es) - Español
- **French** (fr) - Français
- **Standard Arabic** (ar) - العربية

### Implementation Details
- **Configuration**: Located in `config/application.rb` with available locales and fallbacks
- **Locale Files**: Individual YAML files in `config/locales/` for each language
- **Language Switching**: Dropdown selector in header with automatic form submission
- **Session Persistence**: Selected language stored in session and user profile
- **Controller Logic**: `ApplicationController` handles locale detection and switching

### Translation File Structure
Each locale file (`config/locales/[locale].yml`) contains:
- Navigation labels (`nav.*`)
- Common actions (`actions.*`)
- Flash messages (`flash.*`)
- Model names (`models.*`)
- Feature-specific translations (printer, print_pricing, currency, etc.)

### Adding New Features
**CRITICAL: ALL new features MUST include full language support from day one.**

When adding new features to the application:

1. **ALWAYS use i18n helpers** in views (never hardcode text):
   ```erb
   <%= t('key.name') %>  # Instead of hardcoded text
   ```

2. **MANDATORY: Add translations to ALL 7 locale files**:
   ```yaml
   # Add to each config/locales/[locale].yml (en, ja, zh-CN, hi, es, fr, ar)
   new_feature:
     title: "Translated Title"
     description: "Translated Description"
   ```

3. **Use translation keys for flash messages**:
   ```ruby
   # In controllers
   redirect_to path, notice: t('flash.created', model: t('models.printer'))
   ```

4. **Include model attribute translations**:
   ```yaml
   # For form labels and validation messages
   models:
     new_model: "Translated Model Name"
   new_model:
     attribute_name: "Translated Attribute"
   ```

5. **Test in multiple languages** before considering feature complete

6. **No feature is complete without translations** - this is non-negotiable

### Language Switching
- Language selector appears in the main navigation header
- Uses POST request to `/switch_locale` endpoint
- Automatically redirects back to previous page
- Stores preference in session and user profile (if logged in)

### CSS Considerations
- Language selector styled to match navigation theme
- Responsive design for mobile devices
- RTL languages (Arabic) may require additional CSS considerations

## Testing
Uses Rails default testing framework (Minitest) with:
- Model tests for business logic validation
- Controller tests for request handling and Turbo Stream responses
- System tests with Capybara and Selenium for integration testing

### Turbo Stream Testing
Controller tests include specific tests for Turbo Stream responses:
- Tests both HTML and Turbo Stream format responses
- Validates Turbo Stream content and target element IDs
- Ensures proper partial rendering and data updates