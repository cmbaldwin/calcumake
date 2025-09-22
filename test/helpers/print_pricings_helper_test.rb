require "test_helper"

class PrintPricingsHelperTest < ActionView::TestCase
  include CurrencyHelper

  test "print pricings helper is loaded" do
    # Basic test to ensure the helper loads without errors
    assert true
  end

  test "has access to currency helper methods when included" do
    # Since print pricings likely use currency formatting
    assert_respond_to self, :currency_symbol
    assert_respond_to self, :format_currency
  end
end
