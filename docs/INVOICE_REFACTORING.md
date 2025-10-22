# Invoice Views Refactoring Summary

## Overview

This refactoring reorganizes the invoice views into well-structured partials and helper methods, following Rails best practices and DRY principles.

## New Directory Structure

```
app/views/invoices/
├── partials/
│   ├── _company_info_card.html.erb           # Company information card for forms
│   ├── _company_info_display.html.erb        # Reusable company info display
│   ├── _customer_info.html.erb               # Customer billing information
│   ├── _form_actions.html.erb                # Form submit/cancel buttons
│   ├── _index_table_row.html.erb             # Individual invoice row in index
│   ├── _invoice_company_section.html.erb     # Company section for show page
│   ├── _invoice_date_fields.html.erb         # Date input fields
│   ├── _invoice_details_card.html.erb        # Invoice details card wrapper
│   ├── _invoice_header.html.erb              # Invoice header for show page
│   ├── _invoice_metadata.html.erb            # Invoice number, dates, status
│   ├── _invoice_number_field.html.erb        # Invoice number input field
│   ├── _invoice_number_preview.html.erb      # Preview for auto-generated number
│   ├── _invoice_status_currency_fields.html.erb  # Status and currency selects
│   ├── _invoice_totals.html.erb              # Subtotal and total display
│   ├── _line_item_row.html.erb               # Single line item row in table
│   ├── _line_items_card.html.erb             # Line items card for forms
│   ├── _line_items_footer.html.erb           # Table footer with totals
│   ├── _line_items_table.html.erb            # Complete line items table
│   ├── _payment_notes_cards.html.erb         # Payment & notes cards for forms
│   ├── _payment_notes_display.html.erb       # Payment & notes display for show
│   ├── _show_action_buttons.html.erb         # Action buttons for show page
│   └── _show_header.html.erb                 # Header with back button & actions
├── _form.html.erb                             # Main invoice form (refactored)
├── _invoice_card.html.erb                     # Invoice card component (existing)
├── _invoice_line_item_fields.html.erb         # Line item fields (existing)
├── edit.html.erb
├── index.html.erb                             # Invoice list (refactored)
├── new.html.erb
└── show.html.erb                              # Invoice display (refactored)
```

## Helper Methods Added

### InvoicesHelper (`app/helpers/invoices_helper.rb`)

**Status & Badge Helpers:**

- `invoice_status_badge(invoice, size: "fs-6")` - Complete status badge with text
- `invoice_status_class(invoice)` - Bootstrap class for status color
- `invoice_status_badge_class(invoice)` - Full badge class string (legacy)

**Currency Helpers:**

- `formatted_currency_amount(amount, currency)` - Format amount with currency symbol
- `formatted_invoice_total(invoice)` - Quick invoice total formatting

**Form Helpers:**

- `invoice_number_preview(number)` - Generate "INV-000001" format
- `invoice_status_options(current_status = nil)` - Status select options
- `invoice_action_button_class(invoice, action)` - Dynamic button classes

**Utility Helpers:**

- `invoice_date_range(invoice)` - Human-readable date range
- `invoice_line_items_editable?(invoice)` - Check if editable

## Key Improvements

### 1. **DRY Principle**

- Status badge logic centralized (was duplicated 3+ times)
- Currency formatting unified across views
- Company info display reused between form and show views
- Line item display logic shared

### 2. **Separation of Concerns**

- Form partials in `partials/` subdirectory
- Each card component isolated
- Presentation logic moved to helpers
- Print styles separated

### 3. **Maintainability**

- Smaller, focused partials (average ~15 lines)
- Clear naming conventions
- Easy to locate and modify specific sections
- Consistent structure across views

### 4. **Reusability**

- Partials accept parameters for flexibility
- Helper methods work across all invoice views
- Status badge can be used in any view
- Currency formatting consistent everywhere

## Refactored Files

### \_form.html.erb

**Before:** 203 lines with inline HTML for all sections
**After:** 29 lines with clean partial renders

**Structure:**

```erb
<%= form_with(...) do |form| %>
  <div class="row g-3">
    <%= render "invoices/partials/company_info_card" %>
    <%= render "invoices/partials/invoice_details_card", ... %>
    <%= render "invoices/partials/line_items_card", ... %>
    <%= render "invoices/partials/payment_notes_cards", ... %>
    <%= render "invoices/partials/form_actions", ... %>
  </div>
<% end %>
```

### show.html.erb

**Before:** 131 lines with mixed concerns
**After:** 18 lines with logical sections

**Structure:**

```erb
<div data-controller="pdf-generator" ...>
  <%= render "invoices/partials/show_header", ... %>
  <div class="invoice-content">
    <%= render "invoices/partials/invoice_header", ... %>
    <%= render "invoices/partials/customer_info", ... %>
    <%= render "invoices/partials/line_items_table", ... %>
    <%= render "invoices/partials/payment_notes_display", ... %>
  </div>
</div>
```

### index.html.erb

**Before:** Inline badge/currency logic in table rows
**After:** Clean loop with partial render

**Change:**

```erb
<tbody>
  <% @invoices.each do |invoice| %>
    <%= render "invoices/partials/index_table_row", invoice: invoice, print_pricing: @print_pricing %>
  <% end %>
</tbody>
```

## Benefits

1. **Easier Testing** - Smaller units to test
2. **Better Collaboration** - Clear file boundaries
3. **Faster Development** - Reusable components
4. **Reduced Bugs** - Single source of truth for logic
5. **Improved Readability** - Self-documenting structure

## Migration Notes

- All existing functionality preserved
- No database changes required
- Stimulus controller integration maintained
- Translation keys unchanged
- CSS classes remain the same

## Usage Examples

### Using Status Badge Helper

```erb
<!-- Old way -->
<span class="badge bg-<%= invoice.status == 'paid' ? 'success' : 'secondary' %>">
  <%= t("invoices.status.#{invoice.status}") %>
</span>

<!-- New way -->
<%= invoice_status_badge(invoice) %>
```

### Using Currency Formatter

```erb
<!-- Old way -->
<%= currency_symbol(invoice.currency) %><%= format_currency(invoice.total, invoice.currency) %>

<!-- New way -->
<%= formatted_currency_amount(invoice.total, invoice.currency) %>
```

### Reusing Company Info

```erb
<!-- In any view -->
<%= render "invoices/partials/company_info_display", user: current_user %>
```

## Next Steps

Consider extending this pattern to:

- Print pricing views
- Printer management views
- User profile sections
- Shared layout components

---

_Refactored: <%= Date.current.strftime('%B %d, %Y') %>_
