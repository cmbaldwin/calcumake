# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Application Overview

**CalcuMake** (calcumake.com) is a comprehensive Rails 8.0 3D print project management software that includes invoicing, manual cost tracking, and pricing calculations for 3D print jobs. The application provides complete project lifecycle management from initial pricing through delivery, with user authentication via Devise and multi-currency support with configurable energy costs.

**Copyright**: © 2025 株式会社モアブ (MOAB Co., Ltd.) - All rights reserved.

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
- **User**: Authenticated users with default currency and energy cost settings, invoice defaults, and company logo
- **Printer**: User-owned 3D printers with power consumption, cost, and payoff tracking
- **PrintPricing**: Individual print job calculations with comprehensive cost breakdown
- **Plate**: Individual build plates within a print job (1-10 plates per pricing)
- **Invoice**: Professional invoices generated from PrintPricing with automatic numbering and status tracking
- **InvoiceLineItem**: Individual line items within invoices (filament, electricity, labor, machine, other, custom)

```
User (1) -> (many) Printers
User (1) -> (many) PrintPricings
User (1) -> (many) Invoices
PrintPricing (1) -> (many) Plates
PrintPricing (1) -> (many) Invoices
Invoice (1) -> (many) InvoiceLineItems
```

### Multi-Plate Architecture
Each `PrintPricing` can contain **1 to 10 plates**, representing multiple build plates for a single print job:

**Plate Model** ([app/models/plate.rb](app/models/plate.rb)):
- `printing_time_hours` - Hours to print this plate
- `printing_time_minutes` - Minutes to print this plate
- `filament_weight` - Grams of filament used for this plate
- `filament_type` - Type of filament (PLA, ABS, PETG, etc.)
- `spool_price` - Cost of filament spool in user's currency
- `spool_weight` - Weight of filament spool in grams
- `markup_percentage` - Markup percentage for filament cost

**Dynamic Plate Management**:
- Users can add/remove plates using Stimulus controller
- Minimum 1 plate required (validation enforced)
- Maximum 10 plates allowed (UI enforces limit)
- Each plate has its own print time and material specifications
- All calculations sum across plates for total job cost

**Implementation Details**:
```ruby
# PrintPricing validations
validates :plates, length: {
  minimum: 1, message: "must have at least one plate",
  maximum: 10, message: "cannot have more than ten plates"
}

# Nested attributes for dynamic plate management
accepts_nested_attributes_for :plates, allow_destroy: true, reject_if: :all_blank

# Calculations sum across all plates
def total_printing_time_minutes
  plates.sum(&:total_printing_time_minutes)
end

def total_filament_cost
  plates.sum(&:total_filament_cost)
end
```

**Stimulus Controller** ([app/javascript/controllers/nested_form_controller.js](app/javascript/controllers/nested_form_controller.js)):
- Handles dynamic add/remove of plate fields in forms
- Uses template-based approach with unique timestamps
- Manages remove button visibility (hidden when only 1 plate)
- Disables add button at 10 plate limit

### Key Pricing Calculation Components
The `PrintPricing` model handles complex cost calculations including:
- **Filament costs** - Sum of all plates' (weight × spool price / spool weight × markup)
- **Electricity costs** - Sum of all plates' print time × power consumption × energy rate
- **Labor costs** - Prep and post-processing time (job-level, not per-plate)
- **Machine upkeep costs** - Depreciation and repair factors (job-level)
- **VAT and final pricing** - Applied to total calculated costs

### Professional Invoicing System
The application includes a comprehensive invoicing system for converting print pricing calculations into professional invoices:

**Invoice Model** ([app/models/invoice.rb](app/models/invoice.rb)):
- **Automatic numbering**: Sequential invoice numbers (INV-000001, INV-000002, etc.) with thread-safe generation
- **Status tracking**: Draft → Sent → Paid/Cancelled workflow
- **Company branding**: Logo upload and company details integration
- **Multi-currency support**: Inherits currency from user defaults or print pricing
- **Due date management**: Automatic overdue detection and status updates

**Invoice Line Items** ([app/models/invoice_line_item.rb](app/models/invoice_line_item.rb)):
- **Categorized line items**: filament, electricity, labor, machine, other, custom
- **Automatic calculations**: quantity × unit_price = total_price
- **Flexible ordering**: Order position for custom line item arrangement
- **Rich descriptions**: Detailed breakdown of each cost component

**User Invoice Integration**:
- **Company defaults**: Default company name, address, email, phone, payment details
- **Invoice templates**: Default notes and payment instructions
- **Counter synchronization**: Automatic invoice number management per user
- **Active Storage**: Company logo attachment for professional branding

**Key Features**:
- One-click invoice generation from print pricing calculations
- Professional PDF export capabilities
- Invoice status management (draft, sent, paid, cancelled)
- Company logo and branding integration via Active Storage
- Thread-safe invoice numbering with automatic collision detection
- Complete audit trail with creation and modification timestamps

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

### JavaScript Module Management
**Importmap Configuration Patterns:**

**UMD vs ES Module Imports:**
When using CDN libraries with importmaps, ensure proper module format:

```ruby
# CORRECT - UMD version for importmaps compatibility
pin "jspdf", to: "https://cdnjs.cloudflare.com/ajax/libs/jspdf/3.0.3/jspdf.umd.min.js"

# Usage in JavaScript
import "jspdf"
const pdf = new window.jsPDF({...})  # Access as global variable
```

**Rails Admin Importmap Separation:**
Rails Admin uses its own importmap system to avoid conflicts:
- Main app: `config/importmap.rb`
- Rails Admin: `config/importmap.rails_admin.rb` (uses JSPM.io CDN)
- NEVER pin `rails_admin` in main importmap - let Rails Admin manage its own dependencies

### CSS Z-Index Management
**Bootstrap Dropdown Issues:**
Dropdown menus in cards may appear behind content due to Bootstrap/Popper.js positioning. Fix with:

```css
/* Dropdown menu z-index fixes */
.dropdown-menu { z-index: 1050 !important; }
.card .dropdown-menu { z-index: 1060 !important; }
.card { overflow: visible !important; }
.card-body { overflow: visible !important; }
```

**Popper.js Configuration:**
For dropdowns in constrained containers, add boundary and container attributes:

```erb
<button data-bs-toggle="dropdown"
        data-bs-boundary="viewport"
        data-bs-container="body">
```

### CSS Architecture
**Bootstrap 5 Pure Implementation** - The application uses Bootstrap 5 exclusively with custom color theming:

- **application.css**: Bootstrap 5 import with custom CSS variables for color theming using Bootstrap's recommended approach:
  ```css
  :root {
    --bs-primary: #c8102e;       /* Deep red rock */
    --bs-secondary: #d2691e;     /* Sandstone orange */
    --bs-success: #9caf88;       /* Desert sage */
    --bs-info: #87ceeb;          /* Desert sky blue */
    --bs-warning: #f4a460;       /* Sandy brown */
    --bs-danger: #cd853f;        /* Terracotta */
  }
  ```
- **Rails Admin styles**: Consolidated into application.css under a commented section to avoid duplicate Bootstrap imports
- **Zero custom CSS**: All components use pure Bootstrap 5 classes for maintainability and consistency
- **Responsive Design**: Bootstrap's built-in grid system and responsive utilities
- **Component System**: Cards, forms, navigation, buttons all use Bootstrap component classes

**Migration Note**: Previously used custom CSS files (moab_theme.css, forms.css, print_pricings.css, user_profiles.css) but migrated to pure Bootstrap 5 approach in 2024. This change dramatically improved maintainability, reduced code complexity, and ensured responsive design consistency.

### Turbo Streams Implementation
The application uses Turbo Streams for seamless real-time updates:
- **Print Times Tracking**: Increment/decrement buttons update values without page reload
- **Controller Actions**: Both `increment_times_printed` and `decrement_times_printed` respond to Turbo Stream requests
- **Partial Updates**: Uses `shared/components/_times_printed_control.html.erb` partial for targeted DOM updates
- **Fallback Support**: HTML format responses for non-JavaScript clients

### Stimulus Controllers
The application uses Stimulus controllers for interactive functionality:

- **Nested Form Controller** ([app/javascript/controllers/nested_form_controller.js](app/javascript/controllers/nested_form_controller.js)):
  - Manages dynamic add/remove of plate fields in PrintPricing forms
  - Uses template-based approach with unique timestamp IDs
  - Key methods:
    - `add()`: Adds new plate using template, replacing NEW_RECORD with timestamp
    - `remove()`: Marks existing plates for deletion (_destroy field) or removes new plates from DOM
    - `updateRemoveButtons()`: Manages button visibility (hides when 1 plate, disables add at 10 plates)
  - Targets: `container` (plate list), `template` (hidden template for new plates)
  - Usage in form: `data-controller="nested-form"` on form container

- **Toast Controller** ([app/javascript/controllers/toast_controller.js](app/javascript/controllers/toast_controller.js)):
  - Handles auto-dismissing flash notifications with configurable delays

- **Times Printed Controller** ([app/javascript/controllers/times_printed_controller.js](app/javascript/controllers/times_printed_controller.js)):
  - Manages increment/decrement functionality with proper Turbo stream handling

**Controller Patterns:**
- **Data Values**: Controllers use Stimulus values API for configuration (e.g., `data-toast-auto-dismiss-value`)
- **Actions**: Interactive elements use `data-action` attributes to connect to controller methods
- **Targets**: Elements use `data-{controller}-target` for DOM element references

### Component Architecture & Helper Organization
The application follows a well-organized component-based architecture:

**Helper Organization:**
- **PrintPricingsHelper** ([app/helpers/print_pricings_helper.rb](app/helpers/print_pricings_helper.rb)): View-specific formatting and display logic
  - `format_print_time(pricing)`: Calculates and formats total printing time across all plates
  - `format_creation_date(pricing)`: Formats creation date display
  - `total_print_time_hours(print_pricings)`: Calculates total print time across multiple pricings
  - `pricing_card_metadata_badges(pricing)`: Generates badges showing plate count, filament types, weight, and time
  - `pricing_card_actions(pricing)`: Generates action buttons for pricing cards
  - `cost_breakdown_sections(pricing)`: Renders comprehensive cost breakdown including all plates
  - `form_section_card(title, &block)`: DRY helper for form section cards
  - `form_info_section(icon, title, &block)`: DRY helper for info sections
  - `currency_input_group(form, field, **options)`: DRY helper for currency inputs with Bootstrap styling
- **ApplicationHelper**: General-purpose helpers for common UI patterns
- **CurrencyHelper**: Currency formatting and multi-currency support utilities

**Shared Components:**
- **`shared/components/_pricing_card.html.erb`**: Reusable pricing card component displaying plate count, filament types, and totals
- **`shared/components/_stats_cards.html.erb`**: Statistics display component for index pages
- **`shared/components/_times_printed_control.html.erb`**: Interactive increment/decrement control with Turbo Stream support

**Form Architecture - Modular Partials:**
The PrintPricing form was refactored from 206 lines of duplicated code to a highly modular, DRY architecture:

- **`print_pricings/_form.html.erb`** (9 lines): Shared form wrapper used by both new and edit views
- **`print_pricings/form_sections/_basic_information.html.erb`**: Job name, printer selection, start_with_one_print toggle
- **`print_pricings/form_sections/_plates.html.erb`**: Dynamic plates container with Stimulus controller integration
- **`print_pricings/form_sections/_labor_costs.html.erb`**: Prep and postprocessing time inputs
- **`print_pricings/form_sections/_other_costs.html.erb`**: Other costs and VAT percentage
- **`print_pricings/form_sections/_info_sections.html.erb`**: Electricity and machine upkeep information cards
- **`print_pricings/_plate_fields.html.erb`**: Individual plate field template (used by Stimulus for dynamic add/remove)

**Result**: 96% code reduction (206 → 9 lines per form view)

**View Organization:**
- Eliminated unused auto-generated view files (create.html.erb, update.html.erb, destroy.html.erb)
- Removed backup/original files from development process
- Consolidated logic into helpers and shared components for better maintainability
- Form sections organized in dedicated `/form_sections/` directory
- All partials moved to logical shared/components structure when used across multiple views

**Testing Coverage:**
- Comprehensive helper method tests in `test/helpers/print_pricings_helper_test.rb`
- Integration tests for Turbo Stream functionality
- All shared components tested through controller and integration tests
- Complete test coverage for plates feature with 141 tests passing

### Search Functionality
**Typeahead Search with Turbo Frames:**

The PrintPricings index includes reactive search functionality:

**Implementation** ([app/views/print_pricings/index.html.erb](app/views/print_pricings/index.html.erb)):
```erb
<%= form_with(url: print_pricings_path, method: :get,
              data: { turbo_frame: :print_pricings_results }) do |form| %>
  <%= form.text_field :query, value: params[:query],
      placeholder: t('print_pricing.index.search_placeholder'),
      oninput: "this.form.requestSubmit()" %>
<% end %>

<%= turbo_frame_tag :print_pricings_results do %>
  <!-- Results rendered here -->
<% end %>
```

**Search Scope** ([app/models/print_pricing.rb](app/models/print_pricing.rb)):
```ruby
scope :search, ->(query) do
  return all if query.blank?
  where("job_name ILIKE ?", "%#{sanitize_sql_like(query)}%")
    .or(where(id: Plate.where("filament_type ILIKE ?",
              "%#{sanitize_sql_like(query)}%").select(:print_pricing_id)))
end
```

**Features:**
- Searches across job names and plate filament types
- Auto-submits on input (no button required)
- Updates results reactively via Turbo Frame
- Shows "no results" state when query matches nothing
- Fully internationalized search placeholder and messages

## Database
- **PostgreSQL** as primary database
- User profile settings stored in users table
- Comprehensive pricing data with decimal precision for financial calculations

### Database Schema - Plates Table
The `plates` table stores individual build plate data for each print job:

**Migration** ([db/migrate/20251021020820_create_plates.rb](db/migrate/20251021020820_create_plates.rb)):
```ruby
create_table :plates do |t|
  t.references :print_pricing, null: false, foreign_key: true
  t.integer :printing_time_hours
  t.integer :printing_time_minutes
  t.decimal :filament_weight, precision: 10, scale: 2
  t.string :filament_type
  t.decimal :spool_price, precision: 10, scale: 2
  t.decimal :spool_weight, precision: 10, scale: 2
  t.decimal :markup_percentage, precision: 5, scale: 2
  t.timestamps
end
```

**Data Migration** ([db/migrate/20251021020830_migrate_plate_data_from_print_pricings.rb](db/migrate/20251021020830_migrate_plate_data_from_print_pricings.rb)):
- Automatically migrated all existing `PrintPricing` records to have one `Plate` with their original data
- Removed plate-specific columns from `print_pricings` table after migration
- Fully reversible migration (can roll back safely)

### Best Practices - Working with Plates

**Creating PrintPricings in Code:**
Always use the `build` → `save!` pattern, never `create!` directly:

```ruby
# CORRECT - Build first, then save
pricing = user.print_pricings.build(job_name: "Test Job", printer: printer)
pricing.plates.build(
  printing_time_hours: 2,
  printing_time_minutes: 30,
  filament_weight: 50.0,
  filament_type: "PLA",
  spool_price: 25.0,
  spool_weight: 1000.0,
  markup_percentage: 15.0
)
pricing.save!

# WRONG - This will fail validation (no plates)
pricing = user.print_pricings.create!(job_name: "Test Job", printer: printer)
```

**Controller Parameters:**
Use nested `plates_attributes` hash for form submissions:

```ruby
# Correct params structure
{
  print_pricing: {
    job_name: "Job Name",
    printer_id: 1,
    plates_attributes: {
      "0" => { printing_time_hours: 2, filament_weight: 50.0, ... },
      "1" => { printing_time_hours: 1, filament_weight: 30.0, ... }
    }
  }
}
```

**Testing:**
- Always build at least one plate when testing PrintPricing creation
- Use fixtures with both `print_pricings.yml` and `plates.yml`
- Test edge cases: minimum (1 plate), maximum (10 plates)

**Displaying Data:**
- Never access old attributes like `pricing.printing_time_hours` (removed in migration)
- Use helper methods: `format_print_time(pricing)` for calculated values
- Access plates via association: `pricing.plates.sum(&:filament_weight)`

## Authentication & Authorization
- **Devise** handles user authentication
- All main features require authenticated users
- User-specific data isolation (users can only access their own printers/pricings)
- **Rails Admin** provides admin interface at `/admin` (requires admin privileges)

### Rails Admin Configuration
The application includes a properly configured Rails Admin interface:
- **JSPM CDN Integration**: Uses separate importmap file (`config/importmap.rails_admin.rb`) with JSPM CDN dependencies
- **Complete CSS**: Full Rails Admin styles in `app/assets/stylesheets/rails_admin.css`
- **Propshaft Compatible**: No manifest.js required, assets auto-discovered
- **Admin Authentication**: Users need `admin: true` field to access Rails Admin
- **Access Control**: Redirects non-admin users to root, unauthenticated users to sign in

## Deployment
- **Kamal** deployment configuration available
- **Docker** containerization support
- **Thruster** for production HTTP acceleration

### Active Storage Configuration
**Hetzner S3 Object Storage** - Production file storage configuration:
- **Service**: S3-compatible Hetzner Object Storage (hel1 region)
- **Bucket**: `moab` bucket for all production file uploads
- **Environment variables**: `HETZNER_S3_ACCESS_KEY` and `HETZNER_S3_SECRET_KEY`
- **Endpoint**: `https://hel1.your-objectstorage.com/`
- **Usage**: Company logos, user profile attachments, invoice assets
- **Local development**: Uses local disk storage (`local` service)
- **Testing**: Uses temporary disk storage (`test` service)

**Configuration Files**:
- `config/storage.yml`: Defines storage services and S3 connection details
- `config/environments/production.rb`: Sets `config.active_storage.service = :hetzner`
- `.kamal/secrets`: Manages S3 credentials via 1Password integration
- `config/deploy.yml`: Injects S3 environment variables during deployment

## Monetization
**Google AdSense Integration:**
- AdSense script loaded in application layout head section
- Responsive ad unit displayed at bottom of main content area
- Publisher ID: `ca-pub-5257142454834240`
- Ad slot: `9779716586`
- Configured for auto format with full-width responsive design

## Legal & Support Pages
**Comprehensive Legal Framework:**
- **Privacy Policy** (`/privacy-policy`): Complete GDPR-compliant privacy policy including AdSense disclosure, data collection, usage, and user rights
- **User Agreement** (`/user-agreement`): Terms of service with calculation disclaimers, acceptable use, intellectual property, and liability limitations
- **Support Page** (`/support`): Contact information with direct email link to support@calcumake.com

**Navigation Integration:**
- **Authenticated Users**: Help dropdown in navbar containing Support, Privacy Policy, and Terms of Service
- **Non-authenticated Users**: Direct Support link in navbar
- **Footer**: All three legal pages accessible from footer on every page

**Testing Coverage:**
- Complete controller tests for all legal pages
- Integration tests for navbar functionality (authenticated vs non-authenticated states)
- Footer integration tests across all pages
- All tests pass rubocop style checks

## Component Architecture Updates
**Navbar Modularization:**
- Navbar extracted to `app/views/shared/_navbar.html.erb` partial
- Responsive Bootstrap dropdown implementation for help menu
- Language selector integrated with proper form submission
- Authentication-aware navigation (different links for signed-in vs guest users)

**Legal Page Styling:**
- Professional card-based layout with clear section headers
- Responsive design optimized for readability
- Important disclaimers highlighted with Bootstrap alert components
- Consistent typography and spacing following design system

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

## Hotwire/Turbo Architecture & Best Practices

This application implements modern Hotwire patterns following Rails 8 conventions. All new features should leverage Turbo for reactive, SPA-like behavior without custom JavaScript.

### Turbo Drive
Turbo Drive is enabled by default and provides automatic AJAX navigation:

**Key Benefits:**
- Converts link clicks and form submissions to AJAX requests automatically
- Only replaces `<body>` content, preserving `<head>` for faster navigation
- Creates single-page application experience with zero configuration

**Best Practices:**
- Use `data-turbo="false"` to disable Turbo Drive for specific links/forms
- Return `422` status code for invalid form submissions
- Use `data-turbo-track="reload"` for assets that require full page reloads
- Customize progress bar styles to match application design

**Implementation Example:**
```erb
<!-- Disable Turbo Drive for external links -->
<%= link_to "External Site", "https://example.com", data: { turbo: false } %>

<!-- Track asset changes -->
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
```

### Turbo Frames
Turbo Frames enable partial page updates by segmenting page content:

**Core Concepts:**
- Wrap content in `turbo_frame_tag` to create updateable page segments
- Use `data-turbo-frame` attribute on links/forms to target specific frames
- Enables independent loading and updating of page sections

**Frame Targeting Patterns:**
```erb
<!-- Basic frame definition -->
<%= turbo_frame_tag "printer_form" do %>
  <%= form_with model: @printer, data: { turbo_frame: "printer_form" } do |form| %>
    <!-- form content -->
  <% end %>
<% end %>

<!-- Target different frame -->
<%= link_to "Edit", edit_printer_path(@printer), data: { turbo_frame: "sidebar" } %>

<!-- Break out of frame -->
<%= link_to "View All", printers_path, data: { turbo_frame: "_top" } %>
```

**Nested Frames Best Practices:**
- Use `dom_id` helpers for unique frame identification
- Create helper methods for complex nested IDs:
```ruby
def nested_dom_id(*args)
  args.map { |arg| arg.respond_to?(:to_key) ? dom_id(arg) : arg }.join("_")
end
```

**Lazy Loading Frames:**
```erb
<%= turbo_frame_tag "lazy_content", src: lazy_load_path do %>
  <p>Loading...</p>
<% end %>
```

### Turbo Streams
Turbo Streams provide real-time updates and complex DOM manipulations:

**Available Actions:**
- `append` - Add content to end of target
- `prepend` - Add content to beginning of target
- `replace` - Replace entire target element
- `update` - Replace target's inner content
- `remove` - Delete target element
- `before` - Insert content before target
- `after` - Insert content after target

**Controller Integration:**
```ruby
def create
  @printer = current_user.printers.build(printer_params)

  if @printer.save
    respond_to do |format|
      format.html { redirect_to @printer, notice: "Printer created." }
      format.turbo_stream {
        flash.now[:notice] = "Printer created successfully."
        render turbo_stream: [
          turbo_stream.prepend("printers", @printer),
          turbo_stream.replace("flash", partial: "layouts/flash")
        ]
      }
    end
  else
    render :new, status: :unprocessable_content
  end
end
```

**Turbo Stream Templates:**
```erb
<!-- app/views/printers/create.turbo_stream.erb -->
<%= turbo_stream.prepend "printers" do %>
  <%= render @printer %>
<% end %>

<%= turbo_stream.replace "printer_form" do %>
  <%= render "form", printer: Printer.new %>
<% end %>
```

**Real-time Broadcasting:**
```ruby
# In model
class Printer < ApplicationRecord
  broadcasts_to ->(printer) { "user_#{printer.user_id}_printers" },
                 inserts_by: :prepend
end

# In view
<%= turbo_stream_from "user_#{current_user.id}_printers" %>
```

### Flash Messages with Turbo
Modern flash message implementation using CSS animations and Stimulus:

**HTML Structure:**
```erb
<!-- app/views/layouts/application.html.erb -->
<div id="flash" class="flash">
  <%= render "layouts/flash" %>
</div>

<!-- app/views/layouts/_flash.html.erb -->
<% flash.each do |flash_type, message| %>
  <div class="flash__message flash__message--<%= flash_type %>"
       data-controller="removals"
       data-action="animationend->removals#remove">
    <%= message %>
  </div>
<% end %>
```

**CSS Animation:**
```css
.flash__message {
  animation: appear-then-fade 4s both;
}

@keyframes appear-then-fade {
  0%, 100% { opacity: 0; transform: translateY(-10px); }
  5%, 60% { opacity: 1; transform: translateY(0); }
}
```

**Stimulus Controller:**
```javascript
// app/javascript/controllers/removals_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  remove() {
    this.element.remove()
  }
}
```

**Controller Integration:**
```ruby
respond_to do |format|
  format.html { redirect_to path, notice: "Success!" }
  format.turbo_stream {
    flash.now[:notice] = "Success!"
    render "layouts/flash"
  }
end
```

**Critical Turbo Frame Pattern - Avoiding Connection Loss:**
When updating content within Turbo Frames that need to remain reactive for subsequent operations, NEVER replace the frame itself. Instead, wrap the dynamic content in a separate container:

```erb
<!-- WRONG - This breaks subsequent updates -->
<%= turbo_frame_tag "stats_cards" do %>
  <div class="content">...</div>
<% end %>

<!-- Turbo Stream that breaks connection -->
<%= turbo_stream.replace "stats_cards" do %>
  <%= render "component" %>
<% end %>
```

```erb
<!-- CORRECT - Frame stays intact -->
<%= turbo_frame_tag "stats_cards" do %>
  <div id="stats_cards_content">
    <%= render "shared/components/stats_cards", print_pricings: @print_pricings %>
  </div>
<% end %>

<!-- Turbo Stream that preserves connection -->
<%= turbo_stream.replace "stats_cards_content" do %>
  <%= render "shared/components/stats_cards", print_pricings: @print_pricings %>
<% end %>
```

This pattern ensures the Turbo Frame container remains in the DOM and maintains its JavaScript connections for subsequent updates.

### Stimulus Controllers
Follow these patterns for Stimulus controller implementation:

**Controller Structure:**
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { autoHide: Boolean, delay: Number }
  static targets = [ "content", "button" ]
  static classes = [ "active", "hidden" ]

  connect() {
    // Initialize controller
  }

  disconnect() {
    // Cleanup when removed from DOM
  }

  // Action methods
  toggle() {
    this.element.classList.toggle(this.activeClass)
  }
}
```

**Data Attributes Pattern:**
```erb
<div data-controller="modal"
     data-modal-auto-hide-value="true"
     data-modal-delay-value="3000"
     data-modal-active-class="modal--open">
  <div data-modal-target="content">Modal content</div>
  <button data-action="click->modal#close"
          data-modal-target="button">Close</button>
</div>
```

### Development Guidelines

**When to Use Each Turbo Technology:**
- **Turbo Drive**: Default for all navigation (requires no code changes)
- **Turbo Frames**: Partial page updates, forms, independent page sections
- **Turbo Streams**: Real-time updates, complex DOM manipulation, list management

**Testing Turbo Features:**
- Test both HTML and Turbo Stream responses in controller tests
- Use `assert_turbo_stream` helpers in tests
- Test JavaScript behavior with system tests and Capybara

**Performance Considerations:**
- Use `broadcasts_to *_later` methods for background job processing
- Implement proper caching strategies for frequently accessed frames
- Consider lazy loading for expensive content

**Security Best Practices:**
- Always validate permissions before broadcasting streams
- Use signed stream names for sensitive operations
- Implement proper CSRF protection for all forms

**Debugging Tips:**
- Use `data-turbo-track="reload"` to force reloads during development
- Enable Turbo logging: `Turbo.session.drive.debug = true`
- Check browser Network tab for Turbo Stream responses
- Use Rails logging to debug controller responses

**Common Patterns:**
- Modal forms using Turbo Frames
- Inline editing with Turbo Streams
- Real-time notifications with Action Cable
- Progressive enhancement with Stimulus
- Optimistic UI updates with proper fallbacks

## Design Standards & UI Guidelines

### Compact Design System
The application follows a **compact design approach** optimized for maximizing screen real estate while maintaining excellent usability and visual hierarchy.

### Typography Scale
**Primary Headings:**
- H1: `2rem` (down from 2.5rem standard)
- H2: `1.8rem`
- H3: `1.5rem` with `0.4rem` padding-bottom
- Subtitle text: `1rem` (down from 1.2rem standard)

**Body Text:**
- Standard: `0.85rem` (down from 1rem standard)
- Small text: `0.75rem`
- Table cells: `0.85rem`

### Spacing System
**Button Padding Standards:**
- Primary buttons: `0.5rem 1rem` (37% reduction from 0.8rem 1.5rem)
- Small buttons: `0.3rem 0.6rem` (40% reduction from 0.5rem 1rem)
- Button font-size: `0.85rem` for primary, `0.75rem` for small

**Container & Layout Spacing:**
- Section margins: `1rem - 1.5rem` (25-33% reduction from 2-3rem)
- Card padding: `0.75rem - 1rem` (25-33% reduction from 1.5-2rem)
- Form field spacing: `0.75rem` margins (25% reduction from 1rem)

**Table Cell Spacing:**
- Header cells: `0.6rem` padding (40% reduction from 1rem)
- Body cells: `0.6rem` padding (40% reduction from 1rem)

### Component Standards

**Navigation:**
- Nav gap: `0.75rem` (25% reduction)
- Nav link padding: `0.5rem 0.8rem`
- Nav link font-size: `0.85rem`
- Brand font-size: `1.3rem` (13% reduction from 1.5rem)

**Stats Cards:**
- Padding: `0.75rem` (25% reduction from 1rem)
- Gap between cards: `0.5rem` (33% reduction from 0.75rem)
- Stat numbers: `1.5rem` (17% reduction from 1.8rem)
- Min-width: `160px` desktop, `140px` mobile

**Interactive Elements:**
- Border radius: `6px` primary (25% reduction from 8px)
- Border radius: `3-4px` small elements
- Box shadows: Reduced opacity (0.15-0.25 vs 0.3-0.4)
- Hover transforms: `-1px` (50% reduction from -2px)

**Times Printed Controls:**
- Button size: `22px` desktop, `16px` mobile (8-11% reduction)
- Font-size: `0.75rem` desktop, `0.6rem` mobile
- Gap: `0.4rem` desktop, `0.2rem` mobile

### Form Components
**Input Fields:**
- Padding: `0.6rem` (20% reduction from 0.75rem)
- Font-size: `0.9rem` (10% reduction from 1rem)
- Border radius: `6px` (25% reduction from 8px)

**Form Sections:**
- Border radius: `12px` (25% reduction from 16px)
- Padding: `1.5rem` (25% reduction from 2rem)
- Margin between sections: `1.5rem` (25% reduction from 2rem)

### Mobile Responsive Standards
**Breakpoint Adjustments:**
- Hero titles: Additional 10-15% size reduction on mobile
- Table min-width: `650px` (reduced from 700-800px)
- Stat cards: Further 25% padding reduction on mobile
- Button sizes: Additional 10-15% reduction for touch targets

### CSS File Organization
**Modular Architecture:**
- `application.css`: Global styles, navigation, flash messages, containers
- `moab_theme.css`: Theme colors, base components, typography
- `print_pricings.css`: Index pages, tables, stat cards
- `user_profiles.css`: Profile pages, form sections
- `forms.css`: Reusable form components

### Implementation Guidelines
**When Adding New Components:**
1. **Start with base sizing** then reduce by 25-40% for padding/margins
2. **Use consistent spacing scale**: 0.5rem, 0.75rem, 1rem, 1.5rem
3. **Font-size reductions**: 10-15% smaller than standard sizing
4. **Border radius**: Prefer 6px for primary, 3-4px for small elements
5. **Box shadows**: Use lighter opacity values (0.15-0.25 range)

**Responsive Design Approach:**
- Mobile-first with progressive enhancement
- Additional 10-25% spacing reduction on small screens
- Maintain minimum touch target sizes (44px minimum)
- Stack elements vertically with reduced gaps on mobile

**Testing Standards:**
- Verify layouts work on 1200px+ screens without excessive whitespace
- Ensure mobile layouts remain usable with tighter spacing
- Test across different zoom levels (90%, 100%, 110%)
- Validate touch targets meet accessibility guidelines

### Button Standardization
**Universal Button Dimensions:**
All buttons (primary, secondary, outline, clear) must have identical dimensions to ensure visual consistency and professional appearance.

**Standard Button Specifications:**
- **Padding**: `0.6rem 1.2rem` (consistent across all button types)
- **Border**: `2px solid` (transparent for primary, visible for others)
- **Border radius**: `6px`
- **Font size**: `0.9rem`
- **Font weight**: `600`
- **Min-width**: `120px` (ensures consistent button sizing)
- **Text alignment**: `center`
- **Transition**: `all 0.2s ease`

**Button Types:**
- **Primary**: Gradient background, transparent border
- **Secondary**: Transparent background, solid border
- **Outline**: Transparent background, primary color border
- **Clear**: Transparent background, muted border

**Box Shadow Standards:**
- **Primary**: `0 2px 8px rgba(200, 16, 46, 0.25)`
- **Secondary/Others**: `0 1px 4px rgba(0, 0, 0, 0.08)`
- **Hover states**: Slight increase in shadow intensity

**Hover Effects:**
- **Transform**: `translateY(-1px)` (subtle lift effect)
- **Shadow enhancement**: Darker/more prominent shadows
- **Color transitions**: Smooth background/border color changes

**Implementation Rule:**
ALL buttons throughout the application MUST use these exact specifications. This ensures:
1. **Visual consistency** across all forms and pages
2. **Professional appearance** with uniform button sizing
3. **Predictable user experience** with consistent interaction patterns
4. **Accessibility compliance** with adequate touch targets

**Code Example:**
```css
.button, .primary-button, .secondary-button {
  padding: 0.6rem 1.2rem;
  border: 2px solid;
  border-radius: 6px;
  font-size: 0.9rem;
  font-weight: 600;
  min-width: 120px;
  text-align: center;
  transition: all 0.2s ease;
}
```

### Design Principles
1. **Maximize screen real estate** while maintaining visual hierarchy
2. **Consistent spacing ratios** across all components (25-40% reductions)
3. **Progressive density** - more compact on larger screens
4. **Preserve usability** - never sacrifice accessibility for compactness
5. **Visual coherence** - maintain design language despite tighter spacing
6. **Button uniformity** - all buttons must have identical dimensions regardless of type