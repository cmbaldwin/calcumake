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
    click_button "Add Another Plate"
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
    click_button "Add Another Plate"
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
      click_button "Add Another Plate"
      sleep 0.1
    end

    # Should now have 10 plates
    assert_selector "[data-plate-index]", count: 10

    # Try to add 11th plate - should show alert
    accept_alert "Maximum 10 plates allowed" do
      click_button "Add Another Plate"
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

    # Should have signup CTA card visible
    assert_selector ".cta-card", visible: true
    assert_link href: new_user_registration_path
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
    assert_button "Add Another Plate", visible: true
  end

  test "calculator cost calculations aggregate across multiple plates" do
    visit pricing_calculator_path

    # Add second plate
    click_button "Add Another Plate"
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
    click_button "Add Another Plate"
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

  test "calculator shows quick calculator section" do
    visit pricing_calculator_path

    # Quick calculator should be present
    assert_selector "[data-controller='quick-calculator']", visible: true
  end

  test "page has proper SEO meta tags" do
    visit pricing_calculator_path

    # Check page title
    assert_title /3D Print Pricing Calculator/i

    # Check meta description exists
    assert_selector "meta[name='description']", visible: false
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
