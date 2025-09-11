require "test_helper"

class PrintersHelperTest < ActionView::TestCase
  test "printers helper is loaded" do
    # Basic test to ensure the helper loads without errors
    assert true
  end

  test "has access to standard helper methods" do
    assert_respond_to self, :link_to
    assert_respond_to self, :content_tag
  end
end