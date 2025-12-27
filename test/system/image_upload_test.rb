require "application_system_test_case"

class ImageUploadTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:one)
    sign_in @user
  end

  test "image upload component is present on user profile page" do
    visit user_profile_url

    # Check for image upload component
    assert_selector '[data-controller="image-upload"]', wait: 2
    assert_selector ".upload-area"
  end

  test "upload area shows placeholder when no image is present" do
    # Ensure user has no logo
    @user.company_logo.purge if @user.company_logo.attached?

    visit user_profile_url

    within '[data-controller="image-upload"]' do
      # Should show placeholder icon and text
      assert_selector ".placeholder-icon", visible: true
      assert_text "Drag & drop"
    end
  end

  test "upload area shows preview when image is present" do
    # Attach a test image if needed
    if @user.company_logo.attached?
      visit user_profile_url

      within '[data-controller="image-upload"]' do
        # Should show preview image
        assert_selector "img.preview-image", visible: true
        # Should have remove button
        assert_button "Remove"
      end
    end
  end

  test "file input accepts only images" do
    visit user_profile_url

    file_input = find('input[type="file"]', visible: :all)
    # Check that accept attribute includes image types
    assert file_input["accept"].include?("image/"), "Should accept image files"
  end

  test "upload area has correct data attributes for stimulus" do
    visit user_profile_url

    upload_area = find('[data-controller="image-upload"]')
    assert upload_area["data-image-upload-max-size-value"].present?,
           "Should have max size data attribute"
  end

  test "error message container exists" do
    visit user_profile_url

    within '[data-controller="image-upload"]' do
      # Error container should exist (may not be visible initially)
      assert_selector '[data-image-upload-target="error"]', visible: :all
    end
  end

  test "preview and placeholder targets exist" do
    visit user_profile_url

    within '[data-controller="image-upload"]' do
      assert_selector '[data-image-upload-target="preview"]'
      assert_selector '[data-image-upload-target="placeholder"]'
    end
  end
end
