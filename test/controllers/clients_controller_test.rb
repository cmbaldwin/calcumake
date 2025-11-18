require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    sign_in @user
    @client = clients(:one)
  end

  test "should get index" do
    get clients_url
    assert_response :success
  end

  test "should get show" do
    get client_url(@client)
    assert_response :success
  end

  test "should get new" do
    get new_client_url
    assert_response :success
  end

  test "should get edit" do
    get edit_client_url(@client)
    assert_response :success
  end

  # Modal functionality tests
  test "should get new as turbo_stream for modal" do
    get new_client_url, as: :turbo_stream
    assert_response :success
    assert_match(/turbo-stream/, response.body)
    assert_match(/modal_content/, response.body)
    assert_match(/client/, response.body)
  end

  test "should create client via turbo_stream for modal" do
    assert_difference("Client.count") do
      post clients_url, params: {
        client: {
          name: "Modal Test Client",
          email: "modal@test.com"
        }
      }, as: :turbo_stream
    end
    assert_response :success
    assert_match(/turbo-stream/, response.body)
    # Should clear modal_content and close modal
    assert_match(/modal_content/, response.body)
    # Should show success flash message
    assert_match(/flash/, response.body)
  end

  test "should render errors in modal on create failure" do
    assert_no_difference("Client.count") do
      post clients_url, params: {
        client: {
          name: "",  # Invalid: name is required
          email: "test@test.com"
        }
      }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
    assert_match(/modal_content/, response.body)
    # Should show error messages within modal
    assert_match(/can&#39;t be blank|is required/i, response.body)
  end

  test "should load client form with all sections in modal" do
    get new_client_url, as: :turbo_stream
    assert_response :success
    # Check for form sections
    assert_match(/Basic Information|Contact Information|Additional Information/, response.body)
    assert_match(/name/i, response.body)
    assert_match(/email/i, response.body)
  end
end
