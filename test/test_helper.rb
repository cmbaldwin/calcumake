ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "webmock/minitest"

# Configure WebMock to stub external API calls
WebMock.disable_net_connect!(allow_localhost: true)

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Add more helper methods to be used by all tests here...

    # Helper to stub successful Stripe customer creation
    def stub_stripe_customer_create(email:, customer_id: "cus_test123")
      stub_request(:post, "https://api.stripe.com/v1/customers")
        .to_return(
          status: 200,
          body: {
            id: customer_id,
            object: "customer",
            email: email,
            metadata: {}
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    # Helper to stub successful Stripe checkout session creation
    def stub_stripe_checkout_create(session_id: "cs_test123", customer_id: "cus_test123")
      stub_request(:post, "https://api.stripe.com/v1/checkout/sessions")
        .to_return(
          status: 200,
          body: {
            id: session_id,
            object: "checkout.session",
            customer: customer_id,
            url: "https://checkout.stripe.com/test_session"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    # Helper to stub Stripe checkout session retrieval
    def stub_stripe_checkout_retrieve(session_id:, subscription_id: "sub_test123", customer_id: "cus_test123", plan: "startup")
      stub_request(:get, "https://api.stripe.com/v1/checkout/sessions/#{session_id}")
        .to_return(
          status: 200,
          body: {
            id: session_id,
            object: "checkout.session",
            customer: customer_id,
            subscription: subscription_id,
            metadata: { plan: plan }
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end

    # Helper to stub Stripe subscription retrieval
    def stub_stripe_subscription_retrieve(subscription_id:, current_period_end: 30.days.from_now.to_i)
      stub_request(:get, "https://api.stripe.com/v1/subscriptions/#{subscription_id}")
        .to_return(
          status: 200,
          body: {
            id: subscription_id,
            object: "subscription",
            current_period_end: current_period_end,
            status: "active"
          }.to_json,
          headers: { "Content-Type" => "application/json" }
        )
    end
  end
end

class ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
end
