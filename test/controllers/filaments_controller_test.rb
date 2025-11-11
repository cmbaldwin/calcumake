require "test_helper"

class FilamentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    @filament = filaments(:one)
    sign_in @user
  end

  # Index action
  test "should get index" do
    get filaments_url
    assert_response :success
  end

  test "should search filaments by name" do
    get filaments_url, params: { q: { name_or_brand_or_color_cont: @filament.name } }
    assert_response :success
  end

  test "should filter filaments by material type" do
    get filaments_url, params: { q: { material_type_eq: @filament.material_type } }
    assert_response :success
  end

  # Show action
  test "should show filament" do
    get filament_url(@filament)
    assert_response :success
  end

  # New action
  test "should get new" do
    get new_filament_url
    assert_response :success
  end

  # Create action
  test "should create filament" do
    assert_difference("Filament.count") do
      post filaments_url, params: {
        filament: {
          name: "Test Filament",
          material_type: "PLA",
          diameter: 1.75,
          density: 1.24
        }
      }
    end

    assert_redirected_to filament_url(Filament.last)
    assert_equal "Successfully created Filament", flash[:notice]
  end

  test "should not create filament with invalid data" do
    assert_no_difference("Filament.count") do
      post filaments_url, params: {
        filament: {
          name: "",  # Invalid - blank name
          material_type: "InvalidType",  # Invalid material type
          diameter: 1.75
        }
      }
    end

    assert_response :unprocessable_content
  end

  # Edit action
  test "should get edit" do
    get edit_filament_url(@filament)
    assert_response :success
  end

  # Update action
  test "should update filament" do
    patch filament_url(@filament), params: {
      filament: {
        name: "Updated Filament Name",
        brand: "Updated Brand"
      }
    }

    assert_redirected_to filament_url(@filament)
    assert_equal "Successfully updated Filament", flash[:notice]

    @filament.reload
    assert_equal "Updated Filament Name", @filament.name
    assert_equal "Updated Brand", @filament.brand
  end

  test "should not update filament with invalid data" do
    original_name = @filament.name

    patch filament_url(@filament), params: {
      filament: {
        name: "",  # Invalid - blank name
        material_type: "InvalidType"  # Invalid material type
      }
    }

    assert_response :unprocessable_content
    @filament.reload
    assert_equal original_name, @filament.name
  end

  # Destroy action
  test "should destroy filament" do
    assert_difference("Filament.count", -1) do
      delete filament_url(@filament)
    end

    assert_redirected_to filaments_url
    assert_equal "Successfully deleted Filament", flash[:notice]
  end

  # Duplicate action
  test "should duplicate filament" do
    assert_difference("Filament.count") do
      post duplicate_filament_url(@filament)
    end

    new_filament = Filament.last
    assert_redirected_to edit_filament_url(new_filament)
    assert_equal "Successfully duplicated Filament", flash[:notice]
    assert_equal "#{@filament.name} (Copy)", new_filament.name
    assert_equal @filament.material_type, new_filament.material_type
    assert_equal @filament.diameter, new_filament.diameter
  end

  # Authorization tests
  test "should require authentication for all actions" do
    sign_out @user

    get filaments_url
    assert_redirected_to new_user_session_url

    get filament_url(@filament)
    assert_redirected_to new_user_session_url

    get new_filament_url
    assert_redirected_to new_user_session_url

    get edit_filament_url(@filament)
    assert_redirected_to new_user_session_url
  end

  test "should only show user's own filaments" do
    other_user = users(:two)
    other_filament = filaments(:two)
    other_filament.update!(user: other_user)

    get filament_url(other_filament)
    assert_response :not_found
  end

  test "should not allow editing other user's filaments" do
    other_user = users(:two)
    other_filament = filaments(:two)
    other_filament.update!(user: other_user)

    get edit_filament_url(other_filament)
    assert_response :not_found
  end

  # Modal functionality tests
  test "should get new as turbo_stream for modal" do
    get new_filament_url, as: :turbo_stream
    assert_response :success
    assert_match(/turbo-stream/, response.body)
    assert_match(/modal/, response.body)
  end

  test "should create filament via turbo_stream for modal" do
    assert_difference("Filament.count") do
      post filaments_url, params: {
        filament: {
          name: "Modal Test Filament",
          material_type: "PLA",
          diameter: 1.75,
          density: 1.24
        }
      }, as: :turbo_stream
    end
    assert_response :success
    assert_match(/turbo-stream/, response.body)
  end

  test "should render errors in modal on create failure" do
    assert_no_difference("Filament.count") do
      post filaments_url, params: {
        filament: {
          name: "",  # Invalid: name is required
          material_type: "PLA"
        }
      }, as: :turbo_stream
    end
    assert_response :unprocessable_content
    assert_match(/modal/, response.body)
  end
end
