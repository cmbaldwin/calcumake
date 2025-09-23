require "application_system_test_case"

class InvoiceTest < ApplicationSystemTestCase
  def setup
    @user = User.create!(
      email: "invoice@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )

    @printer = @user.printers.create!(
      name: "Invoice Test Printer",
      manufacturer: "Prusa",
      power_consumption: 250,
      cost: 800,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )

    @print_pricing = @user.print_pricings.create!(
      job_name: "Test Invoice Job",
      printer: @printer,
      printing_time_hours: 2,
      printing_time_minutes: 30,
      filament_weight: 50,
      filament_type: "PLA+",
      spool_price: 25,
      spool_weight: 1000,
      markup_percentage: 20,
      prep_time_minutes: 15,
      prep_cost_per_hour: 25,
      postprocessing_time_minutes: 10,
      postprocessing_cost_per_hour: 30,
      other_costs: 2.50,
      vat_percentage: 8,
      times_printed: 2
    )
  end

  test "user can access invoice page from print pricing show page" do
    sign_in @user
    visit print_pricing_path(@print_pricing)

    # Verify invoice link is present
    assert_link "Invoice"

    # Click invoice link and verify invoice page loads
    click_link "Invoice"

    assert_current_path invoice_print_pricing_path(@print_pricing)
    assert_text "Invoice"
    assert_text "Test Invoice Job"
  end

  test "user can access invoice page from print pricings index" do
    sign_in @user
    visit print_pricings_path

    # Verify invoice link is present in the card actions
    assert_link "Invoice"

    # Click invoice link
    click_link "Invoice"

    assert_current_path invoice_print_pricing_path(@print_pricing)
    assert_text "Invoice"
  end

  test "invoice page displays all required invoice elements" do
    sign_in @user
    visit invoice_print_pricing_path(@print_pricing)

    # Header information
    assert_text "Invoice"
    assert_text "INV-#{@print_pricing.id.to_s.rjust(6, '0')}"
    assert_text @user.email
    assert_text "3D Printing Services"

    # Job details
    assert_text "Job Details"
    assert_text "Test Invoice Job"
    assert_text "PLA+"
    assert_text "50g"
    assert_text "2 hours 30 minutes"
    assert_text "Invoice Test Printer"
    assert_text "Times Printed: 2"

    # Cost breakdown table
    assert_text "Cost Breakdown"
    assert_text "Description"
    assert_text "Amount"
    assert_text "Filament Cost"
    assert_text "Electricity Cost"
    assert_text "Labor Cost"
    assert_text "Machine Upkeep"
    assert_text "Other Costs"
    assert_text "Subtotal"
    assert_text "VAT (8%)"
    assert_text "Total"

    # Footer
    assert_text "Notes"
    assert_text "Payment Information"
  end

  test "invoice page has working navigation buttons" do
    sign_in @user
    visit invoice_print_pricing_path(@print_pricing)

    # Verify action buttons are present
    assert_button "Download PDF"
    assert_button "Print"
    assert_link "Back"

    # Test back button
    click_link "Back"
    assert_current_path print_pricing_path(@print_pricing)

    # Go back to invoice for other tests
    visit invoice_print_pricing_path(@print_pricing)

    # Test print button (should trigger browser print dialog)
    # We can't fully test this in automated tests, but we can verify the button exists
    assert_button "Print"
  end

  test "PDF generation controller is connected and configured" do
    sign_in @user
    visit invoice_print_pricing_path(@print_pricing)

    # Verify the PDF generator controller is properly attached
    pdf_container = find(".invoice-container")
    assert pdf_container["data-controller"] == "pdf-generator"
    assert pdf_container["data-pdf-generator-filename-value"] == "test-invoice-job-invoice"

    # Verify PDF generation button has correct action
    pdf_button = find("button", text: "Download PDF")
    assert pdf_button["data-action"] == "click->pdf-generator#generatePDF"
  end

  test "invoice content is properly structured for PDF generation" do
    sign_in @user
    visit invoice_print_pricing_path(@print_pricing)

    # Verify the invoice content container exists for PDF generation
    assert_selector ".invoice-content"

    # Verify key elements for PDF capture
    within ".invoice-content" do
      assert_text "Invoice"
      assert_text "Test Invoice Job"
      assert_selector "table" # Cost breakdown table
      assert_text "Total"
    end

    # Verify actions are hidden from print (d-print-none class)
    actions_container = find(".invoice-actions")
    assert actions_container[:class].include?("d-print-none")
  end

  test "invoice calculates and displays costs correctly" do
    sign_in @user
    visit invoice_print_pricing_path(@print_pricing)

    # Verify final price is displayed (calculated by the model)
    final_price = @print_pricing.final_price
    assert_text "$#{sprintf('%.2f', final_price)}"

    # Verify individual cost components are shown
    filament_cost = @print_pricing.total_filament_cost
    assert_text sprintf("%.2f", filament_cost) if filament_cost > 0

    electricity_cost = @print_pricing.total_electricity_cost
    assert_text sprintf("%.2f", electricity_cost) if electricity_cost > 0

    labor_cost = @print_pricing.total_labor_cost
    assert_text sprintf("%.2f", labor_cost) if labor_cost > 0

    machine_cost = @print_pricing.total_machine_upkeep_cost
    assert_text sprintf("%.2f", machine_cost) if machine_cost > 0
  end

  test "invoice handles pricing without printer gracefully" do
    # Create print pricing without printer
    pricing_without_printer = @user.print_pricings.create!(
      job_name: "No Printer Job",
      printing_time_hours: 1,
      printing_time_minutes: 0,
      filament_weight: 25,
      filament_type: "PLA",
      spool_price: 20,
      spool_weight: 1000,
      markup_percentage: 15
    )

    sign_in @user
    visit invoice_print_pricing_path(pricing_without_printer)

    # Should display job details without printer information
    assert_text "No Printer Job"
    assert_text "PLA"
    assert_no_text "Printer:"

    # Should still show cost breakdown
    assert_text "Cost Breakdown"
    assert_text "Filament Cost"
  end

  test "invoice shows proper currency formatting" do
    sign_in @user
    visit invoice_print_pricing_path(@print_pricing)

    # All monetary amounts should be properly formatted with currency
    within ".cost-breakdown" do
      # Check that dollar signs are present for USD currency
      assert_text "$"

      # Verify amounts are formatted to 2 decimal places
      page_content = page.text
      amounts = page_content.scan(/\$\d+\.\d{2}/)
      assert amounts.length > 0, "Should find properly formatted currency amounts"
    end
  end

  test "PDF generation elements have correct data attributes for JavaScript" do
    sign_in @user
    visit invoice_print_pricing_path(@print_pricing)

    # Verify Stimulus data attributes
    container = find('[data-controller="pdf-generator"]')
    assert_not_nil container

    # Verify filename value is properly parameterized
    expected_filename = @print_pricing.job_name.parameterize + "-invoice"
    assert_equal expected_filename, container["data-pdf-generator-filename-value"]

    # Verify PDF button has correct action binding
    pdf_button = find('[data-action="click->pdf-generator#generatePDF"]')
    assert_not_nil pdf_button
    assert_equal "Download PDF", pdf_button.text.strip
  end
end
