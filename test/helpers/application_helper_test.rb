require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "page_title returns title with brand" do
    result = page_title("Test Page")
    assert_includes result, "Test Page"
    assert_includes result, I18n.t("nav.brand")
    assert_includes result, " | "
  end

  test "page_title returns just brand when no title provided" do
    result = page_title
    assert_equal I18n.t("nav.brand"), result
  end

  test "bootstrap_flash_class returns correct classes" do
    assert_equal "alert-success", bootstrap_flash_class("notice")
    assert_equal "alert-success", bootstrap_flash_class("success")
    assert_equal "alert-danger", bootstrap_flash_class("alert")
    assert_equal "alert-danger", bootstrap_flash_class("error")
    assert_equal "alert-warning", bootstrap_flash_class("warning")
    assert_equal "alert-info", bootstrap_flash_class("info")
    assert_equal "alert-info", bootstrap_flash_class("unknown")
  end

  test "format_boolean returns translated yes/no" do
    assert_equal I18n.t("common.yes"), format_boolean(true)
    assert_equal I18n.t("common.no"), format_boolean(false)
    assert_equal I18n.t("common.no"), format_boolean(nil)
  end

  test "format_percentage handles various inputs" do
    assert_equal "25%", format_percentage(25)
    assert_equal "0%", format_percentage(0)
    assert_equal "0%", format_percentage(nil)
    assert_equal "100%", format_percentage(100)
  end

  test "can access Rails helper methods" do
    # Test that standard Rails helpers are available
    assert_respond_to self, :link_to
    assert_respond_to self, :content_tag
    assert_respond_to self, :form_with
  end
end
