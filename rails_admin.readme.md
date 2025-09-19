# Rails Admin Setup for Rails 8 + Propshaft + Importmaps

This guide documents how to set up Rails Admin in a Rails 8 application using Propshaft (no Sprockets) and importmaps without a build process. This approach is based on the [rails_admin-nobuild](https://github.com/3v0k4/rails_admin-nobuild) pattern.

## Overview

Rails Admin's standard installation doesn't work out-of-the-box with Rails 8's Propshaft asset pipeline. This setup uses:
- **No manifest.js** - Propshaft auto-discovers assets
- **JSPM CDN** - External JavaScript dependencies via ga.jspm.io
- **Separate importmap file** - Dedicated importmap for Rails Admin dependencies
- **Complete CSS file** - Full Rails Admin CSS copied from working instance

## Step-by-Step Installation

### 1. Add Rails Admin Gem

```ruby
# Gemfile
gem "rails_admin", "~> 3.0"
```

```bash
bundle install
```

### 2. Generate Initial Configuration

```bash
rails generate rails_admin:install
```

**Note:** The generator will create broken configurations for Rails 8. We'll fix these manually.

### 3. Create Separate Importmap File

Create `config/importmap.rails_admin.rb`:

```ruby
# Rails Admin JavaScript dependencies via JSPM CDN
# Using ga.jspm.io for Rails 8 + Propshaft compatibility

# Rails Admin core
pin "rails_admin", to: "https://ga.jspm.io/npm:rails_admin@3.1.2/src/rails_admin/application.js", preload: true

# Bootstrap 5 (required by Rails Admin)
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.3.7/dist/js/bootstrap.esm.js"
pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.8/dist/esm/popper.js"

# jQuery (required by Rails Admin)
pin "jquery", to: "https://ga.jspm.io/npm:jquery@3.7.1/dist/jquery.js"
pin "jquery-ui", to: "https://ga.jspm.io/npm:jquery-ui@1.13.3/dist/jquery-ui.js"

# Flatpickr (date picker)
pin "flatpickr", to: "https://ga.jspm.io/npm:flatpickr@4.6.13/dist/flatpickr.js"

# Additional Rails Admin dependencies
pin "rails_admin/base", to: "https://ga.jspm.io/npm:rails_admin@3.1.2/src/rails_admin/base.js"
```

### 4. Remove Broken manifest.js (If Exists)

```bash
# Remove the manifest file - Propshaft doesn't need it
rm app/assets/config/manifest.js
```

### 5. Create Complete Rails Admin CSS

You need the complete Rails Admin CSS file. Either:

**Option A: Copy from working Rails Admin instance**
```bash
# If you have access to a working Rails Admin setup
cp /path/to/working/app/assets/stylesheets/rails_admin.css app/assets/stylesheets/
```

**Option B: Extract from Rails Admin gem**
```bash
# Find the gem and copy CSS assets
bundle show rails_admin
# Copy CSS files from gem's assets directory
```

**Option C: Use this template structure in `app/assets/stylesheets/rails_admin.css`:**

```css
/*
 * Rails Admin CSS for Propshaft + Importmaps
 * Complete styles for Rails Admin 3.x
 * This file should contain all Rails Admin CSS (~946KB when complete)
 */

/* Bootstrap base styles */
/* Rails Admin specific styles */
/* Form styling */
/* Navigation styling */
/* Dashboard styling */
/* Table styling */
/* Modal styling */
/* Responsive styles */

/* Note: This file should be very large (~946KB) when complete */
/* The file needs to contain all Bootstrap + Rails Admin styles */
```

**Important:** The CSS file must be complete and substantial (around 946KB). A minimal CSS file will not work.

### 6. Configure Routes

```ruby
# config/routes.rb
Rails.application.routes.draw do
  mount RailsAdmin::Engine => "/admin", as: "rails_admin"

  # Your other routes...
end
```

### 7. Configure Authentication (Optional but Recommended)

```ruby
# config/initializers/rails_admin.rb
RailsAdmin.config do |config|
  # Authentication
  config.authenticate_with do
    # Replace with your authentication logic
    redirect_to main_app.new_user_session_path unless current_user&.admin?
  end

  # Authorization
  config.authorize_with do
    redirect_to main_app.root_path unless current_user&.admin?
  end

  config.current_user_method(&:current_user)
end
```

### 8. Test the Setup

Create test files to verify the setup works:

#### Test 1: Asset Integration Test

```ruby
# test/integration/rails_admin_assets_test.rb
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
```

#### Test 2: Rails Admin Basic Functionality

```ruby
# test/integration/rails_admin_test.rb
require "test_helper"

class RailsAdminTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin_user = User.create!(
      email: "test_admin@example.com",
      password: "test_password",
      admin: true  # Assuming you have an admin boolean field
    )
  end

  test "rails admin requires authentication" do
    get "/admin"
    assert_redirected_to new_user_session_path
  end

  test "rails admin css is accessible via asset pipeline" do
    css_path = ActionController::Base.helpers.asset_path("rails_admin.css")
    get css_path
    assert_response :success
    assert_match /text\/css/, response.content_type
  end
end
```

### 9. Run Tests

```bash
rails test test/integration/rails_admin_assets_test.rb
rails test test/integration/rails_admin_test.rb
```

## Key Points for Success

### ✅ Do This
- Use **separate importmap file** for Rails Admin dependencies
- Load dependencies via **JSPM CDN** (ga.jspm.io)
- Include **complete Rails Admin CSS** file (not just a stub)
- **Remove manifest.js** - Propshaft doesn't need it
- Test asset integration thoroughly

### ❌ Avoid This
- Don't use the standard Rails Admin generator output as-is
- Don't try to use Sprockets-style asset compilation
- Don't use incomplete CSS files
- Don't mix Rails Admin assets with main application importmap
- Don't use local JavaScript files for complex dependencies

## Troubleshooting

### Assets Not Loading
```bash
# Check that Propshaft can find the CSS
rails assets:precompile
ls public/assets/*rails_admin*
```

### JavaScript Errors
- Verify all JSPM URLs are accessible
- Check browser console for 404s on JavaScript modules
- Ensure Bootstrap and jQuery are loading before Rails Admin

### CSS Missing
- Verify the CSS file is large enough (should be ~946KB when complete)
- Check that all Rails Admin styles are included
- Test CSS accessibility via asset pipeline

## Version Compatibility

This setup has been tested with:
- **Rails**: 8.0+
- **Rails Admin**: 3.0+
- **Propshaft**: Latest
- **Ruby**: 3.4+

## References

- [rails_admin-nobuild](https://github.com/3v0k4/rails_admin-nobuild) - Original pattern
- [JSPM CDN](https://ga.jspm.io) - JavaScript module CDN
- [Rails Admin Documentation](https://github.com/railsadminteam/rails_admin)
- [Propshaft Documentation](https://github.com/rails/propshaft)

## Example Working Implementation

For a complete working example, see the MOAB project structure:
- `config/importmap.rails_admin.rb` - Complete JSPM CDN setup
- `app/assets/stylesheets/rails_admin.css` - Full CSS integration
- `test/integration/rails_admin_*_test.rb` - Comprehensive test coverage

This approach provides a robust, maintainable Rails Admin setup that works seamlessly with Rails 8's modern asset pipeline.