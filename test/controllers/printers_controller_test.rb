require "test_helper"

class PrintersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @printer = printers(:one)
    sign_in @user
  end

  test "should get index" do
    get printers_url
    assert_response :success
  end

  test "should get new" do
    get new_printer_url
    assert_response :success
  end

  test "should create printer" do
    assert_difference("Printer.count") do
      post printers_url, params: {
        printer: {
          name: "Test Printer",
          manufacturer: "Prusa",
          power_consumption: 200,
          cost: 500,
          payoff_goal_years: 3
        }
      }
    end
    assert_redirected_to printer_url(Printer.last)
  end

  test "should show printer" do
    get printer_url(@printer)
    assert_response :success
  end

  test "should get edit" do
    get edit_printer_url(@printer)
    assert_response :success
  end

  test "should update printer" do
    patch printer_url(@printer), params: {
      printer: {
        name: "Updated Printer Name",
        power_consumption: 250
      }
    }
    assert_redirected_to printer_url(@printer)
    @printer.reload
    assert_equal "Updated Printer Name", @printer.name
  end

  test "should destroy printer" do
    assert_difference("Printer.count", -1) do
      delete printer_url(@printer)
    end
    assert_redirected_to printers_url
  end

  test "should require authentication" do
    sign_out @user
    get printers_url
    assert_redirected_to new_user_session_url
  end

  # Modal functionality tests
  test "should get new as turbo_stream for modal" do
    get new_printer_url, as: :turbo_stream
    assert_response :success
    assert_match(/turbo-stream/, response.body)
    assert_match(/modal/, response.body)
  end

  test "should create printer via turbo_stream for modal" do
    assert_difference("Printer.count") do
      post printers_url, params: {
        printer: {
          name: "Modal Test Printer",
          manufacturer: "Prusa",
          power_consumption: 200,
          cost: 500,
          payoff_goal_years: 3
        }
      }, as: :turbo_stream
    end
    assert_response :success
    assert_match(/turbo-stream/, response.body)
  end

  test "should render errors in modal on create failure" do
    assert_no_difference("Printer.count") do
      post printers_url, params: {
        printer: {
          name: "",  # Invalid: name is required
          manufacturer: "Prusa"
        }
      }, as: :turbo_stream
    end
    assert_response :unprocessable_content
    assert_match(/modal/, response.body)
  end
end
