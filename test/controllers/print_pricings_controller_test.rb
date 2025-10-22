require "test_helper"

class PrintPricingsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @printer = printers(:one)
    @print_pricing = print_pricings(:one)
    sign_in @user
  end

  test "should redirect to login when not authenticated" do
    sign_out @user
    get print_pricings_url
    assert_redirected_to new_user_session_url
  end

  test "should get index" do
    get print_pricings_url
    assert_response :success
    assert_select "h3.display-5", text: /My Print Calculations/
  end

  test "should get new" do
    get new_print_pricing_url
    assert_response :success
  end

  test "should create print_pricing" do
    assert_difference("PrintPricing.count") do
      assert_difference("Plate.count") do
        post print_pricings_url, params: {
          print_pricing: {
            job_name: "New Test Job",
            plates_attributes: {
              "0" => {
                printing_time_hours: 3,
                printing_time_minutes: 45,
                filament_weight: 75.0,
                filament_type: "ABS",
                spool_price: 30.0,
                spool_weight: 1000.0,
                markup_percentage: 25.0
              }
            }
          }
        }
      end
    end

    assert_redirected_to print_pricing_url(PrintPricing.last)
  end

  test "should not create print_pricing with invalid params" do
    assert_no_difference("PrintPricing.count") do
      post print_pricings_url, params: {
        print_pricing: {
          job_name: "",
          currency: "",
          filament_type: ""
        }
      }
    end

    assert_response :unprocessable_content
  end

  test "should show print_pricing" do
    get print_pricing_url(@print_pricing)
    assert_response :success
  end

  test "should get edit" do
    get edit_print_pricing_url(@print_pricing)
    assert_response :success
  end

  test "should update print_pricing" do
    patch print_pricing_url(@print_pricing), params: {
      print_pricing: {
        job_name: "Updated Job Name",
        currency: "GBP"
      }
    }
    assert_redirected_to print_pricing_url(@print_pricing)
  end

  test "should not update print_pricing with invalid params" do
    patch print_pricing_url(@print_pricing), params: {
      print_pricing: {
        job_name: "",
        filament_weight: -1
      }
    }
    assert_response :unprocessable_content
  end

  test "should destroy print_pricing" do
    assert_difference("PrintPricing.count", -1) do
      delete print_pricing_url(@print_pricing)
    end

    assert_redirected_to print_pricings_url
  end

  test "should not access other user's print_pricing" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12,
      next_invoice_number: 1
    )
    other_printer = other_user.printers.create!(
      name: "Other Printer",
      manufacturer: "Prusa",
      power_consumption: 200,
      cost: 500,
      payoff_goal_years: 3,
      daily_usage_hours: 8,
      repair_cost_percentage: 5.0
    )
    other_pricing = other_user.print_pricings.build(
      job_name: "Other User's Print",
      printer: other_printer
    )
    other_pricing.plates.build(
      printing_time_hours: 1,
      printing_time_minutes: 0,
      filament_weight: 30.0,
      filament_type: "PLA",
      spool_price: 20.0,
      spool_weight: 1000.0,
      markup_percentage: 15.0
    )
    other_pricing.save!

    # Should return 404 because current_user.print_pricings.find won't find it
    get print_pricing_url(other_pricing)
    assert_response :not_found
  end

  test "should increment times_printed" do
    initial_count = @print_pricing.times_printed || 0
    patch increment_times_printed_print_pricing_url(@print_pricing)
    assert_redirected_to print_pricings_path
    @print_pricing.reload
    assert_equal initial_count + 1, @print_pricing.times_printed
  end

  test "should increment times_printed via turbo stream" do
    initial_count = @print_pricing.times_printed || 0
    patch increment_times_printed_print_pricing_url(@print_pricing), headers: { "Accept": "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "turbo-stream", response.body
    assert_match "times_printed_#{@print_pricing.id}", response.body
    @print_pricing.reload
    assert_equal initial_count + 1, @print_pricing.times_printed
  end

  test "should decrement times_printed" do
    @print_pricing.update!(times_printed: 5)
    patch decrement_times_printed_print_pricing_url(@print_pricing)
    assert_redirected_to print_pricings_path
    @print_pricing.reload
    assert_equal 4, @print_pricing.times_printed
  end

  test "should decrement times_printed via turbo stream" do
    @print_pricing.update!(times_printed: 5)
    patch decrement_times_printed_print_pricing_url(@print_pricing), headers: { "Accept": "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "turbo-stream", response.body
    assert_match "times_printed_#{@print_pricing.id}", response.body
    @print_pricing.reload
    assert_equal 4, @print_pricing.times_printed
  end

  test "should not decrement times_printed below zero" do
    @print_pricing.update!(times_printed: 0)
    patch decrement_times_printed_print_pricing_url(@print_pricing)
    assert_redirected_to print_pricings_path
    @print_pricing.reload
    assert_equal 0, @print_pricing.times_printed
  end

  test "should not decrement times_printed below zero via turbo stream" do
    @print_pricing.update!(times_printed: 0)
    patch decrement_times_printed_print_pricing_url(@print_pricing), headers: { "Accept": "text/vnd.turbo-stream.html" }
    assert_response :success
    assert_match "turbo-stream", response.body
    @print_pricing.reload
    assert_equal 0, @print_pricing.times_printed
  end

  test "should create print_pricing with start_with_one_print toggle" do
    assert_difference("PrintPricing.count") do
      post print_pricings_url, params: {
        print_pricing: {
          job_name: "Test Print Job",
          printer_id: @printer.id,
          start_with_one_print: "1",
          plates_attributes: {
            "0" => {
              printing_time_hours: 2,
              printing_time_minutes: 30,
              filament_weight: 35.0,
              filament_type: "PLA",
              spool_price: 25.0,
              spool_weight: 1000.0,
              markup_percentage: 20.0
            }
          }
        }
      }
    end
    assert_redirected_to print_pricing_url(PrintPricing.last)
    assert_equal 1, PrintPricing.last.times_printed
  end

  test "should create print_pricing without start_with_one_print toggle" do
    assert_difference("PrintPricing.count") do
      post print_pricings_url, params: {
        print_pricing: {
          job_name: "Test Print Job",
          printer_id: @printer.id,
          start_with_one_print: "0",
          plates_attributes: {
            "0" => {
              printing_time_hours: 2,
              printing_time_minutes: 30,
              filament_weight: 35.0,
              filament_type: "PLA",
              spool_price: 25.0,
              spool_weight: 1000.0,
              markup_percentage: 20.0
            }
          }
        }
      }
    end
    assert_redirected_to print_pricing_url(PrintPricing.last)
    assert_equal 0, PrintPricing.last.times_printed
  end

  test "should duplicate print pricing" do
    sign_in users(:one)
    original_count = PrintPricing.count

    post duplicate_print_pricing_url(@print_pricing)

    assert_redirected_to print_pricing_url(PrintPricing.last)
    assert_equal original_count + 1, PrintPricing.count

    duplicated_pricing = PrintPricing.last
    assert_equal "#{@print_pricing.job_name} (Copy)", duplicated_pricing.job_name
    assert_equal 0, duplicated_pricing.times_printed
    assert_equal @print_pricing.plates.count, duplicated_pricing.plates.count
    assert_equal users(:one), duplicated_pricing.user
  end

  test "should not duplicate other user's print pricing" do
    other_user = User.create!(
      email: "other@example.com",
      password: "password123",
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12,
      next_invoice_number: 1
    )
    sign_in other_user

    post duplicate_print_pricing_url(@print_pricing)
    assert_response :not_found
  end
end
