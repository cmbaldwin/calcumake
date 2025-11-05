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

  # OAuth helper method tests
  test "oauth_provider_icon returns Google SVG for Google provider" do
    icon = oauth_provider_icon("Google")
    assert_includes icon, "svg"
    assert_includes icon, "18"
    assert_includes icon, "me-2"
    assert_includes icon, "aria-hidden"
    assert_includes icon, "#4285F4"  # Google blue color
    assert_includes icon, "#34A853"  # Google green color
    assert_includes icon, "#FBBC05"  # Google yellow color
    assert_includes icon, "#EA4335"  # Google red color
  end

  test "oauth_provider_icon returns GitHub SVG for GitHub provider" do
    icon = oauth_provider_icon("GitHub")
    assert_includes icon, "svg"
    assert_includes icon, "18"
    assert_includes icon, "me-2"
    assert_includes icon, "aria-hidden"
    assert_includes icon, "currentColor"
    assert_includes icon, "viewBox=\"0 0 16 16\""
  end

  test "oauth_provider_icon returns Microsoft SVG for Microsoft provider" do
    icon = oauth_provider_icon("Microsoft")
    assert_includes icon, "svg"
    assert_includes icon, "18"
    assert_includes icon, "me-2"
    assert_includes icon, "aria-hidden"
    assert_includes icon, "currentColor"
    assert_includes icon, "viewBox=\"0 0 16 16\""
    assert_includes icon, "7.462 0H0v7.19h7.462V0z"
  end

  test "oauth_provider_icon handles case insensitive input" do
    google_lowercase = oauth_provider_icon("google")
    google_uppercase = oauth_provider_icon("GOOGLE")
    google_mixed = oauth_provider_icon("Google")

    assert_equal google_lowercase, google_uppercase
    assert_equal google_lowercase, google_mixed
    assert_includes google_lowercase, "#4285F4"
  end

  test "oauth_provider_icon returns empty string for unknown provider" do
    assert_equal "", oauth_provider_icon("unknown")
    assert_equal "", oauth_provider_icon("")
    assert_equal "", oauth_provider_icon(nil)
  end

  test "oauth_provider_button_class returns correct classes for each provider" do
    assert_equal "btn btn-outline-danger", oauth_provider_button_class("Google")
    assert_equal "btn btn-outline-dark", oauth_provider_button_class("GitHub")
    assert_equal "btn btn-outline-primary", oauth_provider_button_class("Microsoft")
  end

  test "oauth_provider_button_class handles case insensitive input" do
    assert_equal "btn btn-outline-danger", oauth_provider_button_class("google")
    assert_equal "btn btn-outline-danger", oauth_provider_button_class("GOOGLE")
    assert_equal "btn btn-outline-danger", oauth_provider_button_class("Google")
  end

  test "oauth_provider_button_class returns default class for unknown provider" do
    assert_equal "btn btn-outline-secondary", oauth_provider_button_class("unknown")
    assert_equal "btn btn-outline-secondary", oauth_provider_button_class("")
    assert_equal "btn btn-outline-secondary", oauth_provider_button_class(nil)
  end

  test "oauth helper methods work together for all supported providers" do
    providers = ["Google", "GitHub", "Microsoft"]

    providers.each do |provider|
      icon = oauth_provider_icon(provider)
      button_class = oauth_provider_button_class(provider)

      assert_not_equal "", icon, "Icon should not be empty for #{provider}"
      assert_includes button_class, "btn", "Button class should include 'btn' for #{provider}"
      assert_includes icon, "svg", "Icon should be an SVG for #{provider}"
      assert_includes icon, "aria-hidden", "Icon should have aria-hidden for accessibility"
    end
  end

  test "translate_filament_type handles all material types" do
    assert_equal I18n.t("print_pricing.filament_types.pla"), translate_filament_type("PLA")
    assert_equal I18n.t("print_pricing.filament_types.abs"), translate_filament_type("ABS")
    assert_equal I18n.t("print_pricing.filament_types.petg"), translate_filament_type("PETG")
    assert_equal "", translate_filament_type("")
    assert_equal "", translate_filament_type(nil)
  end
end
