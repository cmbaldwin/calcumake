# Turbo Reference Guide

This document provides comprehensive reference material for Hotwire/Turbo implementation in Rails applications, based on the Hot Rails guide and Rails 8 best practices.

## Table of Contents

1. [Turbo Drive](#turbo-drive)
2. [Turbo Frames](#turbo-frames)
3. [Turbo Streams](#turbo-streams)
4. [Stimulus Integration](#stimulus-integration)
5. [Flash Messages](#flash-messages)
6. [Testing Patterns](#testing-patterns)
7. [Common Gotchas](#common-gotchas)
8. [Performance Tips](#performance-tips)

## Turbo Drive

Turbo Drive automatically converts navigation to AJAX requests, creating SPA-like behavior with zero configuration.

### Core Benefits
- Automatic AJAX conversion for links and forms
- Preserves `<head>` content across navigation
- Faster page transitions
- Browser history management
- Progress bar indication

### Configuration Options

```erb
<!-- Disable Turbo Drive globally (not recommended) -->
<meta name="turbo-visit-control" content="disable">

<!-- Disable for specific links -->
<%= link_to "External", "https://example.com", data: { turbo: false } %>

<!-- Disable for forms -->
<%= form_with model: @model, data: { turbo: false } do |f| %>
<% end %>

<!-- Force full page reload for assets -->
<%= stylesheet_link_tag "app", "data-turbo-track": "reload" %>
```

### Progress Bar Customization

```css
.turbo-progress-bar {
  height: 5px;
  background-color: #007bff;
}
```

### JavaScript Hooks

```javascript
// Listen for Turbo events
document.addEventListener("turbo:load", () => {
  // Page loaded
});

document.addEventListener("turbo:before-visit", (event) => {
  // Before navigation
});

document.addEventListener("turbo:visit", (event) => {
  // During navigation
});
```

## Turbo Frames

Turbo Frames segment pages into independently updateable sections.

### Basic Implementation

```erb
<!-- Define a frame -->
<%= turbo_frame_tag "posts" do %>
  <%= render @posts %>
<% end %>

<!-- Target frame from link -->
<%= link_to "Edit", edit_post_path(@post), data: { turbo_frame: "post_form" } %>

<!-- Target frame from form -->
<%= form_with model: @post, data: { turbo_frame: "posts" } do |f| %>
<% end %>
```

### Frame Targeting

```erb
<!-- Target specific frame -->
data: { turbo_frame: "sidebar" }

<!-- Break out of frame (full page navigation) -->
data: { turbo_frame: "_top" }

<!-- Stay in current frame (default) -->
data: { turbo_frame: "_self" }

<!-- Target parent frame (for nested frames) -->
data: { turbo_frame: "_parent" }
```

### Lazy Loading

```erb
<%= turbo_frame_tag "lazy_content", src: lazy_content_path do %>
  <div class="loading">Loading...</div>
<% end %>
```

### Nested Frames

```ruby
# Helper for nested frame IDs
def nested_dom_id(*args)
  args.map { |arg| arg.respond_to?(:to_key) ? dom_id(arg) : arg }.join("_")
end
```

```erb
<!-- Nested frame structure -->
<%= turbo_frame_tag nested_dom_id(@post, :comments) do %>
  <%= turbo_frame_tag dom_id(@comment, :form) do %>
    <%= render "comments/form" %>
  <% end %>

  <div class="comments">
    <%= render @post.comments %>
  </div>
<% end %>
```

### Frame Error Handling

```erb
<!-- app/views/application/_turbo_frame_error.html.erb -->
<div class="alert alert-error">
  <h3>Unable to load content</h3>
  <p>Please try again or <%= link_to "refresh the page", request.url %>.</p>
</div>
```

## Turbo Streams

Turbo Streams enable real-time DOM manipulation with seven available actions.

### Available Actions

```ruby
# Append content to end of target
turbo_stream.append("posts", @post)

# Prepend content to beginning of target
turbo_stream.prepend("posts", @post)

# Replace entire target element
turbo_stream.replace("post_123", @post)

# Update target's inner content only
turbo_stream.update("post_count", @posts.count)

# Remove target element
turbo_stream.remove("post_123")

# Insert content before target
turbo_stream.before("post_123", @new_post)

# Insert content after target
turbo_stream.after("post_123", @new_post)
```

### Controller Patterns

```ruby
class PostsController < ApplicationController
  def create
    @post = current_user.posts.build(post_params)

    if @post.save
      respond_to do |format|
        format.html { redirect_to @post, notice: "Post created." }
        format.turbo_stream {
          flash.now[:notice] = "Post created successfully."
          render turbo_stream: [
            turbo_stream.prepend("posts", @post),
            turbo_stream.replace("flash", partial: "layouts/flash"),
            turbo_stream.replace("post_form", partial: "form", locals: { post: Post.new })
          ]
        }
      end
    else
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    @post.destroy

    respond_to do |format|
      format.html { redirect_to posts_path, notice: "Post deleted." }
      format.turbo_stream {
        flash.now[:notice] = "Post deleted successfully."
        render turbo_stream: [
          turbo_stream.remove(@post),
          turbo_stream.replace("flash", partial: "layouts/flash")
        ]
      }
    end
  end
end
```

### Turbo Stream Templates

```erb
<!-- app/views/posts/create.turbo_stream.erb -->
<%= turbo_stream.prepend "posts" do %>
  <%= render @post %>
<% end %>

<%= turbo_stream.replace "post_form" do %>
  <%= render "form", post: Post.new %>
<% end %>

<%= turbo_stream.replace "flash" do %>
  <%= render "layouts/flash" %>
<% end %>
```

### Real-time Broadcasting with Action Cable

```ruby
# In model
class Post < ApplicationRecord
  belongs_to :user

  # Basic broadcasting
  broadcasts_to ->(post) { "user_#{post.user_id}_posts" }, inserts_by: :prepend

  # Custom broadcasting
  after_create_commit -> { broadcast_prepend_to "posts", target: "posts_list" }
  after_update_commit -> { broadcast_replace_to "posts" }
  after_destroy_commit -> { broadcast_remove_to "posts" }

  # Background job broadcasting for performance
  after_create_commit -> { broadcast_prepend_later_to "posts" }
end
```

```erb
<!-- Subscribe to stream in view -->
<%= turbo_stream_from "user_#{current_user.id}_posts" %>

<!-- Multiple streams -->
<%= turbo_stream_from "posts" %>
<%= turbo_stream_from "user_#{current_user.id}_notifications" %>
```

### Conditional Broadcasting

```ruby
# Broadcast only to specific users
def broadcast_to_followers
  followers.each do |follower|
    broadcast_prepend_to "user_#{follower.id}_feed", target: "posts"
  end
end

# Broadcast with conditions
after_create_commit :broadcast_if_published

private

def broadcast_if_published
  broadcast_prepend_to "posts" if published?
end
```

## Stimulus Integration

Stimulus controllers enhance Turbo functionality with progressive enhancement.

### Controller Template

```javascript
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    autoHide: Boolean,
    delay: Number,
    url: String
  }

  static targets = [ "content", "button", "input" ]
  static classes = [ "active", "hidden", "loading" ]

  connect() {
    console.log("Controller connected")
    this.setupEventListeners()
  }

  disconnect() {
    console.log("Controller disconnected")
    this.cleanup()
  }

  // Value changed callbacks
  autoHideValueChanged(value) {
    if (value) {
      this.scheduleHide()
    }
  }

  // Action methods
  toggle() {
    this.element.classList.toggle(this.activeClass)
  }

  hide() {
    this.element.classList.add(this.hiddenClass)
  }

  show() {
    this.element.classList.remove(this.hiddenClass)
  }

  // Private methods
  setupEventListeners() {
    // Setup logic
  }

  cleanup() {
    // Cleanup logic
  }

  scheduleHide() {
    setTimeout(() => {
      this.hide()
    }, this.delayValue || 3000)
  }
}
```

### Common Stimulus Patterns

```erb
<!-- Modal controller -->
<div data-controller="modal"
     data-modal-auto-close-value="true"
     data-action="click->modal#close">
  <div data-modal-target="dialog" data-action="click->modal#stopPropagation">
    Modal content
  </div>
</div>

<!-- Form controller -->
<form data-controller="form-validation"
      data-action="submit->form-validation#validate">
  <input data-form-validation-target="email"
         data-action="blur->form-validation#validateField">
  <button data-form-validation-target="submit">Submit</button>
</form>

<!-- Auto-save controller -->
<form data-controller="auto-save"
      data-auto-save-url-value="/posts/auto_save"
      data-auto-save-delay-value="2000">
  <textarea data-action="input->auto-save#scheduleeSave"></textarea>
</form>
```

## Flash Messages

Modern flash message implementation with CSS animations and automatic removal.

### HTML Structure

```erb
<!-- app/views/layouts/application.html.erb -->
<body>
  <div id="flash" class="flash">
    <%= render "layouts/flash" %>
  </div>
  <!-- rest of body -->
</body>

<!-- app/views/layouts/_flash.html.erb -->
<% flash.each do |flash_type, message| %>
  <div class="flash__message flash__message--<%= flash_type %>"
       data-controller="removals"
       data-action="animationend->removals#remove">
    <%= message %>
  </div>
<% end %>
```

### CSS Implementation

```css
/* Flash container */
.flash {
  position: fixed;
  top: 5rem;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  z-index: 1000;
  pointer-events: none;
}

/* Flash message base */
.flash__message {
  font-size: 0.875rem;
  color: white;
  padding: 0.75rem 1.5rem;
  background-color: #374151;
  animation: appear-then-fade 4s both;
  border-radius: 999px;
  box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
  max-width: 90vw;
  word-wrap: break-word;
  pointer-events: auto;
}

/* Flash message types */
.flash__message--notice,
.flash__message--success {
  background-color: #10b981;
}

.flash__message--alert,
.flash__message--error {
  background-color: #ef4444;
}

.flash__message--warning {
  background-color: #f59e0b;
}

.flash__message--info {
  background-color: #3b82f6;
}

/* Animation */
@keyframes appear-then-fade {
  0%, 100% {
    opacity: 0;
    transform: translateY(-10px);
  }
  5%, 60% {
    opacity: 1;
    transform: translateY(0);
  }
}
```

### Stimulus Controller

```javascript
// app/javascript/controllers/removals_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  remove() {
    this.element.remove()
  }
}
```

### Controller Integration

```ruby
# Standard pattern for all controllers
def create
  @resource = current_user.resources.build(resource_params)

  if @resource.save
    respond_to do |format|
      format.html { redirect_to @resource, notice: t('flash.created', model: t('models.resource')) }
      format.turbo_stream {
        flash.now[:notice] = t('flash.created', model: t('models.resource'))
        render "layouts/flash"
      }
    end
  else
    respond_to do |format|
      format.html { render :new, status: :unprocessable_content }
      format.turbo_stream {
        flash.now[:alert] = t('flash.validation_errors')
        render turbo_stream: [
          turbo_stream.replace("resource_form", partial: "form", locals: { resource: @resource }),
          turbo_stream.replace("flash", partial: "layouts/flash")
        ]
      }
    end
  end
end
```

### Turbo Stream Flash Template

```erb
<!-- app/views/layouts/flash.turbo_stream.erb -->
<%= turbo_stream.replace "flash" do %>
  <%= render "layouts/flash" %>
<% end %>
```

## Testing Patterns

### Controller Testing

```ruby
class PostsControllerTest < ActionDispatch::IntegrationTest
  test "creates post with HTML format" do
    assert_difference 'Post.count' do
      post posts_path, params: { post: { title: "Test" } }
    end

    assert_redirected_to post_path(Post.last)
    assert_equal "Post was successfully created.", flash[:notice]
  end

  test "creates post with Turbo Stream format" do
    assert_difference 'Post.count' do
      post posts_path, params: { post: { title: "Test" } }, as: :turbo_stream
    end

    assert_turbo_stream action: :prepend, target: "posts"
    assert_turbo_stream action: :replace, target: "flash"
  end

  test "handles validation errors with Turbo Stream" do
    assert_no_difference 'Post.count' do
      post posts_path, params: { post: { title: "" } }, as: :turbo_stream
    end

    assert_response :unprocessable_content
    assert_turbo_stream action: :replace, target: "post_form"
  end
end
```

### System Testing

```ruby
class PostsSystemTest < ApplicationSystemTestCase
  test "creates post with real-time updates" do
    visit posts_path

    fill_in "Title", with: "New Post"
    click_button "Create Post"

    assert_text "Post was successfully created"
    assert_text "New Post"
  end

  test "inline editing with Turbo Frames" do
    post = posts(:one)
    visit post_path(post)

    click_link "Edit"
    fill_in "Title", with: "Updated Title"
    click_button "Update Post"

    assert_text "Updated Title"
    assert_no_text "Edit" # Form should be replaced
  end
end
```

### Broadcasting Testing

```ruby
test "broadcasts on create" do
  assert_broadcasts "posts", 1 do
    Post.create!(title: "Test Post")
  end
end

test "broadcasts to specific stream" do
  user = users(:one)
  assert_broadcasts "user_#{user.id}_posts", 1 do
    user.posts.create!(title: "Test Post")
  end
end
```

## Common Gotchas

### Form Validation Errors
- Always return `422` status for validation errors
- Include Turbo Stream response for error handling
- Re-render form with errors, don't redirect

```ruby
# Wrong
def create
  if @post.save
    redirect_to @post
  else
    redirect_to new_post_path, alert: "Errors occurred"
  end
end

# Right
def create
  if @post.save
    respond_to do |format|
      format.html { redirect_to @post }
      format.turbo_stream { /* success logic */ }
    end
  else
    render :new, status: :unprocessable_content
  end
end
```

### Frame Targeting Issues
- Ensure frame IDs are unique across the page
- Use `dom_id` helpers for consistent naming
- Check that target frames exist in the DOM

### Memory Leaks with Stimulus
- Always cleanup in `disconnect()` method
- Remove event listeners
- Clear timeouts and intervals

```javascript
export default class extends Controller {
  connect() {
    this.boundMethod = this.method.bind(this)
    document.addEventListener("click", this.boundMethod)
    this.timer = setInterval(this.update.bind(this), 1000)
  }

  disconnect() {
    document.removeEventListener("click", this.boundMethod)
    clearInterval(this.timer)
  }
}
```

### Turbo Stream Security
- Validate permissions before broadcasting
- Don't expose sensitive data in streams
- Use signed stream names for secure operations

## Performance Tips

### Lazy Loading
```erb
<!-- Load expensive content lazily -->
<%= turbo_frame_tag "expensive_content", src: expensive_content_path do %>
  <div class="skeleton">Loading...</div>
<% end %>
```

### Background Broadcasting
```ruby
# Use background jobs for broadcasting
after_create_commit -> { broadcast_prepend_later_to "posts" }

# Custom background job
def broadcast_to_followers
  BroadcastToFollowersJob.perform_later(self)
end
```

### Caching Strategies
```erb
<!-- Cache expensive partials -->
<%= turbo_frame_tag "cached_content" do %>
  <% cache [@user, @posts] do %>
    <%= render @posts %>
  <% end %>
<% end %>
```

### Stimulus Performance
```javascript
// Debounce expensive operations
debounce(func, delay) {
  clearTimeout(this.timeout)
  this.timeout = setTimeout(func, delay)
}

// Use passive event listeners
this.element.addEventListener("scroll", this.onScroll, { passive: true })
```

This reference guide provides the foundational patterns and best practices for building reactive Rails applications with Hotwire/Turbo. Always refer to the official documentation for the latest updates and features.