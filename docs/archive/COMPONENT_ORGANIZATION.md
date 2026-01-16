# ViewComponent Organization Guide

**Last Updated:** 2025-11-21  
**Status:** Active Standard

---

## Directory Structure

```
app/components/
├── shared/                          # Reusable UI primitives
│   ├── button_component.rb
│   ├── button_component.html.erb
│   ├── badge_component.rb
│   ├── badge_component.html.erb
│   ├── icon_component.rb
│   ├── icon_component.html.erb
│   ├── alert_component.rb
│   ├── alert_component.html.erb
│   ├── modal_component.rb
│   ├── modal_component.html.erb
│   ├── card_component.rb
│   ├── card_component.html.erb
│   └── stats_card_component.rb      # Move from root
│
├── forms/                           # Form-related components
│   ├── field_component.rb
│   ├── field_component.html.erb
│   ├── select_field_component.rb
│   ├── select_field_component.html.erb
│   ├── checkbox_field_component.rb
│   ├── radio_field_component.rb
│   ├── file_upload_component.rb
│   ├── currency_field_component.rb
│   ├── date_picker_component.rb
│   ├── section_component.rb         # FormSectionComponent
│   ├── nested_component.rb          # NestedFormComponent
│   ├── actions_component.rb         # FormActionsComponent
│   └── errors_component.rb          # FormErrorsComponent
│
├── layout/                          # Layout & navigation
│   ├── navbar_component.rb
│   ├── navbar_component.html.erb
│   ├── footer_component.rb
│   ├── footer_component.html.erb
│   ├── breadcrumbs_component.rb
│   ├── flash_messages_component.rb
│   ├── cookie_consent_component.rb
│   └── locale_suggestion_banner_component.rb
│
├── cards/                           # Generic card types
│   ├── usage_stats_component.rb
│   ├── usage_stats_component.html.erb
│   ├── usage_dashboard_widget_component.rb
│   ├── feature_card_component.rb
│   ├── problem_card_component.rb
│   ├── pricing_tier_card_component.rb
│   └── info_section_component.rb
│
├── invoices/                        # Invoice feature components
│   ├── card_component.rb
│   ├── card_component.html.erb
│   ├── header_component.rb
│   ├── header_component.html.erb
│   ├── line_item_component.rb
│   ├── line_items_table_component.rb
│   ├── line_items_totals_component.rb
│   ├── actions_component.rb
│   ├── status_badge_component.rb
│   └── form_component.rb
│
├── print_pricings/                  # Print pricing feature
│   ├── card_component.rb
│   ├── card_component.html.erb
│   ├── form_component.rb
│   ├── plate_fields_component.rb
│   ├── plate_filament_fields_component.rb
│   ├── times_printed_control_component.rb
│   └── metadata_badges_component.rb
│
├── printers/                        # Printer feature
│   ├── card_component.rb
│   ├── header_component.rb
│   ├── financial_status_component.rb
│   ├── jobs_section_header_component.rb
│   └── form_component.rb
│
├── clients/                         # Client feature
│   ├── card_component.rb
│   └── form_component.rb
│
├── filaments/                       # Filament feature
│   ├── card_component.rb
│   └── form_component.rb
│
└── calculator/                      # Advanced calculator
    ├── advanced_component.rb
    ├── plate_component.rb
    ├── results_component.rb
    └── input_field_component.rb

test/components/                     # Mirrors app/components structure
├── shared/
│   ├── button_component_test.rb
│   ├── badge_component_test.rb
│   ├── icon_component_test.rb
│   └── stats_card_component_test.rb  # Move from root
├── forms/
│   ├── field_component_test.rb
│   └── section_component_test.rb
├── layout/
│   └── navbar_component_test.rb
├── cards/
│   └── usage_stats_component_test.rb
├── invoices/
│   ├── card_component_test.rb
│   └── header_component_test.rb
├── print_pricings/
│   └── card_component_test.rb
└── calculator/
    └── advanced_component_test.rb
```

---

## Organization Principles

### 1. Categorization Strategy

Components are organized by **function and feature**:

- **`shared/`** - Reusable UI primitives used across entire app
- **`forms/`** - All form-related components
- **`layout/`** - Page layout, navigation, global UI
- **`cards/`** - Generic card types not tied to specific features
- **`[feature]/`** - Feature-specific components (invoices, print_pricings, etc.)

### 2. Naming Conventions

#### Component Files

```ruby
# ✅ GOOD: Clear, descriptive names
shared/button_component.rb
invoices/header_component.rb
forms/field_component.rb

# ❌ BAD: Redundant prefixes
shared/shared_button_component.rb
invoices/invoice_header_component.rb
```

#### Component Classes

```ruby
# ✅ GOOD: Namespace matches directory
class Shared::ButtonComponent < ViewComponent::Base
end

class Invoices::HeaderComponent < ViewComponent::Base
end

class Forms::FieldComponent < ViewComponent::Base
end

# ❌ BAD: Flat namespace
class ButtonComponent < ViewComponent::Base
end
```

#### Usage in Views

```erb
<%# Shared components - common primitives %>
<%= render Shared::ButtonComponent.new(text: "Submit") %>
<%= render Shared::BadgeComponent.new(text: "Active") %>

<%# Feature components %>
<%= render Invoices::HeaderComponent.new(invoice: @invoice) %>
<%= render PrintPricings::CardComponent.new(pricing: @pricing) %>

<%# Form components %>
<%= render Forms::FieldComponent.new(form: f, attribute: :name) %>
```

### 3. When to Create a New Namespace

**Create a feature namespace when:**

- You have 3+ components related to a single feature
- Components are specific to that feature (not reusable elsewhere)
- The feature has distinct domain logic

**Keep in shared/ when:**

- Component is used across multiple features
- Component is a UI primitive (button, badge, icon, etc.)
- Component has no feature-specific logic

**Examples:**

```ruby
# ✅ Feature namespace - specific to invoices
invoices/
  ├── header_component.rb          # Invoice-specific header
  ├── line_item_component.rb       # Invoice line items
  └── status_badge_component.rb    # Invoice status logic

# ✅ Shared namespace - used everywhere
shared/
  ├── badge_component.rb           # Generic badge (any status)
  ├── button_component.rb          # Generic button
  └── card_component.rb            # Generic card wrapper
```

---

## Migration Path

### Phase 1: Organize Existing Components

```bash
# 1. Create namespace directories
mkdir -p app/components/{shared,forms,layout,cards,invoices,print_pricings,printers,clients,filaments,calculator}
mkdir -p test/components/{shared,forms,layout,cards,invoices,print_pricings,printers,clients,filaments,calculator}

# 2. Move existing component to shared/
mv app/components/stats_card_component.* app/components/shared/
mv test/components/stats_card_component_test.rb test/components/shared/

# 3. Update class namespace
# Edit shared/stats_card_component.rb to use Shared:: namespace

# 4. Update all usages in views
# Change: render StatsCardComponent
# To: render Shared::StatsCardComponent
```

### Phase 2: Create New Components in Correct Namespace

```bash
# Always create in appropriate namespace from start
touch app/components/shared/button_component.rb
touch app/components/shared/button_component.html.erb
touch test/components/shared/button_component_test.rb
```

---

## Component Templates

### Shared Component Template

```ruby
# app/components/shared/example_component.rb
# frozen_string_literal: true

module Shared
  class ExampleComponent < ViewComponent::Base
    def initialize(required:, optional: "default")
      @required = required
      @optional = optional
    end

    # Public helper methods for template
    def css_classes
      classes = ["example"]
      classes << @optional if @optional
      classes.join(" ")
    end

    private

    # Private helper methods
    def complex_calculation
      # ...
    end
  end
end
```

```erb
<%# app/components/shared/example_component.html.erb %>
<div class="<%= css_classes %>">
  <%= @required %>
</div>
```

### Feature Component Template

```ruby
# app/components/invoices/header_component.rb
# frozen_string_literal: true

module Invoices
  class HeaderComponent < ViewComponent::Base
    def initialize(invoice:, show_mode: true)
      @invoice = invoice
      @show_mode = show_mode
    end

    # Slots for flexible content
    renders_one :company
    renders_one :metadata

    def invoice_number
      @invoice.invoice_number.presence || "Draft"
    end
  end
end
```

### Test Template

```ruby
# test/components/shared/example_component_test.rb
require "test_helper"

module Shared
  class ExampleComponentTest < ViewComponent::TestCase
    test "renders with required attributes" do
      render_inline(Shared::ExampleComponent.new(required: "value"))

      assert_selector "div.example"
      assert_text "value"
    end

    test "applies custom optional value" do
      render_inline(Shared::ExampleComponent.new(
        required: "value",
        optional: "custom"
      ))

      assert_selector "div.example.custom"
    end

    test "uses default optional value" do
      render_inline(Shared::ExampleComponent.new(required: "value"))

      assert_selector "div.example.default"
    end
  end
end
```

---

## Refactoring Checklist

When creating a new component:

- [ ] ✅ Place in correct namespace directory
- [ ] ✅ Use proper module namespace in class
- [ ] ✅ Create corresponding test in same namespace
- [ ] ✅ Write comprehensive tests (90%+ coverage)
- [ ] ✅ Document component API in comments
- [ ] ✅ Find all usages with `git grep "render.*PartialName"`
- [ ] ✅ Replace all usages with namespaced component
- [ ] ✅ Remove old partial/helper
- [ ] ✅ Run full test suite
- [ ] ✅ Manual browser testing

---

## Quick Reference: Which Namespace?

| Component Type         | Namespace             | Example                               |
| ---------------------- | --------------------- | ------------------------------------- |
| Buttons, badges, icons | `shared/`             | `Shared::ButtonComponent`             |
| Cards (generic)        | `cards/` or `shared/` | `Shared::CardComponent`               |
| Cards (feature)        | `[feature]/`          | `Invoices::CardComponent`             |
| Form fields            | `forms/`              | `Forms::FieldComponent`               |
| Form-specific          | `[feature]/`          | `Invoices::FormComponent`             |
| Headers, footers       | `layout/`             | `Layout::NavbarComponent`             |
| Feature displays       | `[feature]/`          | `PrintPricings::PlateFieldsComponent` |
| Calculator             | `calculator/`         | `Calculator::AdvancedComponent`       |

---

## Benefits of This Structure

### ✅ Clarity

- Immediately clear where to find components
- Easy to discover related components
- Logical grouping by function and feature

### ✅ Scalability

- Can add new features without cluttering root
- Feature teams can work in isolation
- Clear boundaries between shared and feature code

### ✅ Maintainability

- Related components are colocated
- Easy to refactor feature components
- Clear dependency boundaries

### ✅ Discoverability

- New developers can navigate easily
- IDE autocomplete works better
- Test structure mirrors component structure

---

## Migration Priority

1. **Create namespace directories** ✅
2. **Move existing StatsCardComponent** to `shared/`
3. **Create new components** in proper namespaces from start
4. **Update CLAUDE.md** with organization standards
5. **Document in migration plan**

---

**Document Status:** ACTIVE STANDARD  
**Last Updated:** 2025-11-21  
**Owner:** Development Team  
**Enforcement:** ALL new components must follow this structure
