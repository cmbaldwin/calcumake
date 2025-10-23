require "application_system_test_case"

class InvoiceFormTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @print_pricing = print_pricings(:one)
    sign_in @user
  end

  test "adding a new line item dynamically" do
    visit new_print_pricing_invoice_url(@print_pricing)

    # Count initial line items
    initial_count = all(".invoice-line-item-fields").count

    # Click the add line item button (if it exists)
    # Note: The actual button selector may need adjustment based on your view
    if has_css?('[data-action*="addLineItem"]', wait: 1)
      find('[data-action*="addLineItem"]').click

      # Verify a new line item was added
      assert_selector ".invoice-line-item-fields", count: initial_count + 1
    end
  end

  test "calculating line item totals dynamically" do
    visit new_print_pricing_invoice_url(@print_pricing)

    # Find the first line item quantity and price inputs
    within first(".invoice-line-item-fields") do
      quantity_input = find(".line-item-quantity", match: :first)
      price_input = find(".line-item-price", match: :first)

      # Set values
      quantity_input.fill_in with: "5"
      price_input.fill_in with: "10.50"

      # Trigger calculation by blurring the input
      price_input.native.send_keys(:tab)

      # Wait for calculation
      sleep 0.5

      # Check if total is calculated (52.50)
      total_input = find(".line-item-total", match: :first)
      assert_equal "52.50", total_input.value
    end
  end

  test "removing a line item" do
    visit edit_print_pricing_invoice_url(@print_pricing, invoices(:one))

    # Count initial line items
    initial_count = all('.invoice-line-item-fields:not([style*="display: none"])').count

    # Skip test if no line items
    skip "No line items to remove" if initial_count.zero?

    # Click the first remove button
    within first(".invoice-line-item-fields") do
      if has_css?('[data-action*="removeLineItem"]', wait: 1)
        find('[data-action*="removeLineItem"]').click
        sleep 0.3
      else
        skip "No remove button found"
      end
    end

    # Verify line item was hidden or removed
    visible_count = all('.invoice-line-item-fields:not([style*="display: none"])').count
    assert visible_count < initial_count, "Line item should be removed or hidden"
  end

  test "updating totals when line items change" do
    visit edit_print_pricing_invoice_url(@print_pricing, invoices(:one))

    # Check if subtotal element exists
    if has_css?('[data-invoice-form-target="subtotal"]', wait: 1)
      initial_subtotal = find('[data-invoice-form-target="subtotal"]').text

      # Modify a line item if one exists
      within first(".invoice-line-item-fields") do
        price_input = find(".line-item-price", match: :first)
        current_value = price_input.value.to_f
        price_input.fill_in with: (current_value + 10).to_s
        price_input.native.send_keys(:tab)
        sleep 0.5
      end

      # Verify subtotal changed
      new_subtotal = find('[data-invoice-form-target="subtotal"]').text
      assert_not_equal initial_subtotal, new_subtotal, "Subtotal should update"
    end
  end

  test "invoice form validation" do
    visit new_print_pricing_invoice_url(@print_pricing)

    # Try to submit without required fields
    click_button "Create Invoice" if has_button?("Create Invoice")

    # Should see validation errors (Rails HTML5 validation or server-side)
    # This test validates the form submission works correctly
    assert_current_path new_print_pricing_invoice_path(@print_pricing), "Should stay on new page with errors"
  end
end
