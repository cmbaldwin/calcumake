require "test_helper"

class UserProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    sign_in @user
  end

  test "should get show" do
    get user_profile_url
    assert_response :success
  end

  test "should get edit" do
    get edit_user_profile_url
    assert_response :success
  end

  test "should update user profile" do
    patch user_profile_url, params: { 
      user: { 
        default_currency: 'EUR', 
        default_energy_cost_per_kwh: 0.15 
      } 
    }
    assert_redirected_to user_profile_url
    @user.reload
    assert_equal 'EUR', @user.default_currency
    assert_equal 0.15, @user.default_energy_cost_per_kwh.to_f
  end

  test "should require authentication" do
    sign_out @user
    get user_profile_url
    assert_redirected_to new_user_session_url
  end
end
