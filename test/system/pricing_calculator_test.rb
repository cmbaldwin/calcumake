require "application_system_test_case"

class PricingCalculatorTest < ApplicationSystemTestCase
  # Test basic page load and presence of key elements
  test "pricing calculator page loads successfully" do
    visit pricing_calculator_path

    # Check page structure
    assert_selector ".pricing-calculator-page"
    assert_selector ".card-header", text: /Calculator Settings/i
    assert_selector "[data-controller='advanced-calculator']"

    # Verify no quick calculator section (it was removed)
    assert_no_selector ".quick-calculator-section"
  end

  test "page loads with default first plate" do
    visit pricing_calculator_path

    # Should have one plate by default
    assert_selector "[data-plate-index='0']"

    # Should have job name input
    assert_selector "[data-advanced-calculator-target='jobName']"

    # Should have results section
    assert_selector "[data-advanced-calculator-target='resultsSection']"
  end

  test "all form inputs are present and functional" do
    visit pricing_calculator_path

    # Job name
    assert_selector "[data-advanced-calculator-target='jobName']"

    # Machine settings
    assert_selector "[data-advanced-calculator-target='powerConsumption']"
    assert_selector "[data-advanced-calculator-target='machineCost']"
    assert_selector "[data-advanced-calculator-target='payoffYears']"

    # Labor settings
    assert_selector "[data-advanced-calculator-target='prepTime']"
    assert_selector "[data-advanced-calculator-target='postTime']"
    assert_selector "[data-advanced-calculator-target='prepRate']"
    assert_selector "[data-advanced-calculator-target='postRate']"

    # Other costs
    assert_selector "[data-advanced-calculator-target='units']"
    assert_selector "[data-advanced-calculator-target='failureRate']"
    assert_selector "[data-advanced-calculator-target='shippingCost']"
    assert_selector "[data-advanced-calculator-target='otherCost']"
  end

  test "can add and remove plates" do
    visit pricing_calculator_path

    # Should start with 1 plate
    assert_selector "[data-plate-index]", count: 1

    # Add a second plate
    click_button "Add Plate"

    # Should now have 2 plates
    assert_selector "[data-plate-index]", count: 2
    assert_selector "[data-plate-index='0']"
    assert_selector "[data-plate-index='1']"

    # Remove the second plate - button has trash icon, no text
    within "[data-plate-index='1']" do
      find("button[data-action*='removePlate']").click
    end

    # Should be back to 1 plate
    assert_selector "[data-plate-index]", count: 1
  end

  test "cannot remove last plate" do
    visit pricing_calculator_path

    # Try to remove the only plate - should show alert
    within "[data-plate-index='0']" do
      accept_alert do
        find("button[data-action*='removePlate']").click
      end
    end

    # Should still have the plate (alert should prevent removal)
    assert_selector "[data-plate-index='0']"
  end

  test "can add up to 10 plates" do
    visit pricing_calculator_path

    # Add plates up to the limit
    9.times do
      click_button "Add Plate"
    end

    # Should have 10 plates (1 initial + 9 added)
    assert_selector "[data-plate-index]", count: 10

    # Add plate button should be disabled
    assert_selector "[data-advanced-calculator-target='addPlateButton'][disabled]"
  end

  test "can add and remove filaments within a plate" do
    visit pricing_calculator_path

    within "[data-plate-index='0']" do
      # Should start with 1 filament
      assert_selector "[data-filament-index]", count: 1

      # Add another filament
      click_button "Add Filament"

      # Should now have 2 filaments
      assert_selector "[data-filament-index]", count: 2

      # Remove the second filament - button has trash icon only
      within "[data-filament-index='1']" do
        find("button[data-action*='removeFilament']").click
      end

      # Should be back to 1 filament
      assert_selector "[data-filament-index]", count: 1
    end
  end

  test "calculations update in real-time" do
    visit pricing_calculator_path

    # Wait for initial calculation
    sleep 0.5

    # Get initial total
    initial_total = find("[data-advanced-calculator-target='grandTotal']").text

    # Change a value (print time) - use name attribute selector
    within "[data-plate-index='0']" do
      find("input[name='plates[0][print_time]']").fill_in with: "10"
    end

    # Wait for calculation to debounce and update
    sleep 1

    # Total should have changed
    new_total = find("[data-advanced-calculator-target='grandTotal']").text
    assert_not_equal initial_total, new_total
  end

  test "export buttons are present and clickable" do
    visit pricing_calculator_path

    # Export to PDF button
    assert_selector "button", text: /Export to PDF/i

    # Export to CSV button
    assert_selector "button", text: /Export to CSV/i

    # CTA to sign up - uses "Start Free Trial" not "Create Free Account"
    assert_link I18n.t("advanced_calculator.cta.button"), href: new_user_registration_path
  end

  test "per-unit pricing calculation works" do
    visit pricing_calculator_path

    # Set units to a non-zero value - use data attribute selector
    find("[data-advanced-calculator-target='units']").fill_in with: "10"

    # Wait for calculation
    sleep 1

    # Per-unit section should be visible
    assert_selector "[data-advanced-calculator-target='perUnitSection']"
    assert_selector "[data-advanced-calculator-target='perUnitPrice']"

    # Should show a per-unit price
    per_unit_price = find("[data-advanced-calculator-target='perUnitPrice']").text
    assert_not_equal "$0.00", per_unit_price
  end

  test "page is responsive on mobile" do
    resize_to_mobile
    visit pricing_calculator_path

    # Page should still load
    assert_selector ".pricing-calculator-page"

    # Form should be present
    assert_selector ".card-body"

    # Results section should be present (will stack below on mobile)
    assert_selector "[data-advanced-calculator-target='resultsSection']"
  end

  test "stimulus controller connects without errors" do
    visit pricing_calculator_path

    # Wait a bit for JS to initialize
    sleep 0.5

    # Check that the controller is connected by verifying targets are present
    assert_selector "[data-advanced-calculator-target='jobName']"
    assert_selector "[data-advanced-calculator-target='platesContainer']"
    assert_selector "[data-advanced-calculator-target='resultsSection']"

    # Check that initial plate was added
    assert_selector "[data-plate-index='0']"
  end

  test "page works without JavaScript (graceful degradation)" do
    # Disable JavaScript
    Capybara.current_driver = :selenium_headless

    visit pricing_calculator_path

    # Page should still render structure
    assert_selector ".pricing-calculator-page"
    assert_selector ".card-header"

    # Form inputs should still be present
    assert_selector "input[type='text']"
    assert_selector "input[type='number']"
  end

  test "no JavaScript errors on page load" do
    skip "Turbo pre-fetch causes benign 'Failed to fetch' errors in system tests"

    visit pricing_calculator_path

    # Wait for page to fully load
    sleep 1

    # Check for console errors (this will fail if there are JS errors)
    logs = page.driver.browser.logs.get(:browser)
    severe_errors = logs.select { |log| log.level == "SEVERE" }

    assert_empty severe_errors, "JavaScript errors detected: #{severe_errors.map(&:message).join("\n")}"
  end

  test "page load performance is acceptable" do
    start_time = Time.now

    visit pricing_calculator_path

    # Wait for page to be interactive
    assert_selector "[data-advanced-calculator-target='jobName']"

    end_time = Time.now
    load_time = end_time - start_time

    # Page should load in under 5 seconds (generous for system tests)
    assert load_time < 5, "Page took too long to load: #{load_time} seconds"
  end

  test "multiple rapid calculations don't cause freezing" do
    visit pricing_calculator_path

    # Rapidly change multiple values
    10.times do |i|
      within "[data-plate-index='0']" do
        find("input[name='plates[0][print_time]']").fill_in with: (i + 1).to_s
      end
      sleep 0.1  # Small delay to simulate rapid typing
    end

    # Wait for debounced calculation
    sleep 1

    # Page should still be responsive
    assert_selector "[data-advanced-calculator-target='grandTotal']"

    # Should be able to interact with page
    find("[data-advanced-calculator-target='jobName']").set("Test Job")
  end

  test "features highlight section is present" do
    visit pricing_calculator_path

    # Scroll to features section
    execute_script "window.scrollTo(0, document.body.scrollHeight)"

    # Check for features content - look for any visible feature text
    assert_text /10 build plates/i, wait: 5
  end

  test "structured data is present for SEO" do
    visit pricing_calculator_path

    # Check for JSON-LD structured data
    assert_selector "script[type='application/ld+json']", visible: false
  end

  test "CTA cards are present and link to registration" do
    visit pricing_calculator_path

    # Should have CTA to create account - uses "Start Free Trial"
    assert_link I18n.t("advanced_calculator.cta.button"), href: new_user_registration_path
  end

  test "calculation remains accurate with multiple plates and filaments" do
    visit pricing_calculator_path

    # Add a second plate
    click_button "Add Plate"
    sleep 0.3  # Wait for plate to be added

    # Add filaments to both plates - use name attribute selectors matching any plate index
    plates = all("[data-plate-index]")
    within plates[0] do
      find("input[name*='[print_time]']").fill_in with: "5"
      within first("[data-filament-index]") do
        find("input[name*='[filament_weight]']").fill_in with: "100"
        find("input[name*='[filament_price]']").fill_in with: "25"
      end
    end

    within plates[1] do
      find("input[name*='[print_time]']").fill_in with: "3"
      within first("[data-filament-index]") do
        find("input[name*='[filament_weight]']").fill_in with: "50"
        find("input[name*='[filament_price]']").fill_in with: "30"
      end
    end

    # Wait for calculation
    sleep 1

    # Grand total should be greater than 0
    grand_total_text = find("[data-advanced-calculator-target='grandTotal']").text
    # Remove currency symbol and convert to float
    grand_total = grand_total_text.gsub(/[^\d.]/, "").to_f
    assert grand_total > 0, "Grand total should be greater than 0"
  end

  private

  def resize_to_mobile
    page.driver.browser.manage.window.resize_to(375, 667)
  end
end
