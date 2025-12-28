require "test_helper"

class OnboardingControllerTest < ActionDispatch::IntegrationTest
  setup do
    @new_user = users(:one)
    # Make user appear "new" by setting created_at to recent time
    @new_user.update!(
      created_at: 30.minutes.ago,
      onboarding_completed_at: nil,
      onboarding_current_step: 0
    )
    sign_in @new_user
  end

  test "should redirect to onboarding if not completed" do
    get root_path
    assert_redirected_to onboarding_path
  end

  test "should show welcome step for new user" do
    get onboarding_path
    assert_response :success
    assert_select "h1", text: /Welcome to CalcuMake/
  end

  test "should show specific step when provided" do
    get onboarding_path(step: "profile")
    assert_response :success
  end

  test "should redirect to current step if invalid step requested" do
    get onboarding_path(step: "invalid")
    assert_redirected_to onboarding_path(step: "welcome")
  end

  test "should update profile step" do
    @new_user.update!(onboarding_current_step: 1)

    patch onboarding_path(step: "profile"), params: {
      user: { default_currency: "USD", default_energy_cost_per_kwh: 0.12 }
    }

    assert_redirected_to onboarding_path(step: "company")
    @new_user.reload
    assert_equal "USD", @new_user.default_currency
    assert_equal 2, @new_user.onboarding_current_step
  end

  test "should update company step" do
    @new_user.update!(onboarding_current_step: 2)

    patch onboarding_path(step: "company"), params: {
      user: { default_company_name: "Test Company" }
    }

    assert_redirected_to onboarding_path(step: "printer")
    @new_user.reload
    assert_equal "Test Company", @new_user.default_company_name
    assert_equal 3, @new_user.onboarding_current_step
  end

  test "should create printer from preset" do
    @new_user.update!(onboarding_current_step: 3)

    assert_difference "@new_user.printers.count", 1 do
      patch onboarding_path(step: "printer"), params: {
        printer_model: "Prusa i3 MK4"
      }
    end

    assert_redirected_to onboarding_path(step: "filament")
    printer = @new_user.printers.last
    assert_equal "Prusa i3 MK4", printer.name
    assert_equal "Prusa", printer.manufacturer
    assert_equal 120, printer.power_consumption
  end

  test "should require printer selection" do
    @new_user.update!(onboarding_current_step: 3)

    assert_no_difference "@new_user.printers.count" do
      patch onboarding_path(step: "printer"), params: {}
    end

    assert_response :unprocessable_entity
  end

  test "should create multiple filaments" do
    @new_user.update!(onboarding_current_step: 4)

    assert_difference "@new_user.filaments.count", 2 do
      patch onboarding_path(step: "filament"), params: {
        filament_types: ["PLA", "PETG"]
      }
    end

    assert_redirected_to onboarding_path(step: "complete")
    filaments = @new_user.filaments.order(:created_at).last(2)
    assert_equal "PLA", filaments.first.name
    assert_equal "PETG", filaments.last.name
  end

  test "should require at least one filament" do
    @new_user.update!(onboarding_current_step: 4)

    assert_no_difference "@new_user.filaments.count" do
      patch onboarding_path(step: "filament"), params: {
        filament_types: []
      }
    end

    assert_response :unprocessable_entity
  end

  test "should allow skipping individual step" do
    @new_user.update!(onboarding_current_step: 2)

    post skip_step_onboarding_path

    assert_redirected_to onboarding_path(step: "printer")
    @new_user.reload
    assert_equal 3, @new_user.onboarding_current_step
  end

  test "should allow skipping entire walkthrough" do
    post skip_walkthrough_onboarding_path

    assert_redirected_to dashboard_path
    @new_user.reload
    assert_not_nil @new_user.onboarding_completed_at
    assert @new_user.onboarding_completed?
  end

  test "should complete onboarding and redirect to dashboard" do
    @new_user.update!(onboarding_current_step: 5)

    post complete_onboarding_path

    assert_redirected_to dashboard_path
    @new_user.reload
    assert_not_nil @new_user.onboarding_completed_at
    assert @new_user.onboarding_completed?
  end

  test "should not show onboarding for completed users" do
    @new_user.update!(onboarding_completed_at: 1.day.ago)

    get onboarding_path
    assert_redirected_to root_path
  end

  test "should not redirect to onboarding for old users" do
    @new_user.update!(
      created_at: 2.hours.ago,
      onboarding_completed_at: nil
    )

    get root_path
    assert_response :success # Landing page no longer auto-redirects authenticated users
  end
end
