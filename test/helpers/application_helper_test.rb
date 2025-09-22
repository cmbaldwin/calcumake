require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "application helper is loaded" do
    # Basic test to ensure the helper loads without errors
    assert_respond_to self, :content_for
  end

  test "can access Rails helper methods" do
    # Test that standard Rails helpers are available
    assert_respond_to self, :link_to
    assert_respond_to self, :content_tag
    assert_respond_to self, :form_with
  end
end
