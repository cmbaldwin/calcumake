require "test_helper"

class PrintPricingsHelperTest < ActionView::TestCase
  include CurrencyHelper

  setup do
    @pricing = print_pricings(:one)
    @print_pricings = [ print_pricings(:one), print_pricings(:two) ]
  end

  test "format_print_time returns formatted string" do
    result = format_print_time(@pricing)
    assert_match(/\d+h \d+m/, result)
    # Verify it calculates from plates correctly
    total_minutes = @pricing.total_printing_time_minutes
    hours = total_minutes / 60
    minutes = total_minutes % 60
    assert_equal "#{hours}h #{minutes}m", result
  end

  test "format_creation_date returns formatted date" do
    result = format_creation_date(@pricing)
    expected = @pricing.created_at.strftime("%b %d, %Y")
    assert_equal expected, result
  end

  test "total_print_time_hours calculates total correctly" do
    result = total_print_time_hours(@print_pricings)
    expected = @print_pricings.sum { |p| p.total_actual_print_time_minutes } / 60
    assert_equal expected, result
  end

  test "pricing_card_metadata_badges returns HTML with badges" do
    result = pricing_card_metadata_badges(@pricing)
    assert_includes result, "badge bg-info" # Plate count badge
    assert_includes result, "badge bg-secondary" # Filament type badge
    assert_includes result, "text-muted"
    assert_includes result, "plate" # Should show plate count
  end

  test "pricing_card_actions returns HTML with dropdown actions" do
    result = pricing_card_actions(@pricing)
    assert_includes result, "dropdown"
    assert_includes result, "dropdown-toggle"
    assert_includes result, I18n.t("actions.actions")
    assert_includes result, I18n.t("actions.show")
    assert_includes result, I18n.t("actions.edit")
    assert_includes result, I18n.t("actions.delete")
  end

  test "has access to currency helper methods when included" do
    # Since print pricings likely use currency formatting
    assert_respond_to self, :currency_symbol
    assert_respond_to self, :format_currency
  end

  test "format_currency_with_symbol combines symbol and formatted amount" do
    result = format_currency_with_symbol(25.50, "USD")
    assert_equal "$25.50", result
  end

  test "format_detailed_creation_date returns detailed date format" do
    result = format_detailed_creation_date(@pricing)
    assert_match(/\w+ \d{1,2}, \d{4} at \d{1,2}:\d{2} (AM|PM)/, result)
  end

  test "cost_breakdown_sections returns organized data structure" do
    sections = cost_breakdown_sections(@pricing)
    assert_kind_of Array, sections
    assert sections.any? { |s| s[:title] == "Print Information" }
    # Now shows individual plates instead of "Filament Details"
    assert sections.any? { |s| s[:title].include?("Plate") }

    # Check that sections have the expected structure
    sections.each do |section|
      assert section.key?(:title)
      assert section.key?(:items)
      assert_kind_of Array, section[:items]
    end
  end

  test "pricing_show_actions returns HTML with show page dropdown actions" do
    result = pricing_show_actions(@pricing)
    assert_includes result, "dropdown"
    assert_includes result, "dropdown-toggle"
    assert_includes result, I18n.t("actions.actions")
    assert_includes result, I18n.t("actions.edit")
    assert_includes result, I18n.t("actions.delete")
    refute_includes result, I18n.t("actions.show") # Show action not needed on show page
  end
end
