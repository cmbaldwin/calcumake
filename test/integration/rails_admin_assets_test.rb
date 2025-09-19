require "test_helper"

class RailsAdminAssetsTest < ActionDispatch::IntegrationTest
  test "rails admin importmap file exists and has JSPM CDN integration" do
    rails_admin_importmap_path = Rails.root.join("config/importmap.rails_admin.rb")
    assert File.exist?(rails_admin_importmap_path), "Rails Admin importmap file must exist"

    importmap_content = File.read(rails_admin_importmap_path)

    # Rails Admin uses JSPM CDN for dependencies
    assert_includes importmap_content, 'pin "rails_admin"',
                    "rails_admin must be pinned in separate importmap file"
    assert_includes importmap_content, "preload: true",
                    "rails_admin should be preloaded for performance"
  end

  test "rails admin css file exists and contains complete styles" do
    css_path = Rails.root.join("app/assets/stylesheets/rails_admin.css")
    assert File.exist?(css_path), "Rails Admin CSS file must exist"

    css_content = File.read(css_path)

    # Should be the complete Rails Admin CSS (large file)
    assert css_content.length > 100_000, "Rails Admin CSS should be complete (>100KB)"
    assert_includes css_content, "Bootstrap",
                    "Rails Admin CSS must contain Bootstrap styles"
  end

  test "propshaft auto-discovers rails admin css without manifest" do
    # With Propshaft, no manifest.js needed
    manifest_path = Rails.root.join("app/assets/config/manifest.js")
    assert_not File.exist?(manifest_path), "manifest.js should not exist with Propshaft"

    # CSS should be accessible via asset pipeline
    css_path = ActionController::Base.helpers.asset_path("rails_admin.css")
    get css_path
    assert_response :success
  end
end