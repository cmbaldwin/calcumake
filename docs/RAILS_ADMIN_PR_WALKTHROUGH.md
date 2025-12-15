# Contributing a Fix to Rails Admin for Importmap + Propshaft Support

## Overview

This guide walks through creating a Pull Request to Rails Admin that adds official support for Action Text rich text fields when using the importmap + Propshaft setup (no build tools).

## Problem Being Solved

Rails Admin 3.3.0 with `config.asset_source = :importmap` doesn't properly support Action Text `has_rich_text` fields. The field either doesn't render or appears as a plain textarea without rich text editing capabilities.

## The Fix

Add native support for Action Text fields with Lexxy editor (modern Trix replacement) in the importmap configuration.

---

## Step 1: Fork and Clone Rails Admin

```bash
# Fork the repository on GitHub first
# https://github.com/railsadminteam/rails_admin

# Clone your fork
git clone git@github.com:YOUR_USERNAME/rails_admin.git
cd rails_admin

# Add upstream remote
git remote add upstream https://github.com/railsadminteam/rails_admin.git

# Create a feature branch
git checkout -b feature/importmap-action-text-support
```

## Step 2: Understand the Current Structure

Key files to examine:
- `lib/generators/rails_admin/install_generator.rb` - Installation generator
- `lib/generators/rails_admin/templates/` - Template files
- `app/views/rails_admin/main/` - Field partials
- `config/locales/` - Internationalization

## Step 3: Changes Needed

### A. Add Action Text Field Partial Template

Create `lib/generators/rails_admin/templates/rails_admin/main/_form_action_text.html.erb.tt`:

```erb
<%%= form.rich_text_area field.method_name, class: 'form-control' %>
```

This template will be copied to user apps during installation.

### B. Update Install Generator

Modify `lib/generators/rails_admin/install_generator.rb` in the `configure_for_importmap` method:

```ruby
def configure_for_importmap
  run "yarn add rails_admin@#{RailsAdmin::Version.js}"
  template 'rails_admin.js', 'app/javascript/rails_admin.js'
  require_relative 'importmap_formatter'
  add_file 'config/importmap.rails_admin.rb', ImportmapFormatter.new.format
  setup_css

  # NEW: Add Action Text partial template
  template 'rails_admin/main/_form_action_text.html.erb.tt',
           'app/views/rails_admin/main/_form_action_text.html.erb'
end
```

### C. Update Rails Admin JavaScript Template

Modify `lib/generators/rails_admin/templates/rails_admin.js`:

```javascript
import "rails_admin/src/rails_admin/base";
// Support for Action Text with Lexxy (modern Trix alternative)
import "lexxy";
import "@rails/activestorage";
```

### D. Update Importmap Formatter

Modify `lib/generators/rails_admin/importmap_formatter.rb` to include Lexxy:

```ruby
def format
  <<~RUBY
    # ... existing pins ...

    # Action Text support with Lexxy editor
    pin "lexxy", to: "lexxy.js"
    pin "@rails/activestorage", to: "activestorage.esm.js"
  RUBY
end
```

### E. Update Head Partial Template

Modify `app/views/layouts/rails_admin/_head.html.erb` to conditionally load Lexxy CSS:

```erb
<% when :importmap %>
  <%= stylesheet_link_tag "rails_admin.css", media: :all, data: {'turbo-track': 'reload'} %>
  <%# Load Lexxy styles if Action Text is used %>
  <% if defined?(ActionText) %>
    <%= stylesheet_link_tag "lexxy", media: :all, data: {'turbo-track': 'reload'} rescue nil %>
  <% end %>
  <%= javascript_inline_importmap_tag(RailsAdmin::Engine.importmap.to_json(resolver: self)) %>
  ...
```

### F. Add Documentation

Create `docs/action_text.md`:

```markdown
# Action Text Integration with Rails Admin

Rails Admin supports Action Text rich text fields when using the importmap asset source.

## Setup

1. Ensure you have Action Text installed:
   ```bash
   rails action_text:install
   ```

2. Add Lexxy to your Gemfile:
   ```ruby
   gem "lexxy"
   ```

3. Run the Rails Admin installer:
   ```bash
   rails g rails_admin:install --asset=importmap
   ```

4. Configure your model in `config/initializers/rails_admin.rb`:
   ```ruby
   config.model "Article" do
     edit do
       field :content do
         partial 'form_action_text'
       end
     end
   end
   ```

## How it Works

- Rails Admin generates a custom partial for Action Text fields
- Lexxy editor replaces Trix for a modern editing experience
- Styles are loaded automatically when ActionText is detected
```

### G. Update README

Add to the main README.md under "Features":

```markdown
- ✅ Action Text rich text fields (with Lexxy editor for importmap)
```

## Step 4: Test the Changes

### A. Create a Test Rails App

```bash
# In a separate directory
rails new test_app --database=postgresql
cd test_app

# Add your local Rails Admin fork
# In Gemfile:
gem 'rails_admin', path: '../rails_admin'
gem 'lexxy'

bundle install

# Setup Action Text
rails action_text:install

# Generate a model with rich text
rails g scaffold Article title:string
rails g migration AddContentToArticles
```

In the migration:
```ruby
class AddContentToArticles < ActiveRecord::Migration[8.0]
  def change
    # Action Text will create action_text_rich_texts table
  end
end
```

In `app/models/article.rb`:
```ruby
class Article < ApplicationRecord
  has_rich_text :content
end
```

Run migrations:
```bash
rails db:create db:migrate

# Install Rails Admin
rails g rails_admin:install --asset=importmap

# Start server
bin/dev
```

Navigate to `/admin/article/new` and verify the rich text editor works.

### B. Verify Generated Files

Check that these files were created:
- ✅ `app/views/rails_admin/main/_form_action_text.html.erb`
- ✅ `config/importmap.rails_admin.rb` (with Lexxy pins)
- ✅ `app/javascript/rails_admin.js` (with Lexxy imports)

## Step 5: Write Tests

Add specs to `spec/features/action_text_spec.rb`:

```ruby
require 'rails_helper'

RSpec.describe "Action Text Integration", type: :feature do
  before do
    RailsAdmin.config do |config|
      config.asset_source = :importmap
    end
  end

  it "renders rich text field with custom partial" do
    visit rails_admin.new_path(model_name: 'article')

    expect(page).to have_selector('trix-editor')
    expect(page).to have_selector('.form-control')
  end

  it "saves rich text content" do
    visit rails_admin.new_path(model_name: 'article')

    fill_in 'Title', with: 'Test Article'
    # Rich text editor interaction would go here

    click_button 'Save'

    expect(Article.last.content.body).to be_present
  end
end
```

## Step 6: Update CHANGELOG

Add to `CHANGELOG.md`:

```markdown
## [Unreleased]

### Added
- Action Text support for importmap configuration with Lexxy editor
- Automatic generation of Action Text field partial template
- Lexxy CSS loading when ActionText is detected

### Changed
- Updated importmap formatter to include Lexxy and ActiveStorage
- Enhanced rails_admin.js template with Action Text imports
```

## Step 7: Commit and Push

```bash
# Stage all changes
git add .

# Commit with descriptive message
git commit -m "Add Action Text support for importmap configuration

- Add form_action_text partial template for rich text fields
- Include Lexxy editor as modern Trix alternative
- Update importmap formatter to pin Lexxy and ActiveStorage
- Add conditional Lexxy CSS loading in head partial
- Add documentation for Action Text integration
- Update tests to cover Action Text field rendering

Fixes #3722"

# Push to your fork
git push origin feature/importmap-action-text-support
```

## Step 8: Create Pull Request

1. Go to https://github.com/YOUR_USERNAME/rails_admin
2. Click "Pull Request"
3. Use this template:

---

**Title:** Add Action Text support for importmap configuration

**Description:**

This PR adds native support for Action Text rich text fields when using Rails Admin with `config.asset_source = :importmap`.

## Problem

Rails Admin 3.3.0 doesn't properly support Action Text fields in importmap mode. Users report that rich text fields either don't render or appear as plain textareas (#3722).

## Solution

This PR introduces:

1. **Action Text Field Partial Template** - Auto-generated during installation
2. **Lexxy Editor Integration** - Modern Trix alternative that works with importmap
3. **Automatic CSS Loading** - Lexxy styles load when ActionText is detected
4. **Updated Generator** - Includes Lexxy and ActiveStorage in importmap configuration

## Changes

- Added `_form_action_text.html.erb` template for rich text fields
- Updated install generator to create Action Text partial
- Modified importmap formatter to include Lexxy pins
- Enhanced head partial to conditionally load Lexxy CSS
- Added documentation for Action Text setup
- Included tests for Action Text field rendering

## Testing

Tested with:
- ✅ Rails 8.1.1
- ✅ Rails Admin 3.3.0
- ✅ Propshaft
- ✅ Importmap (no Node.js)
- ✅ Action Text with Lexxy editor

## Breaking Changes

None - this is purely additive functionality.

## Dependencies

Requires users to add `gem "lexxy"` to their Gemfile if using Action Text.

Fixes #3722

---

## Step 9: Respond to Review Feedback

Be prepared to:
- Adjust code based on maintainer feedback
- Add/modify tests as requested
- Update documentation
- Squash commits if requested

---

## Claude Instructions for Different Session

If you need to recreate this work or help someone else implement it, here are the key instructions for Claude:

### Context to Provide

```
I need to add Action Text support to Rails Admin for the importmap configuration.
Rails Admin 3.3.0 with config.asset_source = :importmap doesn't support has_rich_text
fields properly - they either don't render or show as plain textareas.

The solution involves:
1. Using Lexxy (modern Trix replacement) instead of Trix
2. Creating a custom field partial for Action Text
3. Updating the importmap configuration to include Lexxy
4. Conditionally loading Lexxy CSS in the Rails Admin head partial

Reference implementation that works:
- app/views/rails_admin/main/_form_action_text.html.erb contains:
  <%= form.rich_text_area field.method_name, class: 'form-control' %>
- config/importmap.rails_admin.rb includes pins for "lexxy" and "@rails/activestorage"
- app/javascript/rails_admin.js imports: rails_admin/base, lexxy, and activestorage
- app/views/layouts/rails_admin/_head.html.erb loads lexxy stylesheet after rails_admin.css

I need this integrated into the Rails Admin gem so it's automatically set up during installation.
```

### Files to Modify

```
Please modify these files in the Rails Admin gem:

1. lib/generators/rails_admin/install_generator.rb
   - Update configure_for_importmap method to generate Action Text partial

2. lib/generators/rails_admin/templates/rails_admin/main/_form_action_text.html.erb.tt
   - Create this new template file

3. lib/generators/rails_admin/importmap_formatter.rb
   - Add Lexxy and ActiveStorage pins to the generated importmap

4. lib/generators/rails_admin/templates/rails_admin.js
   - Add Lexxy and ActiveStorage imports

5. app/views/layouts/rails_admin/_head.html.erb
   - Add conditional Lexxy CSS loading when ActionText is detected

6. docs/action_text.md
   - Create documentation for Action Text integration

7. README.md
   - Add Action Text to features list

8. CHANGELOG.md
   - Document the new feature
```

### Key Requirements

```
- Must work with Rails 8.1+, Propshaft, and Importmap (no build tools)
- Must not break existing functionality
- Should be opt-in (only loads if ActionText is present)
- Must use Lexxy instead of Trix (better importmap support)
- Should follow Rails Admin's existing generator patterns
- Needs documentation and tests
```

### Testing Steps

```
After making changes, test by:

1. Create new Rails app: rails new test_app
2. Add modified rails_admin gem via path in Gemfile
3. Add lexxy gem
4. Install Action Text: rails action_text:install
5. Generate scaffold with has_rich_text field
6. Run rails g rails_admin:install --asset=importmap
7. Verify these files exist:
   - app/views/rails_admin/main/_form_action_text.html.erb
   - Lexxy pins in config/importmap.rails_admin.rb
   - Lexxy imports in app/javascript/rails_admin.js
8. Start server and navigate to /admin/article/new
9. Verify rich text editor renders with toolbar and is interactive
```

---

## Additional Resources

- [Rails Admin Issue #3722](https://github.com/railsadminteam/rails_admin/issues/3722)
- [rails_admin-nobuild example](https://github.com/3v0k4/rails_admin-nobuild)
- [Lexxy GitHub](https://github.com/basecamp/lexxy)
- [Rails Action Text Guide](https://guides.rubyonrails.org/action_text_overview.html)
- [Our working implementation](docs/RAILS_ADMIN_LEXXY_INTEGRATION.md)

## Success Criteria

- ✅ Generator creates Action Text partial automatically
- ✅ Importmap includes Lexxy and ActiveStorage pins
- ✅ JavaScript imports Lexxy
- ✅ CSS loads conditionally
- ✅ Rich text editor works in /admin
- ✅ Tests pass
- ✅ Documentation complete
- ✅ No breaking changes
- ✅ PR accepted and merged

Good luck with your contribution! 🚀
