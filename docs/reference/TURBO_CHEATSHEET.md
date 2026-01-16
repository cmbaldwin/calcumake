# Turbo Quick Reference Cheat Sheet

## Turbo Drive
```erb
<!-- Disable Turbo Drive -->
data: { turbo: false }

<!-- Track asset changes -->
"data-turbo-track": "reload"
```

## Turbo Frames
```erb
<!-- Basic frame -->
<%= turbo_frame_tag "frame_id" do %>
  Content
<% end %>

<!-- Target specific frame -->
data: { turbo_frame: "frame_id" }

<!-- Break out of frame -->
data: { turbo_frame: "_top" }

<!-- Lazy loading -->
<%= turbo_frame_tag "lazy", src: path do %>
  Loading...
<% end %>
```

## Turbo Streams

### Actions
```ruby
turbo_stream.append("target", content)    # Add to end
turbo_stream.prepend("target", content)   # Add to beginning
turbo_stream.replace("target", content)   # Replace element
turbo_stream.update("target", content)    # Replace innerHTML
turbo_stream.remove("target")             # Delete element
turbo_stream.before("target", content)    # Insert before
turbo_stream.after("target", content)     # Insert after
```

### Controller Pattern
```ruby
respond_to do |format|
  format.html { redirect_to path, notice: "Success!" }
  format.turbo_stream {
    flash.now[:notice] = "Success!"
    render turbo_stream: [
      turbo_stream.prepend("items", @item),
      turbo_stream.replace("flash", partial: "layouts/flash")
    ]
  }
end
```

### Broadcasting
```ruby
# In model
broadcasts_to ->(item) { "items" }, inserts_by: :prepend

# In view
<%= turbo_stream_from "items" %>
```

## Stimulus Basics
```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String, delay: Number }
  static targets = [ "input", "output" ]
  static classes = [ "active" ]

  connect() { /* Initialize */ }
  disconnect() { /* Cleanup */ }

  methodName() { /* Action */ }
}
```

```erb
<div data-controller="example"
     data-example-url-value="/api/endpoint"
     data-action="click->example#methodName">
  <input data-example-target="input">
  <div data-example-target="output"></div>
</div>
```

## Flash Messages
```erb
<!-- Layout -->
<div id="flash" class="flash">
  <%= render "layouts/flash" %>
</div>

<!-- Partial -->
<% flash.each do |type, message| %>
  <div class="flash__message flash__message--<%= type %>"
       data-controller="removals"
       data-action="animationend->removals#remove">
    <%= message %>
  </div>
<% end %>
```

```css
@keyframes appear-then-fade {
  0%, 100% { opacity: 0; transform: translateY(-10px); }
  5%, 60% { opacity: 1; transform: translateY(0); }
}
```

## Testing
```ruby
# Controller test
post path, params: params, as: :turbo_stream
assert_turbo_stream action: :prepend, target: "items"

# Broadcasting test
assert_broadcasts "stream_name", 1 do
  Model.create!(attrs)
end
```

## Common Patterns

### Modal Form
```erb
<%= turbo_frame_tag "modal" do %>
  <%= form_with model: @item, data: { turbo_frame: "modal" } %>
<% end %>
```

### Inline Edit
```erb
<%= turbo_frame_tag dom_id(@item, :edit) do %>
  <%= link_to "Edit", edit_item_path(@item), data: { turbo_frame: dom_id(@item, :edit) } %>
<% end %>
```

### Real-time List
```erb
<%= turbo_stream_from "items" %>
<div id="items">
  <%= render @items %>
</div>
```

## Debugging
```javascript
// Enable Turbo logging
Turbo.session.drive.debug = true

// Listen to events
document.addEventListener("turbo:load", () => console.log("Loaded"))
```

## Status Codes
- `200` - Success, render partial
- `422` - Validation errors
- `302` - Redirect (HTML only)
- `204` - No content