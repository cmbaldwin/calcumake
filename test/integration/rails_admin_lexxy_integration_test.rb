require "test_helper"

class RailsAdminLexxyIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin_user = User.create!(
      email: "lexxy_admin@example.com",
      password: "test_password",
      admin: true,
      default_currency: "USD",
      default_energy_cost_per_kwh: 0.12,
      confirmed_at: Time.current
    )
  end

  test "lexxy is pinned in rails admin importmap" do
    rails_admin_importmap_path = Rails.root.join("config/importmap.rails_admin.rb")
    assert File.exist?(rails_admin_importmap_path), "Rails Admin importmap file must exist"

    importmap_content = File.read(rails_admin_importmap_path)

    # Lexxy should be pinned for Action Text support
    assert_includes importmap_content, 'pin "lexxy"',
                    "Lexxy must be pinned in Rails Admin importmap for rich text editing"

    # ActiveStorage should be pinned for file uploads in rich text
    assert_includes importmap_content, 'pin "@rails/activestorage"',
                    "ActiveStorage must be pinned for file uploads in Lexxy editor"
  end

  test "trix is NOT pinned in rails admin importmap" do
    rails_admin_importmap_path = Rails.root.join("config/importmap.rails_admin.rb")
    importmap_content = File.read(rails_admin_importmap_path)

    # Trix should NOT be present (conflicts with Lexxy)
    assert_not_includes importmap_content, 'pin "trix"',
                        "Trix should not be pinned (conflicts with Lexxy)"
    assert_not_includes importmap_content, 'pin "@rails/actiontext"',
                        "ActionText Trix version should not be pinned (using Lexxy instead)"
  end

  test "rails admin javascript imports lexxy" do
    js_path = Rails.root.join("app/javascript/rails_admin.js")
    assert File.exist?(js_path), "Rails Admin JavaScript file must exist"

    js_content = File.read(js_path)

    # Lexxy should be imported
    assert_includes js_content, 'import "lexxy"',
                    "Lexxy must be imported in rails_admin.js"

    # ActiveStorage should be imported
    assert_includes js_content, 'import "@rails/activestorage"',
                    "ActiveStorage must be imported for file uploads"

    # Rails Admin base should be imported
    assert_includes js_content, 'import "rails_admin/src/rails_admin/base"',
                    "Rails Admin base must be imported"
  end

  test "custom action text partial exists" do
    partial_path = Rails.root.join("app/views/rails_admin/main/_form_action_text.html.erb")
    assert File.exist?(partial_path), "Custom Action Text partial must exist"

    partial_content = File.read(partial_path)

    # Should render rich_text_area helper
    assert_includes partial_content, "rich_text_area",
                    "Partial must use rich_text_area helper"
    assert_includes partial_content, "field.method_name",
                    "Partial must use dynamic field method name"
  end

  test "custom rails admin head partial loads lexxy css" do
    head_partial_path = Rails.root.join("app/views/layouts/rails_admin/_head.html.erb")
    assert File.exist?(head_partial_path), "Custom Rails Admin head partial must exist"

    head_content = File.read(head_partial_path)

    # Font Awesome CDN should be loaded (required by Rails Admin)
    assert_includes head_content, "font-awesome",
                    "Font Awesome must be loaded from CDN"

    # Rails Admin CSS should be loaded
    assert_includes head_content, 'stylesheet_link_tag "rails_admin.css"',
                    "Rails Admin CSS must be loaded"

    # Lexxy CSS should be loaded AFTER rails_admin.css
    assert_includes head_content, 'stylesheet_link_tag "lexxy"',
                    "Lexxy CSS must be loaded for rich text editor styling"

    # Verify correct order (Lexxy should appear after rails_admin in file)
    rails_admin_css_index = head_content.index('stylesheet_link_tag "rails_admin.css"')
    lexxy_css_index = head_content.index('stylesheet_link_tag "lexxy"')

    assert rails_admin_css_index < lexxy_css_index,
           "Lexxy CSS must be loaded AFTER Rails Admin CSS to override Trix styles"
  end

  test "rails admin css does not contain trix styles" do
    css_path = Rails.root.join("app/assets/stylesheets/rails_admin.css")
    css_content = File.read(css_path)

    # Trix CSS should NOT be present (conflicts with Lexxy)
    assert_not_includes css_content, "trix-editor",
                        "Trix editor styles should be removed from rails_admin.css"
    assert_not_includes css_content, "trix-button",
                        "Trix button styles should be removed from rails_admin.css"
  end

  test "lexxy css file is accessible via propshaft" do
    # Lexxy CSS should be served by Propshaft
    css_path = ActionController::Base.helpers.asset_path("lexxy.css")
    get css_path
    assert_response :success
    assert_match /text\/css/, response.content_type
  end

  test "article model configured to use action text partial in rails admin" do
    # Read rails_admin initializer
    initializer_path = Rails.root.join("config/initializers/rails_admin.rb")
    assert File.exist?(initializer_path), "Rails Admin initializer must exist"

    initializer_content = File.read(initializer_path)

    # Article content field should use custom partial
    assert_includes initializer_content, 'config.model "Article"',
                    "Article model must be configured in Rails Admin"
    assert_includes initializer_content, "partial 'form_action_text'",
                    "Article content field must use custom Action Text partial"
  end

  test "lexxy gem is installed and available" do
    # Check if Lexxy gem is available
    assert defined?(Lexxy), "Lexxy gem must be installed and loaded"
  end

  # System test to verify full integration (requires Selenium)
  # Uncomment when system tests are configured
  # test "lexxy editor renders in rails admin article form" do
  #   driven_by :selenium, using: :headless_chrome
  #
  #   sign_in @admin_user
  #   visit "/admin/article/new"
  #
  #   # Verify rich text editor is present
  #   assert_selector "trix-editor", text: ""
  #   assert_selector ".trix-button-group" # Toolbar buttons
  #
  #   # Verify Lexxy styles are applied (check for specific Lexxy CSS classes)
  #   # This would require inspecting computed styles
  # end
end
