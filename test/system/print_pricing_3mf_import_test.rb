require "application_system_test_case"

class PrintPricing3mfImportTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in @user
    assert_current_path print_pricings_path  # Wait for redirect to complete

    @printer = @user.printers.first || @user.printers.create!(
      name: "Test Printer",
      power_watts: 100,
      purchase_price: 20000,
      cost: 20000,
      payoff_goal_years: 3,
      daily_usage_hours: 8
    )

    @filament = @user.filaments.first || @user.filaments.create!(
      name: "PLA White",
      material_type: "PLA",
      price_per_kg: 2500
    )
  end

  test "new print pricing form has 3MF file upload section" do
    visit new_print_pricing_path

    # Should see 3MF import section
    assert_selector "h5", text: I18n.t('print_pricing.three_mf.import_title')

    # Should have file input
    assert_selector "input[type='file'][accept='.3mf']"

    # Should have help text
    assert_text I18n.t('print_pricing.three_mf.help_text')
  end

  test "user can upload 3MF file when creating print pricing" do
    visit new_print_pricing_path

    # Fill in basic fields
    fill_in I18n.t("activerecord.attributes.print_pricing.job_name"),
            with: "3MF Upload Test"
    select @printer.name,
           from: I18n.t("print_pricing.fields.select_printer")

    # Fill in required plate/filament fields
    find("input[name*='[printing_time_hours]']", match: :first).fill_in with: "1"
    find("input[name*='[printing_time_minutes]']", match: :first).fill_in with: "0"

    filament_select = find("select[name*='[plate_filaments_attributes]'][name$='[filament_id]']", match: :first)
    filament_select.find("option", text: @filament.display_name).select_option
    find("input[name*='[plate_filaments_attributes]'][name$='[filament_weight]']", match: :first).fill_in with: "10"

    # Attach 3MF file
    file_path = Rails.root.join("test/fixtures/files/sample_fdm.3mf")
    attach_file I18n.t("print_pricing.three_mf.file_label"), file_path

    # Submit form
    click_button I18n.t("print_pricing.buttons.calculate_save")

    # Should see success message
    assert_text I18n.t("print_pricing.created")

    # Get the created pricing
    print_pricing = PrintPricing.last

    # Verify file was attached
    assert print_pricing.three_mf_file.attached?, "3MF file should be attached"

    # Visit edit page to see import status
    visit edit_print_pricing_path(print_pricing)

    # Should see pending import status
    assert_selector ".alert", text: I18n.t("print_pricing.three_mf.status.pending")
  end

  test "edit form shows 3MF file status when file is attached" do
    # Create print pricing with attached file
    print_pricing = @user.print_pricings.build(
      job_name: "Test Job",
      printer: @printer,
      units: 1
    )

    plate = print_pricing.plates.build(
      printing_time_hours: 0,
      printing_time_minutes: 0
    )

    plate.plate_filaments.build(
      filament: @filament,
      filament_weight: 1
    )

    print_pricing.save!

    # Attach file
    file_path = Rails.root.join("test/fixtures/files/sample_fdm.3mf")
    print_pricing.three_mf_file.attach(
      io: File.open(file_path),
      filename: "sample_fdm.3mf",
      content_type: "application/x-3mf"
    )

    visit edit_print_pricing_path(print_pricing)

    # Should see file attachment status
    assert_selector ".alert", text: I18n.t('print_pricing.three_mf.status.pending')

    # Should see file size (human readable)
    assert_text "KB" # Human-readable size

    # Should have download button
    assert_link I18n.t('print_pricing.three_mf.download')
  end

  test "shows completed status after successful import" do
    print_pricing = @user.print_pricings.build(
      job_name: "Completed Import Test",
      printer: @printer,
      units: 1
    )

    plate = print_pricing.plates.build(
      printing_time_hours: 2,
      printing_time_minutes: 30,
      material_technology: "fdm"
    )

    plate.plate_filaments.build(
      filament: @filament,
      filament_weight: 50
    )

    print_pricing.save!

    # Simulate completed import
    print_pricing.update_columns(
      three_mf_import_status: "completed",
      three_mf_import_error: nil
    )

    visit edit_print_pricing_path(print_pricing)

    # Should see success status
    assert_selector ".alert-success",
                    text: I18n.t('print_pricing.three_mf.status.completed')
    assert_selector "i.bi-check-circle-fill"
  end

  test "shows failed status with error message" do
    print_pricing = @user.print_pricings.build(
      job_name: "Failed Import Test",
      printer: @printer,
      units: 1
    )

    plate = print_pricing.plates.build(
      printing_time_hours: 0,
      printing_time_minutes: 0
    )

    plate.plate_filaments.build(
      filament: @filament,
      filament_weight: 1
    )

    print_pricing.save!

    # Simulate failed import
    print_pricing.update_columns(
      three_mf_import_status: "failed",
      three_mf_import_error: "Invalid 3MF file format"
    )

    visit edit_print_pricing_path(print_pricing)

    # Should see error status
    assert_selector ".alert-danger",
                    text: I18n.t('print_pricing.three_mf.status.failed')
    assert_selector "i.bi-x-circle-fill"
    assert_text "Invalid 3MF file format"
  end

  test "shows processing status with spinner" do
    print_pricing = @user.print_pricings.build(
      job_name: "Processing Test",
      printer: @printer,
      units: 1
    )

    plate = print_pricing.plates.build(
      printing_time_hours: 0,
      printing_time_minutes: 0
    )

    plate.plate_filaments.build(
      filament: @filament,
      filament_weight: 1
    )

    print_pricing.save!

    # Simulate processing state
    print_pricing.update_column(:three_mf_import_status, "processing")

    visit edit_print_pricing_path(print_pricing)

    # Should see processing status
    assert_selector ".alert-info",
                    text: I18n.t('print_pricing.three_mf.status.processing')
    assert_selector ".spinner-border"
  end
end
