# Modal Implementation Session - November 15, 2025

## Summary

Implemented a custom event-based modal system for creating related records within forms using Turbo Frames and Stimulus.

## Problem Statement

Users needed the ability to create related records (clients, printers, filaments) from within forms without:
- Full page reloads
- Losing form state
- Navigating away from the current form

## Solution Architecture

### Custom Event Pattern

Instead of using `turbo:frame-load` event directly (which proved problematic due to event bubbling issues), implemented a custom event-based system:

1. **`modal-link` controller** - Dispatches custom `open-modal` event when links clicked
2. **`modal` controller** - Listens for `open-modal` event document-wide
3. **Loading state** - Modal opens immediately with spinner before content loads
4. **Turbo Frame** - Replaces loading content with actual form
5. **Success handling** - Turbo Stream updates specific dropdown + closes modal
6. **Error handling** - Modal stays open showing validation errors

### Key Technical Decision: Custom Events vs Direct Event Listening

**Initial Approach (Failed):**
```erb
<!-- Tried binding turbo:frame-load directly to modal container -->
<div data-action="turbo:frame-load->modal#frameLoaded">
```

**Problem:** The `turbo:frame-load` event fires on the `<turbo-frame>` element itself and doesn't reliably bubble up to parent containers.

**Final Solution:**
```javascript
// modal_link_controller.js - Dispatches custom event
document.dispatchEvent(new CustomEvent('open-modal', {
  detail: { trigger: this.element }
}))

// modal_controller.js - Listens at document level
document.addEventListener('open-modal', this.handleOpenModal.bind(this))
```

**Benefits:**
- Guaranteed event delivery (document-level)
- Immediate modal open with loading state
- Decoupled link behavior from modal implementation
- Works from any nesting context

## Implementation Details

### Files Created

1. **`app/javascript/controllers/modal_link_controller.js`**
   - Dispatches `open-modal` custom event
   - Attached to links via `data-controller="modal-link"`

2. **`docs/MODAL_IMPLEMENTATION.md`**
   - Complete implementation guide
   - Pattern examples
   - Troubleshooting guide

### Files Modified

1. **`app/javascript/controllers/modal_controller.js`**
   - Added `handleOpenModal()` method
   - Added `openWithLoading()` for immediate loading state
   - Simplified `handleSubmit()` to close on success
   - Added `handleHidden()` to clear content on close

2. **`app/views/shared/_modal.html.erb`**
   - Simplified to minimal Bootstrap modal structure
   - Removed turbo:frame-load action (no longer needed)
   - Kept turbo:submit-end for form handling

3. **`app/views/invoices/partials/form/_client.html.erb`**
   - Wrapped select in `turbo_frame_tag "client_select_frame"`
   - Changed link to button with modal-link controller

4. **`app/views/print_pricings/form_sections/_basic_information.html.erb`**
   - Wrapped select in `turbo_frame_tag "printer_select_frame"`
   - Changed link to button with modal-link controller

5. **`app/views/print_pricings/_plate_filament_fields.html.erb`**
   - Used `dom_id(f.object, :filament_select)` for unique frames
   - Added `data-filament-select-frame` for multiple instance tracking

6. **`app/views/clients/create.turbo_stream.erb`**
   - Updates `client_select_frame` only (not full page)
   - Closes modal via JavaScript
   - Clears modal content

7. **`app/views/printers/create.turbo_stream.erb`**
   - Updates `printer_select_frame` only
   - Same close pattern as clients

8. **`app/views/filaments/create.turbo_stream.erb`**
   - Uses `querySelectorAll('[data-filament-select-frame]')`
   - Updates all filament dropdowns on page
   - Triggers change events for recalculation

9. **`config/importmap.rb`**
   - Added `@popperjs/core` dependency (required by Bootstrap ESM)
   - Changed Bootstrap to ESM build (`bootstrap.esm.min.js`)

10. **`app/javascript/application.js`**
    - Imports Bootstrap ESM module
    - Makes Bootstrap globally available via `window.bootstrap`

11. **`CLAUDE.md`**
    - Added modal pattern documentation section
    - Added `bin/sync-translations` to development commands
    - Updated key files list
    - Added modal implementation guide reference

## Translation Sync Script

User also implemented `bin/sync-translations` script:

**Purpose:** Synchronize missing translation keys from English master to all locale files

**Workflow:**
1. Add keys to `config/locales/en.yml`
2. Run `bin/sync-translations`
3. Script copies missing keys with English values as placeholders
4. Developer translates placeholders to target languages

**Features:**
- Compares against English master (`en.yml`)
- Handles nested YAML structures
- Preserves existing translations
- Reports what was added to each locale
- Supports all 7 languages: en, ja, zh-CN, hi, es, fr, ar

## Lessons Learned

### 1. Bootstrap ESM vs UMD

**Problem:** Bootstrap wasn't available globally
**Solution:** Use ESM build + import in application.js + assign to window

```javascript
import * as bootstrap from "bootstrap"
window.bootstrap = bootstrap
```

### 2. Turbo Frame Event Bubbling

**Discovery:** `turbo:frame-load` doesn't bubble reliably
**Solution:** Custom events at document level provide guaranteed delivery

### 3. Loading States Matter

**UX Improvement:** Showing loading spinner immediately prevents "click and wait" confusion
**Implementation:** Open modal first, then let Turbo Frame replace content

### 4. Targeted Updates Only

**Best Practice:** Only update the specific dropdown that changed, not the whole page
**Implementation:** Wrap selects in turbo frames with unique IDs

### 5. Multiple Instance Handling

**Challenge:** Filaments can appear multiple times on one page
**Solution:** Use data attributes (`data-filament-select-frame`) and `querySelectorAll`

## Testing Recommendations

1. Test both success and error paths in turbo_stream format
2. Verify dropdown updates with new record selected
3. Confirm modal closes on success
4. Ensure modal stays open on validation errors
5. Test multiple instance updates (filaments)

## Future Enhancements

Potential improvements (not implemented):

- [ ] Modal animations/transitions
- [ ] Keyboard shortcuts (Esc already works via Bootstrap)
- [ ] Accessibility improvements (ARIA labels)
- [ ] Modal size variants (small, large, fullscreen)
- [ ] Nested modals support
- [ ] Form autosave in modals

## References

- **HotRails.dev Modal Guide:** https://www.hotrails.dev/articles/rails-modals-with-hotwire
- **Turbo Events Reference:** https://turbo.hotwired.dev/reference/events
- **Bootstrap Modal Docs:** https://getbootstrap.com/docs/5.3/components/modal/
- **Stimulus Controllers:** https://stimulus.hotwired.dev/handbook/introduction

## Session Outcome

✅ Modal system fully functional for all three use cases
✅ Documentation updated (CLAUDE.md + MODAL_IMPLEMENTATION.md)
✅ Translation sync script documented
✅ Custom event pattern established as project standard
✅ Bootstrap properly integrated via ESM

**Status:** Complete and production-ready
