require "test_helper"

class AnalyticsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @pro_user = users(:one)
    @pro_user.update!(plan: "pro")

    @free_user = users(:two)
    @free_user.update!(plan: "free")

    @admin_user = users(:three)
    @admin_user.update!(admin: true)
  end

  # Authorization Tests

  test "Pro user can access analytics page" do
    sign_in @pro_user

    get analytics_url
    assert_response :success
    assert_select "h1", text: /Analytics/i
  end

  test "Admin user can access analytics page" do
    sign_in @admin_user

    get analytics_url
    assert_response :success
    assert_select "h1", text: /Analytics/i
  end

  test "Free user is redirected to pricing page" do
    sign_in @free_user

    get analytics_url
    assert_redirected_to subscriptions_pricing_path
    follow_redirect!
    assert_match /Pro plan/i, response.body
  end

  test "Unauthenticated user is redirected to sign in" do
    get analytics_url
    assert_redirected_to new_user_session_path
  end

  # Tab Navigation Tests

  test "displays overview tab by default" do
    sign_in @pro_user

    get analytics_url
    assert_response :success
    assert_select ".nav-link.active", text: /Overview/i
  end

  test "can navigate to printers tab" do
    sign_in @pro_user

    get analytics_url, params: { tab: "printers" }
    assert_response :success
    assert_select ".nav-link.active", text: /Printers/i
  end

  test "can navigate to clients tab" do
    sign_in @pro_user

    get analytics_url, params: { tab: "clients" }
    assert_response :success
    assert_select ".nav-link.active", text: /Clients/i
  end

  test "can navigate to materials tab" do
    sign_in @pro_user

    get analytics_url, params: { tab: "materials" }
    assert_response :success
    assert_select ".nav-link.active", text: /Materials/i
  end

  # Date Range Tests

  test "accepts start_date and end_date parameters" do
    sign_in @pro_user

    start_date = 30.days.ago.to_date
    end_date = Date.current

    get analytics_url, params: { start_date: start_date, end_date: end_date }
    assert_response :success

    # Verify dates are parsed correctly
    assert_equal start_date, assigns(:start_date)
    assert_equal end_date, assigns(:end_date)
  end

  test "uses default date range when no params provided" do
    sign_in @pro_user

    get analytics_url
    assert_response :success

    assert_equal 30.days.ago.to_date, assigns(:start_date)
    assert_equal Date.current, assigns(:end_date)
  end

  test "loads analytics service for overview tab" do
    sign_in @pro_user

    get analytics_url, params: { tab: "overview" }
    assert_response :success

    analytics = assigns(:analytics)
    assert_not_nil analytics
    assert_instance_of Analytics::OverviewStats, analytics
  end

  test "loads printer analytics service for printers tab" do
    sign_in @pro_user

    get analytics_url, params: { tab: "printers" }
    assert_response :success

    printer_analytics = assigns(:printer_analytics)
    assert_not_nil printer_analytics
    assert_instance_of Analytics::PrinterStats, printer_analytics
  end

  test "loads client analytics service for clients tab" do
    sign_in @pro_user

    get analytics_url, params: { tab: "clients" }
    assert_response :success

    client_analytics = assigns(:client_analytics)
    assert_not_nil client_analytics
    assert_instance_of Analytics::ClientStats, client_analytics
  end

  test "loads material analytics service for materials tab" do
    sign_in @pro_user

    get analytics_url, params: { tab: "materials" }
    assert_response :success

    material_analytics = assigns(:material_analytics)
    assert_not_nil material_analytics
    assert_instance_of Analytics::MaterialStats, material_analytics
  end

  # Content Tests

  test "overview tab displays key metrics" do
    sign_in @pro_user

    # Create some data
    create_test_print_pricing(@pro_user)

    get analytics_url, params: { tab: "overview" }
    assert_response :success

    # Should display revenue, prints, calculations, profit cards
    assert_select ".card", minimum: 4
  end

  test "printers tab displays printer statistics" do
    sign_in @pro_user

    get analytics_url, params: { tab: "printers" }
    assert_response :success

    # Should display utilization, ROI, cost per print sections
    assert_select "h5", text: /Usage by Printer/i
    assert_select "h5", text: /ROI Progress/i
  end

  test "clients tab displays client rankings" do
    sign_in @pro_user

    get analytics_url, params: { tab: "clients" }
    assert_response :success

    # Should display top clients sections
    assert_select "h5", text: /Top Clients by Revenue/i
    assert_select "h5", text: /Top Clients by Profitability/i
  end

  test "materials tab displays material usage" do
    sign_in @pro_user

    get analytics_url, params: { tab: "materials" }
    assert_response :success

    # Should display material cost sections
    assert_select "h5", text: /Cost Breakdown/i
    assert_select "h5", text: /Top Filaments/i
  end

  # Turbo Frame Tests

  test "responds to turbo frame requests" do
    sign_in @pro_user

    get analytics_url, params: { tab: "printers" }, headers: { "Turbo-Frame" => "analytics_content" }
    assert_response :success
  end

  private

  def create_test_print_pricing(user)
    pricing = user.print_pricings.create!(
      job_name: "Test Job",
      final_price: 100,
      times_printed: 2,
      printer: printers(:one)
    )

    plate = pricing.plates.create!(
      printing_time_hours: 2,
      printing_time_minutes: 30,
      material_technology: "fdm"
    )

    plate.plate_filaments.create!(
      filament: filaments(:one),
      filament_weight: 50.0
    )

    pricing
  end
end
