require "test_helper"

class UserProfilesHelperTest < ActionView::TestCase
  include CurrencyHelper

  test "user profiles helper is loaded" do
    # Basic test to ensure the helper loads without errors
    assert true
  end

  test "has access to currency helper methods when included" do
    # Since user profiles handle currency settings
    assert_respond_to self, :currency_options
    assert_respond_to self, :currency_symbol
  end
end
