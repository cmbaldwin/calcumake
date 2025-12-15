# Integrating Lexxy Rich Text Editor with Rails Admin (No-Build Setup)

**Date:** December 15, 2024
**Author:** Claude & Cody
**Rails Version:** 8.1.1
**Rails Admin Version:** 3.3.0
**Lexxy Version:** 0.1.23.beta

## Problem Statement

Rails Admin 3.3.0 with importmap configuration doesn't have native support for Action Text rich text fields. When using `has_rich_text :content` in models, Rails Admin would either:

1. Not display the field at all
2. Show a plain textarea without any rich text editing capabilities
3. Load Trix editor but with missing styles and non-functional toolbar

Additionally, we wanted to use **Lexxy** (a modern Trix replacement by Basecamp) instead of the default Trix editor, which added another layer of complexity.

## Environment Constraints

- **Rails 8.1.1** with **importmap-rails** (no Node.js/npm in production)
- **Propshaft** asset pipeline (not Sprockets)
- **No CSS bundling** (no cssbundling-rails, no Sass compilation)
- **Rails Admin 3.3.0** with `config.asset_source = :importmap`
- **Lexxy gem** already installed for main app

## The Journey: What Didn't Work

### Attempt 1: Native Rails Admin Action Text Support
Rails Admin claims to support `:action_text` field type, but this doesn't exist in version 3.3.0:

```ruby
field :content, :action_text do
  help "Article content with rich text editor"
end
```

**Result:** Field didn't render at all.

### Attempt 2: Loading Trix via Importmap
Added Trix and ActionText to `config/importmap.rails_admin.rb`:

```ruby
pin "trix", to: "https://ga.jspm.io/npm:trix@2.1.5/dist/trix.esm.js"
pin "@rails/actiontext", to: "https://ga.jspm.io/npm:@rails/actiontext@8.0.0/app/assets/javascripts/actiontext.esm.js"
```

**Result:** Editor appeared but:
- Toolbar icons missing
- Styles not applied
- Conflicted with Lexxy when both were loaded

### Attempt 3: Custom CSS Imports
Tried importing Lexxy CSS into rails_admin.css using `@import url()`:

```css
@import url('lexxy.css');
```

**Result:** Propshaft couldn't resolve the path. CSS imports don't work the same way in Propshaft as they do in Sprockets.

### Attempt 4: Downloading Lexxy CSS Files Locally
Created `app/assets/stylesheets/lexxy/` directory and downloaded CSS files from GitHub:

```bash
mkdir -p app/assets/stylesheets/lexxy
curl -o app/assets/stylesheets/lexxy/lexxy-variables.css ...
curl -o app/assets/stylesheets/lexxy/lexxy-editor.css ...
curl -o app/assets/stylesheets/lexxy/lexxy-content.css ...
```

**Result:** Still couldn't import them properly in rails_admin.css.

### Attempt 5: Custom Rails Admin Layout Override
Created `app/views/layouts/rails_admin/_head.html.erb` to override asset loading, but accidentally removed critical Rails Admin CSS loading.

**Result:** Rails Admin lost all styling.

## The Solution: Three-Part Integration

### Part 1: Rails Admin CSS (Propshaft-Compatible)

**Key Insight:** Rails Admin with importmap + Propshaft requires a pre-compiled CSS file, not SCSS that needs compilation.

**Solution:** Use the rails_admin.css from [rails_admin-nobuild](https://github.com/3v0k4/rails_admin-nobuild) repository, which is a working example of Rails Admin with Propshaft.

```bash
curl -s https://raw.githubusercontent.com/3v0k4/rails_admin-nobuild/main/app/assets/stylesheets/rails_admin.css \
  -o app/assets/stylesheets/rails_admin.css
```

This file:
- Contains pre-compiled Bootstrap 5.1.3 styles
- Has `url()` paths modified for Propshaft compatibility
- Includes all Rails Admin UI styles
- Contains Trix styles (which we'll override with Lexxy)

### Part 2: Custom Rails Admin Head Partial

Create `app/views/layouts/rails_admin/_head.html.erb` to add Lexxy stylesheet:

```erb
<meta content="IE=edge" http-equiv="X-UA-Compatible">
<meta content="text/html; charset=utf-8" http-equiv="Content-Type">
<meta content="width=device-width, initial-scale=1" name="viewport; charset=utf-8">
<meta content="NONE,NOARCHIVE" name="robots">
<meta content="false" name="turbo-prefetch">
<%= csrf_meta_tag %>
<% case RailsAdmin::config.asset_source
   when :importmap %>
  <%= stylesheet_link_tag "rails_admin.css", media: :all, data: {'turbo-track': 'reload'} %>
  <%# Add Lexxy styles for rich text editor %>
  <%= stylesheet_link_tag "lexxy", media: :all, data: {'turbo-track': 'reload'} %>
  <%= javascript_inline_importmap_tag(RailsAdmin::Engine.importmap.to_json(resolver: self)) %>
  <%= javascript_importmap_module_preload_tags(RailsAdmin::Engine.importmap) %>
  <%= javascript_importmap_shim_nonce_configuration_tag if respond_to? :javascript_importmap_shim_nonce_configuration_tag %>
  <%= javascript_importmap_shim_tag if respond_to? :javascript_importmap_shim_tag %>
  <%= # Preload jQuery and make it global, unless jQuery UI fails to initialize
      tag.script "import jQuery from 'jquery'; window.jQuery = jQuery;".html_safe, type: "module" %>
  <%= javascript_import_module_tag 'rails_admin' %>
<% else
     raise "Unknown asset_source: #{RailsAdmin::config.asset_source}"
   end %>
```

**Key Change:** Line 9 adds `stylesheet_link_tag "lexxy"` after rails_admin.css, allowing Lexxy to override any Trix styles.

### Part 3: JavaScript Configuration

**config/importmap.rails_admin.rb:**
```ruby
# ... other Rails Admin pins ...

# Lexxy editor for Action Text (replaces Trix)
pin "lexxy", to: "lexxy.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
```

**app/javascript/rails_admin.js:**
```javascript
import "rails_admin/src/rails_admin/base";
import "lexxy";
import "@rails/activestorage";
```

**Critical:** Do NOT import Trix alongside Lexxy. They conflict.

### Part 4: Rails Admin Model Configuration

**config/initializers/rails_admin.rb:**
```ruby
config.model "Article" do
  edit do
    group :content do
      label "Content (Translatable)"

      field :title
      field :slug
      field :excerpt

      # Rich text content field with custom partial
      field :content do
        partial 'form_action_text'
        help "Article content with rich text editor"
      end
    end
  end
end
```

**app/views/rails_admin/main/_form_action_text.html.erb:**
```erb
<%= form.rich_text_area field.method_name, class: 'form-control' %>
```

This custom partial renders the `rich_text_area` helper, which generates a `<trix-editor>` element that Lexxy automatically converts and enhances.

## How It Works

1. **Rails Admin loads** with its base CSS (Bootstrap + custom styles)
2. **Lexxy CSS loads** after Rails Admin CSS, overriding Trix styles
3. **Lexxy JavaScript loads** via importmap and detects `<trix-editor>` elements
4. **Lexxy automatically replaces** Trix editor with its enhanced version
5. **ActiveStorage** handles image/file uploads in the editor

## File Structure

```
app/
├── assets/
│   └── stylesheets/
│       └── rails_admin.css          # Pre-compiled from rails_admin-nobuild
├── javascript/
│   └── rails_admin.js               # Imports Lexxy
├── views/
│   ├── layouts/
│   │   └── rails_admin/
│   │       └── _head.html.erb       # Custom head with Lexxy CSS
│   └── rails_admin/
│       └── main/
│           └── _form_action_text.html.erb  # Rich text field partial
config/
├── importmap.rails_admin.rb         # Pins Lexxy & ActiveStorage
└── initializers/
    └── rails_admin.rb               # Field configuration
```

## Testing the Integration

1. Start Rails server: `bin/dev`
2. Navigate to `/admin/article/new`
3. Verify:
   - ✅ Content field shows rich text editor
   - ✅ Toolbar with formatting icons appears
   - ✅ Editor is interactive (typing works)
   - ✅ Toolbar buttons work (bold, italic, headings, etc.)
   - ✅ Image upload works (drag & drop)
   - ✅ Lexxy styles are applied (modern UI)

## Key Takeaways

### 1. Rails Admin + Importmap Needs Pre-Compiled CSS
With Propshaft and no CSS bundling, you must provide a complete, pre-compiled `rails_admin.css` file. The [rails_admin-nobuild](https://github.com/3v0k4/rails_admin-nobuild) repository provides this.

### 2. Override via Partials, Not Configuration
Rails Admin doesn't have a built-in `:action_text` field type in version 3.3.0. Use custom partials to render rich text fields.

### 3. CSS Loading Order Matters
Load Lexxy CSS **after** Rails Admin CSS so it can override Trix styles:
```erb
<%= stylesheet_link_tag "rails_admin.css" %>
<%= stylesheet_link_tag "lexxy" %>  <!-- This overrides Trix -->
```

### 4. Don't Mix Trix and Lexxy
Only load Lexxy JavaScript, not both Trix and Lexxy. They conflict.

### 5. Lexxy Handles Conversion Automatically
Lexxy automatically detects and converts `<trix-editor>` elements. No additional configuration needed.

## Troubleshooting

### Editor appears but toolbar icons missing
**Problem:** Lexxy CSS not loading
**Solution:** Verify `stylesheet_link_tag "lexxy"` is in the head partial

### Editor not interactive
**Problem:** Lexxy JavaScript not loading
**Solution:** Check `app/javascript/rails_admin.js` imports Lexxy

### "Asset not found" error
**Problem:** Missing rails_admin.css file
**Solution:** Download from rails_admin-nobuild repo

### Trix and Lexxy both loading
**Problem:** Conflicting importmap pins
**Solution:** Remove Trix pins from `config/importmap.rails_admin.rb`

### Content field doesn't appear at all
**Problem:** Field not configured or custom partial missing
**Solution:** Add custom partial and configure field in rails_admin.rb

## Benefits of This Setup

1. **No build step** - Works with pure importmaps and Propshaft
2. **Modern editor** - Lexxy provides better UX than Trix
3. **Maintainable** - Follows Rails conventions
4. **Production-ready** - No Node.js dependencies
5. **Fast** - CSS and JS load from CDN via importmap

## References

- [Rails Admin No-Build Example](https://github.com/3v0k4/rails_admin-nobuild)
- [Lexxy GitHub Repository](https://github.com/basecamp/lexxy)
- [Rails Admin Documentation](https://github.com/railsadminteam/rails_admin)
- [Propshaft Documentation](https://github.com/rails/propshaft)

## Version History

- **v1.0** (2024-12-15): Initial working implementation
- Rails 8.1.1, Rails Admin 3.3.0, Lexxy 0.1.23.beta

---

**Success!** This setup provides a fully functional rich text editor in Rails Admin without any build tools, using modern Lexxy editor and Rails 8's importmap approach.
