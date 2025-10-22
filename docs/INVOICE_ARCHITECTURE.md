# Invoice Views Architecture

## Component Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│                     INVOICE FORM                             │
│                    (_form.html.erb)                          │
└─────────────────────────────────────────────────────────────┘
                              │
                              ├── Company Info Card
                              │   └── Company Info Display
                              │       └── company_logo_url (helper)
                              │
                              ├── Invoice Details Card
                              │   ├── Invoice Number Field
                              │   │   └── Invoice Number Preview
                              │   │       └── invoice_number_preview() helper
                              │   ├── Invoice Date Fields
                              │   └── Status & Currency Fields
                              │       └── invoice_status_options() helper
                              │
                              ├── Line Items Card
                              │   ├── Line Item Fields (nested)
                              │   └── Invoice Totals
                              │       └── formatted_currency_amount() helper
                              │
                              ├── Payment & Notes Cards
                              └── Form Actions

┌─────────────────────────────────────────────────────────────┐
│                    INVOICE SHOW                              │
│                   (show.html.erb)                            │
└─────────────────────────────────────────────────────────────┘
                              │
                              ├── Show Header
                              │   └── Action Buttons
                              │
                              └── Invoice Content (printable)
                                  ├── Invoice Header
                                  │   ├── Company Section
                                  │   └── Metadata
                                  │       └── invoice_status_badge() helper
                                  │
                                  ├── Customer Info
                                  │
                                  ├── Line Items Table
                                  │   ├── Line Item Row(s)
                                  │   │   └── formatted_currency_amount() helper
                                  │   └── Line Items Footer
                                  │       └── formatted_currency_amount() helper
                                  │
                                  └── Payment & Notes Display

┌─────────────────────────────────────────────────────────────┐
│                    INVOICE INDEX                             │
│                   (index.html.erb)                           │
└─────────────────────────────────────────────────────────────┘
                              │
                              └── Table Body
                                  └── Index Table Row(s)
                                      ├── invoice_status_badge() helper
                                      └── formatted_currency_amount() helper
```

## Helper Method Dependencies

```
InvoicesHelper
│
├── Status & Badges
│   ├── invoice_status_badge(invoice, size)
│   ├── invoice_status_class(invoice)
│   └── invoice_status_badge_class(invoice)  [legacy]
│
├── Currency Formatting
│   ├── formatted_currency_amount(amount, currency)
│   └── formatted_invoice_total(invoice)
│
├── Form Helpers
│   ├── invoice_number_preview(number)
│   ├── invoice_status_options(current_status)
│   └── invoice_action_button_class(invoice, action)
│
└── Utilities
    ├── invoice_date_range(invoice)
    └── invoice_line_items_editable?(invoice)

CurrencyHelper (existing)
│
├── currency_symbol(currency)
└── format_currency(amount, currency)
```

## Data Flow: Form Submission

```
User Input
    │
    ├─→ Company Info Card ─────────→ current_user.*
    │
    ├─→ Invoice Details Card ──────→ @invoice.{invoice_number, dates, status, currency}
    │
    ├─→ Line Items Card ───────────→ @invoice.invoice_line_items_attributes[]
    │   │                             ├── description
    │   │                             ├── quantity
    │   │                             ├── unit_price
    │   │                             └── _destroy (for deletions)
    │   │
    │   └─→ [Stimulus Controller] ──→ Real-time calculations
    │       ├── calculateLineTotal()
    │       └── updateTotals()
    │
    └─→ Payment & Notes Cards ─────→ @invoice.{payment_details, notes}
```

## Reusability Matrix

| Partial                   | Used In     | Reusable? | Parameters Required      |
| ------------------------- | ----------- | --------- | ------------------------ |
| company_info_display      | Form, Show  | ✅ High   | user                     |
| invoice_status_badge      | Index, Show | ✅ High   | invoice, size (optional) |
| formatted_currency_amount | All views   | ✅ High   | amount, currency         |
| line_item_row             | Show, Email | ✅ Medium | item, currency           |
| invoice_totals            | Form, Email | ✅ Medium | invoice, currency        |
| customer_info             | Show, PDF   | ✅ Medium | customer_name            |

|

## Testing Strategy

### Unit Tests (Helper Methods)

```ruby
# test/helpers/invoices_helper_test.rb
test "invoice_status_badge returns correct class for paid" do
  invoice = invoices(:paid_invoice)
  assert_includes invoice_status_badge(invoice), "bg-success"
end

test "formatted_currency_amount formats USD correctly" do
  assert_equal "$123.45", formatted_currency_amount(123.45, "USD")
end

test "invoice_number_preview formats correctly" do
  assert_equal "INV-000042", invoice_number_preview(42)
end
```

### Integration Tests (Partials)

```ruby
# test/integration/invoice_form_test.rb
test "form renders company info partial" do
  get new_print_pricing_invoice_path(@print_pricing)
  assert_select "div.card.border-info" # company_info_card
  assert_select "img[alt='Company Logo']" if @user.company_logo.attached?
end

test "show page renders line items table" do
  get print_pricing_invoice_path(@print_pricing, @invoice)
  assert_select "table.table-bordered"
  assert_select "tbody tr", count: @invoice.invoice_line_items.count
end
```

## Performance Considerations

1. **Cached Logo URLs**: Company logos cached for 1 hour (already implemented)
2. **Partial Caching**: Consider fragment caching for invoice show page
3. **Counter Caching**: Add `invoice_line_items_count` if showing counts frequently
4. **Eager Loading**: Ensure `invoice_line_items` are eager loaded in controller

### Potential Cache Keys

```ruby
# In show.html.erb
<% cache [@invoice, @invoice.invoice_line_items.maximum(:updated_at)] do %>
  <%= render "invoices/partials/line_items_table", invoice: @invoice %>
<% end %>
```

## Future Enhancements

1. **Email Templates**: Reuse show partials for invoice emails
2. **PDF Generation**: Use show structure for PDF rendering
3. **API Responses**: Serialize using helper methods
4. **Localization**: Add more translation keys in partials
5. **Theming**: Extract CSS to component classes

---

Last Updated: October 22, 2025
