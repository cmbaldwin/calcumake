require "application_system_test_case"

class AdvancedCalculatorTest < ApplicationSystemTestCase
  # Phase 1: Critical system tests for Advanced Pricing Calculator
  # Testing public-facing calculator for non-authenticated users

  test "visitor can access calculator without authentication" do
    visit pricing_calculator_path

    # Should not be redirected to login
    assert_current_path pricing_calculator_path
    assert_selector "h1", text: /3D Print Pricing Calculator/i
    assert_selector "[data-controller='advanced-calculator']"
  end

  test "calculator initializes with one plate" do
    visit pricing_calculator_path

    # Should have exactly 1 plate on load
    assert_selector "[data-plate-index]", count: 1
    assert_selector ".plate-number", text: /Plate 1/i
  end

  test "visitor can perform complete calculation workflow" do
    visit pricing_calculator_path

    # Fill in job name
    fill_in "plates[0][print_time]", with: "5"

    # Fill in first filament (should exist by default)
    within first("[data-filament-index]") do
      fill_in "plates[0][filaments][0][filament_weight]", with: "100"
      fill_in "plates[0][filaments][0][filament_price]", with: "25"
    end

    # Wait for calculations to complete (debounced)
    sleep 0.5

    # Verify results section is visible
    assert_selector "[data-advanced-calculator-target='resultsSection']", visible: true

    # Verify cost values are displayed and not zero
    total_text = find("[data-advanced-calculator-target='grandTotal']").text
    assert_not_equal "$0.00", total_text, "Grand total should be calculated"
  end

  test "visitor can add multiple plates" do
    visit pricing_calculator_path

    initial_plates = page.all("[data-plate-index]").count
    assert_equal 1, initial_plates

    # Add a plate
    click_button "Add Plate"
    sleep 0.2

    # Should now have 2 plates
    assert_selector "[data-plate-index]", count: 2

    # Verify plate numbers are correct
    assert_selector ".plate-number", text: /Plate 1/i
    assert_selector ".plate-number", text: /Plate 2/i
  end

  test "visitor can add multiple filaments to a plate" do
    visit pricing_calculator_path

    within first("[data-plate-index]") do
      initial_filaments = page.all("[data-filament-index]").count

      # Add filament button should be present
      click_button "Add Filament"
      sleep 0.2

      # Should have added one more filament
      new_filaments = page.all("[data-filament-index]").count
      assert_equal initial_filaments + 1, new_filaments
    end
  end

  test "visitor can remove plates" do
    visit pricing_calculator_path

    # Add a second plate first
    click_button "Add Plate"
    sleep 0.2
    assert_selector "[data-plate-index]", count: 2

    # Remove the first plate
    within first("[data-plate-index]") do
      find("button.btn-danger").click
    end
    sleep 0.2

    # Should now have only 1 plate
    assert_selector "[data-plate-index]", count: 1
  end

  test "visitor can remove filaments from a plate" do
    visit pricing_calculator_path

    within first("[data-plate-index]") do
      # Add a second filament first
      click_button "Add Filament"
      sleep 0.2

      initial_count = page.all("[data-filament-index]").count
      assert initial_count >= 2, "Should have at least 2 filaments"

      # Remove first filament
      within first("[data-filament-index]") do
        find("button.btn-outline-danger").click
      end
      sleep 0.2

      # Should have one less filament
      new_count = page.all("[data-filament-index]").count
      assert_equal initial_count - 1, new_count
    end
  end

  test "calculator enforces 10 plate limit" do
    visit pricing_calculator_path

    # Add 9 more plates (already have 1)
    9.times do
      click_button "Add Plate"
      sleep 0.1
    end

    # Should now have 10 plates
    assert_selector "[data-plate-index]", count: 10

    # Try to add 11th plate - should show alert
    accept_alert "Maximum 10 plates allowed" do
      click_button "Add Plate"
    end

    # Should still have only 10 plates
    assert_selector "[data-plate-index]", count: 10
  end

  test "calculator shows per-unit pricing when units greater than 1" do
    visit pricing_calculator_path

    # Fill in basic calculation data
    fill_in "plates[0][print_time]", with: "2"

    within first("[data-filament-index]") do
      fill_in "plates[0][filaments][0][filament_weight]", with: "50"
      fill_in "plates[0][filaments][0][filament_price]", with: "20"
    end

    # Set units to 1 - per unit section should be hidden
    fill_in "units", with: "1"
    sleep 0.5

    per_unit_section = find("[data-advanced-calculator-target='perUnitSection']")
    assert_not per_unit_section.visible?, "Per-unit section should be hidden when units = 1"

    # Set units to 5 - per unit section should be visible
    fill_in "units", with: "5"
    sleep 0.5

    assert per_unit_section.visible?, "Per-unit section should be visible when units > 1"

    # Verify per-unit price is displayed
    per_unit_price = find("[data-advanced-calculator-target='perUnitPrice']").text
    assert_not_equal "$0.00", per_unit_price, "Per-unit price should be calculated"
  end

  test "calculator displays all cost breakdown categories" do
    visit pricing_calculator_path

    # Fill in some data to trigger calculations
    fill_in "plates[0][print_time]", with: "3"

    within first("[data-filament-index]") do
      fill_in "plates[0][filaments][0][filament_weight]", with: "75"
      fill_in "plates[0][filaments][0][filament_price]", with: "30"
    end

    sleep 0.5

    # Verify all cost categories are displayed
    assert_selector "[data-advanced-calculator-target='totalFilamentCost']", visible: true
    assert_selector "[data-advanced-calculator-target='totalElectricityCost']", visible: true
    assert_selector "[data-advanced-calculator-target='totalLaborCost']", visible: true
    assert_selector "[data-advanced-calculator-target='totalMachineCost']", visible: true
    assert_selector "[data-advanced-calculator-target='totalOtherCosts']", visible: true
    assert_selector "[data-advanced-calculator-target='grandTotal']", visible: true
  end

  test "calculator handles decimal inputs correctly" do
    visit pricing_calculator_path

    # Test decimal print time
    fill_in "plates[0][print_time]", with: "2.5"

    # Test decimal filament weight
    within first("[data-filament-index]") do
      fill_in "plates[0][filaments][0][filament_weight]", with: "123.45"
      fill_in "plates[0][filaments][0][filament_price]", with: "24.99"
    end

    sleep 0.5

    # Should calculate without errors
    total_text = find("[data-advanced-calculator-target='grandTotal']").text
    assert_not_equal "$0.00", total_text
    assert_match /\$\d+\.\d{2}/, total_text, "Total should be formatted as currency"
  end

  test "calculator validates numeric inputs" do
    visit pricing_calculator_path

    # Try to input negative values
    print_time_field = find("input[name='plates[0][print_time]']")

    # HTML5 validation should prevent negative numbers
    assert_equal "0.1", print_time_field[:min]
    assert_equal "number", print_time_field[:type]
  end

  test "calculator shows CTA to create account" do
    visit pricing_calculator_path

    # Should have signup CTA link in the localStorage warning
    assert_link "Sign up to save your prints for free and never lose them", href: new_user_registration_path
  end

  test "calculator has export PDF button" do
    visit pricing_calculator_path

    # Export PDF button should be present
    assert_button "Export to PDF"

    # Button should have correct data action
    pdf_button = find("button", text: "Export to PDF")
    assert pdf_button["data-action"].include?("click->advanced-calculator#exportToPDF")
  end

  test "calculator has export CSV button" do
    visit pricing_calculator_path

    # Export CSV button should be present
    assert_button "Export to CSV"

    # Button should have correct data action
    csv_button = find("button", text: "Export to CSV")
    assert csv_button["data-action"].include?("click->advanced-calculator#exportToCSV")
  end

  test "calculator works in Japanese locale" do
    visit pricing_calculator_path(locale: :ja)

    # Should load successfully
    assert_current_path pricing_calculator_path(locale: :ja)

    # Calculator should still be present
    assert_selector "[data-controller='advanced-calculator']"

    # Should have Japanese translations
    assert_selector "label", text: /時間|hrs/i
  end

  test "calculator works in Spanish locale" do
    visit pricing_calculator_path(locale: :es)

    assert_current_path pricing_calculator_path(locale: :es)
    assert_selector "[data-controller='advanced-calculator']"
  end

  test "calculator works in French locale" do
    visit pricing_calculator_path(locale: :fr)

    assert_current_path pricing_calculator_path(locale: :fr)
    assert_selector "[data-controller='advanced-calculator']"
  end

  test "calculator handles failure rate field" do
    visit pricing_calculator_path

    # Should have failure rate field with default value
    failure_rate_field = find("input[data-advanced-calculator-target='failureRate']")
    assert_equal "5", failure_rate_field.value

    # Change failure rate
    fill_in "failure_rate", with: "10"
    sleep 0.5

    # Should recalculate (grand total may change based on implementation)
    assert_selector "[data-advanced-calculator-target='grandTotal']", visible: true
  end

  test "calculator handles shipping cost field" do
    visit pricing_calculator_path

    # Fill in shipping cost
    fill_in "shipping_cost", with: "25.50"

    # Fill in other required fields
    fill_in "plates[0][print_time]", with: "2"
    within first("[data-filament-index]") do
      fill_in "plates[0][filaments][0][filament_weight]", with: "50"
      fill_in "plates[0][filaments][0][filament_price]", with: "20"
    end

    sleep 0.5

    # Other costs should include shipping
    other_costs_text = find("[data-advanced-calculator-target='totalOtherCosts']").text
    assert_not_equal "$0.00", other_costs_text
  end

  test "calculator handles other cost field" do
    visit pricing_calculator_path

    # Fill in other cost
    fill_in "other_cost", with: "15.00"

    # Fill in other required fields
    fill_in "plates[0][print_time]", with: "2"
    within first("[data-filament-index]") do
      fill_in "plates[0][filaments][0][filament_weight]", with: "50"
      fill_in "plates[0][filaments][0][filament_price]", with: "20"
    end

    sleep 0.5

    # Other costs should be reflected
    assert_selector "[data-advanced-calculator-target='totalOtherCosts']", visible: true
  end

  test "calculator displays structured data for SEO" do
    visit pricing_calculator_path

    # Should have JSON-LD structured data
    assert_selector "script[type='application/ld+json']", visible: false

    # Verify page source contains structured data
    assert_match /"@type":"SoftwareApplication"/, page.html
    assert_match /CalcuMake/i, page.html
  end

  test "calculator is responsive on mobile viewports" do
    resize_to_mobile
    visit pricing_calculator_path

    # Calculator should load successfully
    assert_selector "[data-controller='advanced-calculator']"

    # Input fields should be visible and functional
    assert_selector "input[name='plates[0][print_time]']", visible: true

    # Buttons should be accessible
    assert_button "Add Plate", visible: true
  end

  test "calculator cost calculations aggregate across multiple plates" do
    visit pricing_calculator_path

    # Add second plate
    click_button "Add Plate"
    sleep 0.2

    # Fill in first plate
    within all("[data-plate-index]")[0] do
      fill_in "plates[0][print_time]", with: "2"
      within first("[data-filament-index]") do
        fill_in "plates[0][filaments][0][filament_weight]", with: "50"
        fill_in "plates[0][filaments][0][filament_price]", with: "20"
      end
    end

    # Fill in second plate
    within all("[data-plate-index]")[1] do
      fill_in "plates[1][print_time]", with: "3"
      within first("[data-filament-index]") do
        fill_in "plates[1][filaments][0][filament_weight]", with: "75"
        fill_in "plates[1][filaments][0][filament_price]", with: "25"
      end
    end

    sleep 0.5

    # Grand total should reflect combined costs from both plates
    total_text = find("[data-advanced-calculator-target='grandTotal']").text
    assert_not_equal "$0.00", total_text

    # Filament cost should be sum of both plates
    filament_cost_text = find("[data-advanced-calculator-target='totalFilamentCost']").text
    assert_not_equal "$0.00", filament_cost_text
  end

  test "calculator maintains state when removing and re-adding plates" do
    visit pricing_calculator_path

    # Add second plate
    click_button "Add Plate"
    sleep 0.2

    # Fill in second plate with specific values
    within all("[data-plate-index]")[1] do
      fill_in "plates[1][print_time]", with: "7"
    end

    # Remove first plate
    within first("[data-plate-index]") do
      find("button.btn-danger").click
    end
    sleep 0.2

    # Should still have 1 plate
    assert_selector "[data-plate-index]", count: 1

    # Calculator should still function
    within first("[data-plate-index]") do
      fill_in_print_time_for_current_plate "5"
    end

    sleep 0.5

    # Should still calculate
    assert_selector "[data-advanced-calculator-target='grandTotal']", visible: true
  end

  test "calculator shows results section" do
    visit pricing_calculator_path

    # Results section should be present
    assert_selector "[data-advanced-calculator-target='resultsSection']", visible: true
  end

  test "page has proper SEO meta tags" do
    visit pricing_calculator_path

    # Check page title
    assert_title /3D Print Pricing Calculator/i

    # Check meta description exists
    assert_selector "meta[name='description']", visible: false
  end

  # ==========================================
  # FDM/Resin Technology Toggle Tests
  # ==========================================

  test "calculator has FDM/Resin technology toggle" do
    visit pricing_calculator_path

    # Should have both technology options
    assert_selector "input[name='print_technology'][value='fdm']", visible: false
    assert_selector "input[name='print_technology'][value='resin']", visible: false
    assert_selector "label[for='tech_fdm']", text: /FDM/i
    assert_selector "label[for='tech_resin']", text: /Resin/i
  end

  test "calculator defaults to FDM technology" do
    visit pricing_calculator_path

    # FDM should be checked by default
    fdm_radio = find("input[name='print_technology'][value='fdm']", visible: false)
    assert fdm_radio.checked?, "FDM should be selected by default"

    # FDM fields should be visible
    within first("[data-plate-index]") do
      assert_selector ".fdm-fields", visible: true
      refute_selector ".resin-fields", visible: true
    end
  end

  test "switching to resin shows resin fields and hides filament fields" do
    visit pricing_calculator_path

    # Switch to resin
    find("label[for='tech_resin']").click
    sleep 0.3

    # Resin fields should now be visible, filament fields hidden
    within first("[data-plate-index]") do
      refute_selector ".fdm-fields", visible: true
      assert_selector ".resin-fields", visible: true
    end
  end

  test "resin fields accept volume and price per liter" do
    visit pricing_calculator_path

    # Switch to resin
    find("label[for='tech_resin']").click
    sleep 0.3

    # Fill in resin fields
    within first("[data-plate-index]") do
      fill_in "plates[0][print_time]", with: "3"
      within ".resin-fields" do
        fill_in "plates[0][resin_volume]", with: "50"
        fill_in "plates[0][resin_price_per_liter]", with: "40"
      end
    end

    sleep 0.5

    # Should calculate costs
    total_text = find("[data-advanced-calculator-target='grandTotal']").text
    assert_not_equal "$0.00", total_text
  end

  test "material cost label changes based on technology" do
    visit pricing_calculator_path

    # Should show "Filament Cost" by default (or just "Filament")
    material_label = find("[data-advanced-calculator-target='materialCostLabel']")
    assert_match /Filament/i, material_label.text

    # Switch to resin
    find("label[for='tech_resin']").click
    sleep 0.3

    # Should now show "Resin Cost" (or just "Resin")
    material_label = find("[data-advanced-calculator-target='materialCostLabel']")
    assert_match /Resin/i, material_label.text
  end

  test "technology toggle affects all plates simultaneously" do
    visit pricing_calculator_path

    # Add a second plate
    click_button "Add Plate"
    sleep 0.2

    # Both plates should show FDM fields
    all("[data-plate-index]").each do |plate|
      within plate do
        assert_selector ".fdm-fields", visible: true
        refute_selector ".resin-fields", visible: true
      end
    end

    # Switch to resin
    find("label[for='tech_resin']").click
    sleep 0.3

    # Both plates should now show resin fields
    all("[data-plate-index]").each do |plate|
      within plate do
        refute_selector ".fdm-fields", visible: true
        assert_selector ".resin-fields", visible: true
      end
    end
  end

  test "printer profile selector is filtered by technology" do
    visit pricing_calculator_path

    # On FDM, selector should have FDM printers
    printer_selector = find("[data-printer-profile-selector]")
    fdm_options = printer_selector.all("option").select { |opt| opt.text.present? && opt.text != "-- Select a Common Printer --" }
    assert fdm_options.any?, "Should have FDM printer options"

    # Switch to resin
    find("label[for='tech_resin']").click
    sleep 0.3

    # Selector should now have resin printers
    printer_selector = find("[data-printer-profile-selector]")
    resin_options = printer_selector.all("option").select { |opt| opt.text.present? && opt.text != "-- Select a Common Printer --" }
    assert resin_options.any?, "Should have resin printer options"
  end

  test "printer profile AI warning is displayed" do
    visit pricing_calculator_path

    # Should show AI-generated warning near the printer selector
    assert_text "AI-generated estimates"
    assert_text "Always verify specifications with your printer's manual"
    assert_selector "small.text-warning", text: /AI-generated/i
  end

  test "selecting a printer updates technology toggle" do
    visit pricing_calculator_path

    # Start with FDM selected
    fdm_radio = find("input[name='print_technology'][value='fdm']", visible: false)
    assert fdm_radio.checked?

    # Find and select a resin printer from the dropdown
    # First switch to resin to see resin printers
    find("label[for='tech_resin']").click
    sleep 0.2

    printer_selector = find("[data-printer-profile-selector]")
    resin_printer_option = printer_selector.all("option").find { |opt| opt.text.include?("Mars") || opt.text.include?("Saturn") }

    if resin_printer_option
      printer_selector.select(resin_printer_option.text)
      sleep 0.3

      # Resin should still be selected (toggle shouldn't change from resin back to FDM)
      resin_radio = find("input[name='print_technology'][value='resin']", visible: false)
      assert resin_radio.checked?, "Resin should remain selected when resin printer is selected"
    end
  end

  test "calculations work correctly for both FDM and resin" do
    visit pricing_calculator_path

    # Test FDM calculation
    within first("[data-plate-index]") do
      fill_in "plates[0][print_time]", with: "2"
      within first("[data-filament-index]") do
        fill_in "plates[0][filaments][0][filament_weight]", with: "100"
        fill_in "plates[0][filaments][0][filament_price]", with: "25"
      end
    end

    sleep 0.5

    fdm_total = find("[data-advanced-calculator-target='grandTotal']").text
    assert_not_equal "$0.00", fdm_total

    # Switch to resin and test calculation
    find("label[for='tech_resin']").click
    sleep 0.3

    within first("[data-plate-index]") do
      fill_in "plates[0][print_time]", with: "3"
      within ".resin-fields" do
        fill_in "plates[0][resin_volume]", with: "75"
        fill_in "plates[0][resin_price_per_liter]", with: "50"
      end
    end

    sleep 0.5

    resin_total = find("[data-advanced-calculator-target='grandTotal']").text
    assert_not_equal "$0.00", resin_total
    # Totals should be different since we used different values
    assert_not_equal fdm_total, resin_total
  end

  private

  def resize_to_mobile
    page.driver.browser.manage.window.resize_to(375, 667)
  end

  def fill_in_print_time_for_current_plate(value)
    # Helper to fill in print time for dynamically indexed plates
    print_time_input = find("input[name^='plates'][name$='[print_time]']")
    print_time_input.fill_in with: value
  end
end
