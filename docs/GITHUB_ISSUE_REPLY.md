# Rails Admin + Importmap + Propshaft Setup

## Solution: Rails Admin + Importmap + Propshaft + Action Text (Lexxy)

I got this working with **Rails 8.1.1, Rails Admin 3.3.0, Propshaft, and Importmap** (no build tools). Here's the minimal setup:

### 1. Download the pre-compiled CSS

Rails Admin with importmap needs a pre-compiled CSS file:

```bash
curl -s https://raw.githubusercontent.com/3v0k4/rails_admin-nobuild/main/app/assets/stylesheets/rails_admin.css \
  -o app/assets/stylesheets/rails_admin.css
```

Credit to [@3v0k4's rails_admin-nobuild](https://github.com/3v0k4/rails_admin-nobuild) for the Propshaft-compatible CSS.

### 2. For Action Text rich text fields (optional)

If you need rich text editing (e.g., for blog posts), add to `app/views/rails_admin/main/_form_action_text.html.erb`:

```erb
<%= form.rich_text_area field.method_name, class: 'form-control' %>
```

Configure the field in `config/initializers/rails_admin.rb`:

```ruby
config.model "Article" do
  edit do
    field :content do
      partial 'form_action_text'
    end
  end
end
```

### 3. Use Lexxy instead of Trix (optional)

Add to `Gemfile`:

```ruby
gem "lexxy"
```

Add to `config/importmap.rails_admin.rb`:

```ruby
pin "lexxy", to: "lexxy.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
```

Add to `app/javascript/rails_admin.js`:

```javascript
import "rails_admin/src/rails_admin/base";
import "lexxy";
import "@rails/activestorage";
```

Override the head to include Lexxy CSS at `app/views/layouts/rails_admin/_head.html.erb`:

```erb
<!-- Keep all original Rails Admin head content, just add this line after rails_admin.css -->
<%= stylesheet_link_tag "lexxy", media: :all, data: {'turbo-track': 'reload'} %>
```

### That's it!

Works perfectly with:

- ✅ Rails 8.1.1
- ✅ Importmap (no Node.js)
- ✅ Propshaft
- ✅ Action Text with Lexxy editor
- ✅ No build step

Full writeup: [Rails Admin Lexxy Integration Guide](https://github.com/your-username/your-repo/blob/main/docs/RAILS_ADMIN_LEXXY_INTEGRATION.md) _(update with your actual link)_
