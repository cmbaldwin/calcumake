require "test_helper"

class SubscriptionsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get pricing page" do
    get pricing_subscriptions_url
    assert_response :success
    assert_select "h1", text: I18n.t("subscriptions.title")
  end

  test "pricing page shows current plan and usage stats" do
    get pricing_subscriptions_url
    assert_response :success

    # Should show usage stats for free/startup users
    assert_select ".card" if @user.free_plan? || @user.startup_plan?
  end

  test "should redirect unauthenticated users from pricing" do
    sign_out @user
    get pricing_subscriptions_url
    assert_redirected_to new_user_session_url
  end

  # Checkout Session Tests
  test "should create checkout session for valid plan" do
    # Mock Stripe customer creation
    stub_request(:post, "https://api.stripe.com/v1/customers")
      .to_return(
        status: 200,
        body: { id: "cus_test123", email: @user.email }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock Stripe checkout session creation
    stub_request(:post, "https://api.stripe.com/v1/checkout/sessions")
      .to_return(
        status: 200,
        body: {
          id: "cs_test123",
          url: "https://checkout.stripe.com/pay/cs_test123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    post create_checkout_session_subscriptions_url, params: { plan: "startup" }
    assert_response :redirect
    assert_match(/^https:\/\/checkout.stripe.com/, response.redirect_url)
  end

  test "should reject invalid plan" do
    post create_checkout_session_subscriptions_url, params: { plan: "invalid" }
    assert_redirected_to pricing_subscriptions_url
    assert_equal I18n.t("subscriptions.invalid_plan"), flash[:alert]
  end

  test "should prevent duplicate subscription for active subscription" do
    # Setup: User already has active subscription
    @user.update!(
      stripe_subscription_id: "sub_test123",
      plan: "startup"
    )

    # Mock Stripe subscription retrieval - active subscription
    stub_request(:get, "https://api.stripe.com/v1/subscriptions/sub_test123")
      .to_return(
        status: 200,
        body: {
          id: "sub_test123",
          status: "active",
          customer: "cus_test123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    post create_checkout_session_subscriptions_url, params: { plan: "pro" }

    assert_redirected_to pricing_subscriptions_url
    assert_equal I18n.t("subscriptions.already_subscribed"), flash[:alert]
  end

  test "should prevent duplicate subscription for trialing subscription" do
    # Setup: User has trialing subscription
    @user.update!(
      stripe_subscription_id: "sub_trial123",
      plan: "startup"
    )

    # Mock Stripe subscription retrieval - trialing subscription
    stub_request(:get, "https://api.stripe.com/v1/subscriptions/sub_trial123")
      .to_return(
        status: 200,
        body: {
          id: "sub_trial123",
          status: "trialing",
          customer: "cus_test123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    post create_checkout_session_subscriptions_url, params: { plan: "pro" }

    assert_redirected_to pricing_subscriptions_url
    assert_equal I18n.t("subscriptions.already_subscribed"), flash[:alert]
  end

  test "should allow new subscription if previous was canceled" do
    # Setup: User has subscription ID but it's canceled in Stripe
    @user.update!(
      stripe_subscription_id: "sub_canceled123",
      plan: "free"
    )

    # Mock Stripe subscription retrieval - canceled subscription
    stub_request(:get, "https://api.stripe.com/v1/subscriptions/sub_canceled123")
      .to_return(
        status: 200,
        body: {
          id: "sub_canceled123",
          status: "canceled",
          customer: "cus_test123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock customer and session creation
    stub_request(:post, "https://api.stripe.com/v1/customers")
      .to_return(
        status: 200,
        body: { id: "cus_test456", email: @user.email }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:post, "https://api.stripe.com/v1/checkout/sessions")
      .to_return(
        status: 200,
        body: {
          id: "cs_new123",
          url: "https://checkout.stripe.com/pay/cs_new123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    post create_checkout_session_subscriptions_url, params: { plan: "startup" }

    # Should allow creating new subscription
    assert_response :redirect
    assert_match(/^https:\/\/checkout.stripe.com/, response.redirect_url)
  end

  test "should allow new subscription if previous subscription not found in Stripe" do
    # Setup: User has subscription ID but it doesn't exist in Stripe
    @user.update!(
      stripe_subscription_id: "sub_nonexistent123",
      plan: "free"
    )

    # Mock Stripe subscription retrieval - not found (404)
    stub_request(:get, "https://api.stripe.com/v1/subscriptions/sub_nonexistent123")
      .to_return(
        status: 404,
        body: {
          error: {
            type: "invalid_request_error",
            message: "No such subscription"
          }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock customer and session creation
    stub_request(:post, "https://api.stripe.com/v1/customers")
      .to_return(
        status: 200,
        body: { id: "cus_test789", email: @user.email }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    stub_request(:post, "https://api.stripe.com/v1/checkout/sessions")
      .to_return(
        status: 200,
        body: {
          id: "cs_recover123",
          url: "https://checkout.stripe.com/pay/cs_recover123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    post create_checkout_session_subscriptions_url, params: { plan: "startup" }

    # Should allow creating new subscription
    assert_response :redirect
    assert_match(/^https:\/\/checkout.stripe.com/, response.redirect_url)
  end

  # Success Callback Tests
  test "should handle successful checkout" do
    # Mock Stripe checkout session retrieval
    stub_request(:get, %r{https://api.stripe.com/v1/checkout/sessions/cs_test_success123})
      .to_return(
        status: 200,
        body: {
          id: "cs_test_success123",
          subscription: "sub_new123",
          customer: "cus_test123",
          metadata: { plan: "startup", user_id: @user.id.to_s }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Mock Stripe subscription retrieval
    stub_request(:get, "https://api.stripe.com/v1/subscriptions/sub_new123")
      .to_return(
        status: 200,
        body: {
          id: "sub_new123",
          current_period_end: 1.month.from_now.to_i,
          status: "active"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get success_subscriptions_url, params: { session_id: "cs_test_success123" }

    assert_redirected_to root_path
    assert_match(/successfully upgraded/i, flash[:notice])
  end

  # Subscription Management Tests
  test "should redirect to billing portal for existing customer" do
    @user.update!(stripe_customer_id: "cus_test123")

    # Mock Stripe billing portal session creation
    stub_request(:post, "https://api.stripe.com/v1/billing_portal/sessions")
      .to_return(
        status: 200,
        body: {
          id: "bps_test123",
          url: "https://billing.stripe.com/session/bps_test123"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    get manage_subscriptions_url

    assert_response :redirect
    assert_match(/^https:\/\/billing.stripe.com/, response.redirect_url)
  end

  test "should reject manage request without customer ID" do
    @user.update!(stripe_customer_id: nil)

    get manage_subscriptions_url

    assert_redirected_to pricing_subscriptions_url
    assert_equal I18n.t("subscriptions.no_subscription"), flash[:alert]
  end

  # Subscription Cancellation Tests
  test "should cancel subscription at period end" do
    @user.update!(stripe_subscription_id: "sub_test123")

    # Mock Stripe subscription update (cancel at period end)
    stub_request(:post, "https://api.stripe.com/v1/subscriptions/sub_test123")
      .to_return(
        status: 200,
        body: {
          id: "sub_test123",
          cancel_at_period_end: true,
          status: "active"
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    post cancel_subscriptions_url

    assert_redirected_to pricing_subscriptions_url
    assert_equal I18n.t("subscriptions.cancel_scheduled"), flash[:notice]
  end

  test "should reject cancel request without subscription" do
    @user.update!(stripe_subscription_id: nil)

    post cancel_subscriptions_url

    assert_redirected_to pricing_subscriptions_url
    assert_equal I18n.t("subscriptions.no_subscription"), flash[:alert]
  end
end
