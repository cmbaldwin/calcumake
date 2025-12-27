# frozen_string_literal: true

require "test_helper"

class ApiTokensControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @other_user = users(:two)
    @active_token = api_tokens(:active_token)
    @other_user_token = api_tokens(:other_user_token)
    sign_in @user
  end

  # Authentication tests
  test "should require authentication for index" do
    sign_out @user
    get api_tokens_url
    assert_redirected_to new_user_session_url
  end

  test "should require authentication for new" do
    sign_out @user
    get new_api_token_url
    assert_redirected_to new_user_session_url
  end

  test "should require authentication for create" do
    sign_out @user
    post api_tokens_url, params: { api_token: { name: "Test" } }
    assert_redirected_to new_user_session_url
  end

  test "should require authentication for destroy" do
    sign_out @user
    delete api_token_url(@active_token)
    assert_redirected_to new_user_session_url
  end

  # Index tests
  test "should get index" do
    get api_tokens_url
    assert_response :success
    assert_select "h1", text: /API Tokens/i
  end

  test "index should show only current user tokens" do
    get api_tokens_url
    assert_response :success

    # Should include user's tokens
    assert_match @active_token.name, response.body

    # Should not include other user's tokens
    assert_no_match(/#{@other_user_token.name}/, response.body)
  end

  test "index should show empty state when no tokens" do
    @user.api_tokens.destroy_all
    get api_tokens_url
    assert_response :success
    assert_match(/No API tokens yet/i, response.body)
  end

  # New tests
  test "should get new" do
    get new_api_token_url
    assert_response :success
    assert_select "form[action=?]", api_tokens_path
  end

  test "new should show expiration options" do
    get new_api_token_url
    assert_response :success
    assert_select "select[name='api_token[expiration]']"
    assert_match(/30 days/i, response.body)
    assert_match(/90 days/i, response.body)
    assert_match(/1 year/i, response.body)
    assert_match(/Never expires/i, response.body)
  end

  # Create tests
  test "should create api_token" do
    assert_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: { name: "New Test Token", expiration: "90_days" }
      }
    end
    assert_redirected_to api_tokens_path
    assert_match(/API token created successfully/i, flash[:notice])
  end

  test "should create api_token with default expiration" do
    assert_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: { name: "Default Expiration Token" }
      }
    end

    token = ApiToken.last
    assert token.expires_at.present?
    assert token.expires_at > 80.days.from_now # ~90 days
    assert token.expires_at < 100.days.from_now
  end

  test "should create api_token with never expires option" do
    assert_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: { name: "Never Expires Token", expiration: "never" }
      }
    end

    token = ApiToken.last
    assert_nil token.expires_at
    assert token.never_expires?
  end

  test "should create api_token with 30 day expiration" do
    assert_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: { name: "30 Day Token", expiration: "30_days" }
      }
    end

    token = ApiToken.last
    assert token.expires_at.present?
    assert token.expires_at > 25.days.from_now
    assert token.expires_at < 35.days.from_now
  end

  test "should create api_token with 1 year expiration" do
    assert_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: { name: "1 Year Token", expiration: "1_year" }
      }
    end

    token = ApiToken.last
    assert token.expires_at.present?
    assert token.expires_at > 360.days.from_now
    assert token.expires_at < 370.days.from_now
  end

  test "should record client info on create" do
    post api_tokens_url, params: {
      api_token: { name: "Client Info Token" }
    }, headers: { "User-Agent" => "Test Browser/1.0" }

    token = ApiToken.last
    assert token.created_from_ip.present?, "Expected created_from_ip to be present"
    assert token.user_agent.present?, "Expected user_agent to be present"
    assert_equal "Test Browser/1.0", token.user_agent
  end

  test "should not create api_token with blank name" do
    assert_no_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: { name: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "should not create api_token with name too long" do
    assert_no_difference("ApiToken.count") do
      post api_tokens_url, params: {
        api_token: { name: "a" * 101 }
      }
    end
    assert_response :unprocessable_entity
  end

  # Creation flow stores token in session for one-time display
  test "should store plain token in session on create" do
    post api_tokens_url, params: {
      api_token: { name: "Session Token" }
    }

    assert session[:new_api_token_plain].present?
    assert session[:new_api_token_plain].start_with?("cm_")
    assert session[:new_api_token_id].present?
  end

  test "should render errors in form on create failure" do
    post api_tokens_url, params: {
      api_token: { name: "" }
    }

    assert_response :unprocessable_entity
    assert_match(/can&#39;t be blank|is required/i, response.body)
  end

  # Destroy tests
  test "should revoke api_token" do
    assert @active_token.active?

    delete api_token_url(@active_token)

    @active_token.reload
    assert @active_token.revoked?
    assert_redirected_to user_profile_path(anchor: "api-tokens")
    assert_match(/API token has been revoked/i, flash[:notice])
  end

  test "should not destroy other user token" do
    # The controller scopes by current_user so other user's token won't be found
    # This should raise RecordNotFound which Rails converts to 404
    delete api_token_url(@other_user_token)
    assert_response :not_found
  end

  # Destroy with turbo_stream tests
  test "should revoke api_token via turbo_stream" do
    delete api_token_url(@active_token), as: :turbo_stream

    assert_response :success
    assert_match(/turbo-stream/, response.body)

    @active_token.reload
    assert @active_token.revoked?
  end

  test "should update token card to show revoked status via turbo_stream" do
    delete api_token_url(@active_token), as: :turbo_stream

    assert_response :success
    # Should replace the token card
    assert_match(/api_token_#{@active_token.id}/, response.body)
  end

  # Data isolation tests
  test "tokens should be isolated between users" do
    user_1_count = @user.api_tokens.count
    user_2_count = @other_user.api_tokens.count

    # Create token for user 1
    post api_tokens_url, params: { api_token: { name: "User 1 Token" } }

    assert_equal user_1_count + 1, @user.api_tokens.reload.count
    assert_equal user_2_count, @other_user.api_tokens.reload.count
  end
end
