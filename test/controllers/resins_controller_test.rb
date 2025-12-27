require "test_helper"

class ResinsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @resin = resins(:one)
    sign_in @user
  end

  # Index action
  test "should get index" do
    get resins_url
    assert_response :success
  end

  test "should search resins by name" do
    get resins_url, params: { q: { name_or_brand_or_color_cont: @resin.name } }
    assert_response :success
  end

  test "should filter resins by resin type" do
    get resins_url, params: { q: { resin_type_eq: @resin.resin_type } }
    assert_response :success
  end

  # Show action
  test "should show resin" do
    get resin_url(@resin)
    assert_response :success
  end

  # New action
  test "should get new" do
    get new_resin_url
    assert_response :success
  end

  # Create action
  test "should create resin" do
    assert_difference("Resin.count") do
      post resins_url, params: {
        resin: {
          name: "Test Resin",
          resin_type: "Standard",
          bottle_volume_ml: 1000,
          bottle_price: 25.00
        }
      }
    end

    assert_redirected_to resins_url
    assert_equal "Successfully created Resin", flash[:notice]
  end

  test "should not create resin with invalid data" do
    assert_no_difference("Resin.count") do
      post resins_url, params: {
        resin: {
          name: "",  # Invalid - blank name
          resin_type: "InvalidType"  # Invalid resin type
        }
      }
    end

    assert_response :unprocessable_content
  end

  # Edit action
  test "should get edit" do
    get edit_resin_url(@resin)
    assert_response :success
  end

  # Update action
  test "should update resin" do
    patch resin_url(@resin), params: {
      resin: {
        name: "Updated Resin Name",
        brand: "Updated Brand"
      }
    }

    assert_redirected_to resin_url(@resin)
    assert_equal "Successfully updated Resin", flash[:notice]

    @resin.reload
    assert_equal "Updated Resin Name", @resin.name
    assert_equal "Updated Brand", @resin.brand
  end

  test "should not update resin with invalid data" do
    original_name = @resin.name

    patch resin_url(@resin), params: {
      resin: {
        name: "",  # Invalid - blank name
        resin_type: "InvalidType"  # Invalid resin type
      }
    }

    assert_response :unprocessable_content
    @resin.reload
    assert_equal original_name, @resin.name
  end

  # Destroy action
  test "should destroy resin" do
    assert_difference("Resin.count", -1) do
      delete resin_url(@resin)
    end

    assert_redirected_to resins_url
    assert_equal "Successfully deleted Resin", flash[:notice]
  end

  # Duplicate action
  test "should duplicate resin" do
    assert_difference("Resin.count") do
      post duplicate_resin_url(@resin)
    end

    new_resin = Resin.last
    assert_redirected_to edit_resin_url(new_resin)
    assert_equal "Successfully duplicated Resin", flash[:notice]
    assert_equal "#{@resin.name} (Copy)", new_resin.name
    assert_equal @resin.resin_type, new_resin.resin_type
  end

  # Authorization tests
  test "should require authentication for all actions" do
    sign_out @user

    get resins_url
    assert_redirected_to new_user_session_url

    get resin_url(@resin)
    assert_redirected_to new_user_session_url

    get new_resin_url
    assert_redirected_to new_user_session_url

    get edit_resin_url(@resin)
    assert_redirected_to new_user_session_url
  end

  test "should only show user's own resins" do
    other_user = users(:two)
    other_resin = resins(:two)
    other_resin.update!(user: other_user)

    get resin_url(other_resin)
    assert_response :not_found
  end

  test "should not allow editing other user's resins" do
    other_user = users(:two)
    other_resin = resins(:two)
    other_resin.update!(user: other_user)

    get edit_resin_url(other_resin)
    assert_response :not_found
  end

  # Modal functionality tests
  test "should get new as turbo_stream for modal" do
    get new_resin_url, as: :turbo_stream
    assert_response :success
    assert_match(/turbo-stream/, response.body)
    assert_match(/modal_content/, response.body)
    assert_match(/resin/, response.body)
  end

  test "should create resin via turbo_stream for modal" do
    assert_difference("Resin.count") do
      post resins_url, params: {
        resin: {
          name: "Modal Test Resin",
          resin_type: "Standard",
          bottle_volume_ml: 1000,
          bottle_price: 25.00
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
    assert_no_difference("Resin.count") do
      post resins_url, params: {
        resin: {
          name: "",  # Invalid: name is required
          resin_type: "Standard"
        }
      }, as: :turbo_stream
    end
    assert_response :unprocessable_content
    assert_match(/modal_content/, response.body)
  end

  test "should handle modal form with all required fields" do
    get new_resin_url, as: :turbo_stream
    assert_response :success
    # Check that form has required fields
    assert_match(/name/, response.body)
    assert_match(/resin_type/, response.body)
  end
end
