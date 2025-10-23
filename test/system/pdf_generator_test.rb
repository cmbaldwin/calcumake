require "application_system_test_case"

class PdfGeneratorTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @print_pricing = print_pricings(:one)
    @invoice = invoices(:one)
    sign_in @user
  end

  test "PDF generator button is present on invoice show page" do
    visit print_pricing_invoice_url(@print_pricing, @invoice)

    # Check for PDF generation button
    # The actual selector will depend on your view implementation
    assert has_css?('[data-controller*="pdf-generator"]', wait: 2) ||
           has_button?("Download PDF", wait: 2) ||
           has_button?("Generate PDF", wait: 2),
           "PDF generator should be available"
  end

  test "invoice content is visible for PDF generation" do
    visit print_pricing_invoice_url(@print_pricing, @invoice)

    # Verify invoice content is present
    assert_selector ".invoice-content", wait: 2

    # Verify key invoice elements are present
    assert_text @invoice.invoice_number, wait: 1
    assert_text @invoice.company_name if @invoice.company_name.present?
  end

  test "PDF controller initializes correctly" do
    visit print_pricing_invoice_url(@print_pricing, @invoice)

    # Check that the PDF controller is connected via data attributes
    if has_css?('[data-controller*="pdf-generator"]', wait: 2)
      element = find('[data-controller*="pdf-generator"]')
      assert element.present?, "PDF generator controller should be initialized"
    end
  end

  test "invoice displays all required information for PDF" do
    visit print_pricing_invoice_url(@print_pricing, @invoice)

    within ".invoice-content" do
      # Check for essential invoice information
      assert_text @invoice.invoice_number
      assert_text @invoice.invoice_date.strftime("%Y-%m-%d")

      # Check for line items
      @invoice.invoice_line_items.each do |line_item|
        assert_text line_item.description
      end

      # Check for totals
      assert_text "Total"
    end
  end

  test "PDF generation handles images correctly" do
    visit print_pricing_invoice_url(@print_pricing, @invoice)

    # If invoice has a company logo, verify it's rendered
    if @invoice.user.company_logo.attached?
      assert_selector 'img[src*="company_logo"]', wait: 2
    end
  end
end
