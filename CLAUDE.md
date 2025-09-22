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

### CSS Architecture
The application uses a modular CSS approach with dedicated stylesheets:
- **application.css**: Global styles, navigation, toast notifications, containers
- **print_pricings.css**: Print pricing index, table styles, times printed controls
- **user_profiles.css**: User profile pages, form sections, calculator headers
- **forms.css**: Reusable form components and input styles
- **Minimal inline CSS**: All major styling moved to dedicated CSS files for better maintainability

### Turbo Streams Implementation
The application uses Turbo Streams for seamless real-time updates:
- **Print Times Tracking**: Increment/decrement buttons update values without page reload
- **Controller Actions**: Both `increment_times_printed` and `decrement_times_printed` respond to Turbo Stream requests
- **Partial Updates**: Uses `shared/components/_times_printed_control.html.erb` partial for targeted DOM updates
- **Fallback Support**: HTML format responses for non-JavaScript clients

### Stimulus Controllers
The application uses Stimulus controllers for interactive functionality:
- **Toast Controller** (`toast_controller.js`): Handles auto-dismissing flash notifications with configurable delays
- **Times Printed Controller** (`times_printed_controller.js`): Manages increment/decrement functionality with proper Turbo stream handling
- **Data Values**: Controllers use Stimulus values API for configuration (e.g., `data-toast-auto-dismiss-value`)
- **Actions**: Interactive elements use `data-action` attributes to connect to controller methods

### Component Architecture & Helper Organization
The application follows a well-organized component-based architecture:

**Helper Organization:**
- **PrintPricingsHelper**: Contains view-specific formatting and display logic
  - `format_print_time(pricing)`: Formats printing time display
  - `format_creation_date(pricing)`: Formats creation date display
  - `total_print_time_hours(print_pricings)`: Calculates total print time across multiple pricings
  - `pricing_card_metadata_badges(pricing)`: Generates metadata badges for pricing cards
  - `pricing_card_actions(pricing)`: Generates action buttons for pricing cards
- **ApplicationHelper**: General-purpose helpers for common UI patterns
- **CurrencyHelper**: Currency formatting and multi-currency support utilities

**Shared Components:**
- **`shared/components/_pricing_card.html.erb`**: Reusable pricing card component with responsive Bootstrap grid
- **`shared/components/_stats_cards.html.erb`**: Statistics display component for index pages
- **`shared/components/_times_printed_control.html.erb`**: Interactive increment/decrement control with Turbo Stream support

**View Organization:**
- Eliminated unused auto-generated view files (create.html.erb, update.html.erb, destroy.html.erb)
- Removed backup/original files from development process
- Consolidated logic into helpers and shared components for better maintainability
- All partials moved to logical shared/components structure when used across multiple views

**Testing Coverage:**
- Comprehensive helper method tests in `test/helpers/print_pricings_helper_test.rb`
- Integration tests for Turbo Stream functionality
- All shared components tested through controller and integration tests

## Database
- **PostgreSQL** as primary database
- User profile settings stored in users table
- Comprehensive pricing data with decimal precision for financial calculations

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