require "test_helper"

class AiChatControllerTest < ActionDispatch::IntegrationTest
  test "returns error for empty message" do
    post ai_chat_path,
         params: { message: "" },
         headers: { "Accept" => "application/json", "Content-Type" => "application/json" },
         as: :json
    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "returns error for blank message" do
    post ai_chat_path,
         params: { message: "   " },
         headers: { "Accept" => "application/json", "Content-Type" => "application/json" },
         as: :json
    assert_response :unprocessable_entity
  end

  test "handles missing API key gracefully" do
    # In test env, API key is not set, so we get a fallback response
    post ai_chat_path,
         params: { message: "How much does PLA cost?" },
         headers: { "Accept" => "application/json", "Content-Type" => "application/json" },
         as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json["response"].present?
  end

  test "rate limits after max requests for anonymous users" do
    11.times do |i|
      post ai_chat_path,
           params: { message: "test #{i}" },
           headers: { "Accept" => "application/json", "Content-Type" => "application/json" },
           as: :json
    end
    # 11th request should be rate limited
    assert_response :too_many_requests
    json = JSON.parse(response.body)
    assert json["error"].present?
  end

  test "authenticated users get higher rate limit" do
    user = users(:one)
    sign_in user

    11.times do |i|
      post ai_chat_path,
           params: { message: "test #{i}" },
           headers: { "Accept" => "application/json", "Content-Type" => "application/json" },
           as: :json
    end
    # Should NOT be rate limited (limit is 50 for authenticated)
    assert_response :success
  end

  test "returns valid JSON response format" do
    post ai_chat_path,
         params: { message: "What is PLA?" },
         headers: { "Accept" => "application/json", "Content-Type" => "application/json" },
         as: :json
    assert_response :success
    json = JSON.parse(response.body)
    assert json.key?("response")
    assert_kind_of String, json["response"]
  end

  private

  def sign_in(user)
    post user_session_path, params: {
      user: {
        email: user.email,
        password: "password123"
      }
    }
  end
end
