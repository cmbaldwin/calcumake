require "test_helper"

class RailsAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin_user = User.create!(
      email: "test_admin@example.com",
      password: "test_password",
      admin: true,
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )
    @regular_user = User.create!(
      email: "test_user@example.com",
      password: "test_password",
      admin: false,
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12
    )
  end

  test "rails admin requires authentication" do
    get "/admin"
    assert_redirected_to "http://www.example.com/users/sign_in"
  end

  # TODO: Fix the model mapping issue when non-admin users access Rails Admin
  # test "rails admin requires admin privileges" do
  #   sign_in @regular_user
  #   # The authorize_with block should redirect before Rails Admin tries to map models
  #   get "/admin"
  #   assert_redirected_to "http://www.example.com/"
  # end

  # TODO: Fix the model mapping issue when accessing Rails Admin with users
  # test "rails admin allows access for admin users" do
  #   sign_in @admin_user
  #   get "/admin"
  #   assert_response :success
  #   assert_includes response.body, "Dashboard"
  # end

  test "rails admin css is accessible via asset pipeline" do
    css_path = ActionController::Base.helpers.asset_path("rails_admin.css")
    get css_path
    assert_response :success
    assert_match /text\/css/, response.content_type
  end
end
