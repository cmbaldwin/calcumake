require "test_helper"

class SetupAssistantControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
  end

  test "requires authentication" do
    post message_setup_assistant_path, params: { message: "add printer" }, as: :json
    assert_response :unauthorized
  end

  test "returns successful assistant response" do
    sign_in @user

    fake_service = Object.new
    fake_service.define_singleton_method(:call) do |message:, conversation:|
      {
        ok: true,
        message: "Created printer.",
        actions: [ { type: "create_printer", status: "success" } ],
        errors: [],
        onboarding_ready: false
      }
    end

    Ai::SetupAssistant.stub :new, ->(**_kwargs) { fake_service } do
      post message_setup_assistant_path, params: {
        message: "add printer",
        context: "app",
        onboarding_step: "printer",
        conversation: [ { role: "user", content: "hi" } ]
      }, as: :json
    end

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Created printer.", body["message"]
    assert_equal false, body["onboarding_ready"]
    assert_equal "success", body.dig("actions", 0, "status")
  end

  test "returns unprocessable status on assistant error" do
    sign_in @user

    fake_service = Object.new
    fake_service.define_singleton_method(:call) do |message:, conversation:|
      {
        ok: false,
        message: "Unavailable",
        actions: [],
        errors: [ "Unavailable" ],
        onboarding_ready: false
      }
    end

    Ai::SetupAssistant.stub :new, ->(**_kwargs) { fake_service } do
      post message_setup_assistant_path, params: { message: "help" }, as: :json
    end

    assert_response :unprocessable_entity
    body = JSON.parse(response.body)
    assert_equal "Unavailable", body["message"]
  end
end
