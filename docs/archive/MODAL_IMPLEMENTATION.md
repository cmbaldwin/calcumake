# Modal Implementation Guide

## Overview

CalcuMake uses a custom event-based modal system built with Turbo Frames and Stimulus to enable creating related records within forms without full page reloads.

**Key Design Principle**: Modal opens immediately with loading state, then Turbo Frame replaces loading content with actual form.

## Architecture

### Components

1. **`modal_controller.js`** - Manages Bootstrap modal lifecycle and loading states
2. **`modal_link_controller.js`** - Dispatches custom `open-modal` event when links are clicked
3. **`_modal.html.erb`** - Reusable modal partial in application layout
4. **Turbo Stream responses** - Update specific dropdowns and close modal on success

### How It Works

```
User clicks link → modal_link dispatches 'open-modal' event
                 → modal_controller shows modal with loading spinner
                 → Turbo Frame fetches content
                 → Content loads into modal_content frame
                 → User submits form
                 → Success: Turbo Stream updates dropdown + closes modal
                 → Error: Modal stays open with validation errors
```

## Implementation Pattern

### 1. Add Modal Link in View

Wrap select dropdown in a turbo frame and add modal link:

```erb
<%= turbo_frame_tag "resource_select_frame" do %>
  <%= f.label :resource_id, t('resource.label'), class: "form-label" %>
  <%= f.select :resource_id,
      options_for_select(resources),
      { prompt: t('resource.select_prompt') },
      { class: "form-select" } %>
<% end %>

<div class="form-text mt-2">
  <%= t('resource.help_text') %>
  <%= link_to new_resource_path(format: :turbo_stream),
      class: "btn btn-sm btn-outline-primary ms-2",
      data: {
        controller: "modal-link",
        action: "click->modal-link#open",
        turbo_frame: "modal_content"
      } do %>
    <i class="bi bi-plus-circle"></i>
    <%= t('resource.add_new') %>
  <% end %>
</div>
```

### 2. Controller Action

Respond to turbo_stream format in the `new` action:

```ruby
def new
  @resource = current_user.resources.build

  respond_to do |format|
    format.html
    format.turbo_stream
  end
end
```

### 3. Create Turbo Stream View

**File**: `app/views/resources/new.turbo_stream.erb`

```erb
<%= turbo_stream.update "modal_content" do %>
  <div class="modal-header">
    <h5 class="modal-title"><%= t('resource.new.title') %></h5>
    <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
  </div>
  <div class="modal-body">
    <%= render "form", resource: @resource %>
  </div>
<% end %>
```

### 4. Update Create Action

Handle both success and error cases:

```ruby
def create
  @resource = current_user.resources.build(resource_params)

  respond_to do |format|
    if @resource.save
      flash.now[:notice] = t('resource.created')
      format.turbo_stream
    else
      # Re-render form with errors in modal
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("modal_content", partial: "form", locals: { resource: @resource })
      end
    end
  end
end
```

### 5. Create Success Turbo Stream Response

**File**: `app/views/resources/create.turbo_stream.erb`

```erb
<%# Update the select dropdown with new resource %>
<%= turbo_stream.update "resource_select_frame" do %>
  <label for="model_resource_id" class="form-label"><%= t('resource.label') %></label>
  <select name="model[resource_id]" id="model_resource_id" class="form-select">
    <option value=""><%= t('resource.select_prompt') %></option>
    <% current_user.resources.order(:name).each do |resource| %>
      <option value="<%= resource.id %>" <%= 'selected' if resource.id == @resource.id %>>
        <%= resource.name %>
      </option>
    <% end %>
  </select>
<% end %>

<%# Clear modal content %>
<%= turbo_stream.update "modal_content", "" %>

<%# Close modal %>
<%= turbo_stream.append "modal" do %>
  <template>
    <script>
      const modalElement = document.getElementById('modal');
      const modalInstance = bootstrap.Modal.getInstance(modalElement);
      if (modalInstance) {
        modalInstance.hide();
      }
    </script>
  </template>
<% end %>

<%# Show success notification %>
<%= turbo_stream.prepend "flash" do %>
  <%= render "layouts/flash_message", type: :notice, message: flash.now[:notice] %>
<% end %>
```

## Special Cases

### Multiple Frame Instances (e.g., Filaments)

When the same modal can update multiple dropdowns on the page:

```erb
<!-- Each filament field has unique frame ID -->
<%= turbo_frame_tag dom_id(f.object, :filament_select),
    data: { filament_select_frame: true } do %>
  <%= f.select :filament_id, ... %>
<% end %>
```

**Success response** uses JavaScript to update all frames:

```erb
<%= turbo_stream.append "modal" do %>
  <template>
    <script>
      // Update all filament select dropdowns
      const filamentFrames = document.querySelectorAll('[data-filament-select-frame]');
      const newResource = {
        id: <%= @filament.id %>,
        name: "<%= j @filament.display_name %>",
        // ... other attributes
      };

      filamentFrames.forEach(frame => {
        const select = frame.querySelector('select');
        if (select) {
          const option = document.createElement('option');
          option.value = newResource.id;
          option.textContent = newResource.name;
          option.selected = true;
          select.appendChild(option);
          select.dispatchEvent(new Event('change', { bubbles: true }));
        }
      });

      // Close modal
      const modalElement = document.getElementById('modal');
      const modalInstance = bootstrap.Modal.getInstance(modalElement);
      if (modalInstance) {
        modalInstance.hide();
      }
    </script>
  </template>
<% end %>
```

## Key Implementation Details

### Why Custom Events?

The custom `open-modal` event pattern allows:
- Immediate modal display with loading state (better UX)
- Decoupling between link triggers and modal behavior
- Document-level event handling (works from nested contexts)
- Loading spinner before Turbo frame content arrives

### Bootstrap Modal Lifecycle

1. **Open**: `bootstrap.Modal.getInstance(element).show()`
2. **Close**: `bootstrap.Modal.getInstance(element).hide()`
3. **Cleanup**: `hidden.bs.modal` event clears modal content

### Turbo Frame Best Practices

- Always specify `format: :turbo_stream` in link paths
- Wrap select dropdowns in turbo frames for targeted updates
- Use unique frame IDs (via `dom_id`) for multiple instances
- Clear modal content after successful submission

## Active Implementations

| Resource | Form Location | Frame ID | Controller Response |
|----------|---------------|----------|---------------------|
| Clients | Invoice forms | `client_select_frame` | `clients/create.turbo_stream.erb` |
| Printers | Print pricing forms | `printer_select_frame` | `printers/create.turbo_stream.erb` |
| Filaments | Plate filament fields | `dom_id(object, :filament_select)` | `filaments/create.turbo_stream.erb` |

## Testing

Ensure both HTML and turbo_stream formats work:

```ruby
test "should create resource via modal" do
  post resources_url(format: :turbo_stream), params: { resource: valid_params }

  assert_response :success
  assert_match /turbo-stream.*action="update"/, response.body
  assert_match /resource_select_frame/, response.body
end

test "should show errors in modal" do
  post resources_url(format: :turbo_stream), params: { resource: invalid_params }

  assert_response :success
  assert_match /modal_content/, response.body
  assert_match /error-explanation/, response.body
end
```

## Troubleshooting

### Modal not opening?
- Check console for `open-modal` event dispatch
- Verify Bootstrap is loaded globally (`window.bootstrap`)
- Ensure modal controller is connected

### Content not loading?
- Verify `format: :turbo_stream` in link path
- Check controller responds to turbo_stream format
- Confirm turbo_stream view exists

### Dropdown not updating?
- Verify frame ID matches between form and turbo_stream response
- Check turbo_stream.update targets correct frame
- Ensure selected option is marked in response

### Modal stays open after success?
- Verify `bootstrap.Modal.getInstance()` script runs
- Check for JavaScript errors in console
- Ensure modal close script is in turbo_stream response
