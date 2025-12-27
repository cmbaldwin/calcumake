require "test_helper"

class MaterialsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @filament = filaments(:one)
    @resin = resins(:one)
    sign_in @user
  end

  test "should get index" do
    get materials_url
    assert_response :success
  end

  test "should display both filaments and resins" do
    get materials_url
    assert_response :success
    assert_select "h4", text: /Filaments/
    assert_select "h4", text: /Resins/
  end

  test "should search across filaments and resins" do
    get materials_url, params: { q: { name_or_brand_or_color_cont: "test" } }
    assert_response :success
  end

  test "should require authentication" do
    sign_out @user
    get materials_url
    assert_redirected_to new_user_session_url
  end

  test "should show empty state when no materials" do
    # Delete all materials for user
    @user.filaments.destroy_all
    @user.resins.destroy_all

    get materials_url
    assert_response :success
  end
end
