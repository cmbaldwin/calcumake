# Info Popup System - Systematic Rollout Plan

## Overview
This document outlines the systematic rollout plan for adding info popups throughout the CalcuMake application. Info popups provide inline documentation to help users understand the purpose and usage of form fields and features.

## Completed ✅

### Core Infrastructure
- [x] Database migration for `info_popups_enabled` user preference
- [x] `Shared::InfoPopupComponent` ViewComponent
- [x] `info_popup_controller.js` Stimulus controller
- [x] `info_toggle_controller.js` Stimulus controller for global toggle
- [x] Toggle switch in navbar (next to locale switcher)
- [x] Translation keys in `config/locales/en/info_popups.yml`
- [x] Component tests in `test/components/shared/info_popup_component_test.rb`
- [x] CSS-first tooltips with progressive enhancement
- [x] Mobile popover support (tap-to-show)
- [x] Desktop tooltip support (hover-to-show)
- [x] Performance optimizations (memoization, lazy loading, skip rendering)

### First Implementation
- [x] Print Pricing form - Basic Information section
  - Job Name field
  - Printer selection field

## Phase 1: Critical User Flows (High Priority)

### Print Pricing Forms
**File:** `app/views/print_pricings/form_sections/`

**Basic Information** (`_basic_information.html.erb`)
- [x] Job Name
- [x] Printer selection
- [ ] Start with one print checkbox

**Plates Section** (`_plates.html.erb`)
For each plate:
- [ ] Printing time
- [ ] Filament weight
- [ ] Filament selection
- [ ] Filament cost per gram

**Filament List** (within plates)
For each filament in a plate:
- [ ] Filament type
- [ ] Weight
- [ ] Cost per gram

**Labor Costs** (`_labor_costs.html.erb`)
- [ ] Prep time minutes
- [ ] Prep cost per hour
- [ ] Postprocessing time minutes
- [ ] Postprocessing cost per hour

**Other Costs** (`_other_costs.html.erb`)
- [ ] Other costs amount
- [ ] VAT percentage
- [ ] Listing cost percentage
- [ ] Payment processing cost percentage
- [ ] Filament markup percentage

### Invoice Forms
**File:** `app/views/invoices/_form.html.erb`

**Basic Fields**
- [ ] Client selection
- [ ] Status
- [ ] Issue date
- [ ] Due date
- [ ] Invoice number
- [ ] Notes

**Line Items**
- [ ] Description
- [ ] Quantity
- [ ] Unit price
- [ ] Category

### Printer Management
**File:** `app/views/printers/_form.html.erb`

- [ ] Printer name
- [ ] Power consumption (watts)
- [ ] Initial cost

### Filament Management
**File:** `app/views/filaments/_form.html.erb`

- [ ] Filament name
- [ ] Color
- [ ] Material type
- [ ] Cost per gram
- [ ] Total weight
- [ ] Remaining weight

### Client Management
**File:** `app/views/clients/_form.html.erb`

- [ ] Client name
- [ ] Email
- [ ] Phone
- [ ] Address
- [ ] Notes

## Phase 2: User Profile & Settings (Medium Priority)

### Profile Settings
**File:** `app/views/user_profiles/show.html.erb` and `edit.html.erb`

**Currency & Energy**
- [ ] Default currency
- [ ] Energy cost per kWh

**Company Information**
- [ ] Company name
- [ ] Company address
- [ ] Company email
- [ ] Company phone
- [ ] Payment details
- [ ] Invoice notes
- [ ] Company logo

**Default Values**
- [ ] Default prep time
- [ ] Default prep cost per hour
- [ ] Default postprocessing time
- [ ] Default postprocessing cost per hour
- [ ] Default other costs
- [ ] Default VAT percentage
- [ ] Default listing cost percentage
- [ ] Default payment processing cost percentage
- [ ] Default filament markup percentage

## Phase 3: Dashboard & Stats (Low Priority)

### Dashboard Statistics
**File:** `app/views/print_pricings/index.html.erb`

- [ ] Total print pricings count
- [ ] Total revenue
- [ ] Total electricity cost
- [ ] Machine payoff progress
- [ ] Average job cost
- [ ] Most used printer

### Usage Stats Component
**File:** `app/components/usage_stats_component.html.erb`

- [ ] Plan limit indicator
- [ ] Usage percentage
- [ ] Upgrade prompts

## Phase 4: Advanced Calculator (Public Feature)

### Public Pricing Calculator
**File:** `app/views/pages/pricing_calculator.html.erb`

Similar to authenticated print pricing forms, but for anonymous users:
- [ ] All plate fields
- [ ] All filament fields
- [ ] All cost calculation fields
- [ ] Export features (PDF/CSV)

## Implementation Checklist for Each Field

When adding an info popup to a field, follow this checklist:

1. **Add the component to the view:**
   ```erb
   <%= f.label :field_name, class: "form-label d-inline-block" %>
   <%= render Shared::InfoPopupComponent.new(translation_key: "info_popups.category.field_name") %>
   ```

2. **Verify translation key exists in `config/locales/en/info_popups.yml`:**
   ```yaml
   en:
     info_popups:
       category:
         field_name: "Helpful description of what this field is for"
   ```

3. **Run translation sync** (if API key available):
   ```bash
   bin/sync-translations
   ```

4. **Test the popup:**
   - [ ] Hover over the (i) icon
   - [ ] Verify tooltip appears with correct content
   - [ ] Test in multiple languages
   - [ ] Test toggle on/off functionality
   - [ ] Verify keyboard accessibility (Tab + Enter/Space)

5. **Commit changes:**
   ```bash
   git add .
   git commit -m "Add info popup for [category] [field_name]"
   ```

## Translation Key Naming Convention

Follow this structure for all info popup translation keys:

```
info_popups.
  ├── toggle (system controls)
  ├── print_pricings
  │   ├── [field_name]
  │   └── plate
  │       ├── [field_name]
  │       └── filaments
  │           └── [field_name]
  ├── invoices
  │   ├── [field_name]
  │   └── line_item
  │       └── [field_name]
  ├── printers
  │   └── [field_name]
  ├── filaments
  │   └── [field_name]
  ├── clients
  │   └── [field_name]
  └── profile
      ├── [field_name]
      └── defaults
          └── [field_name]
```

## Writing Effective Tooltips

### Guidelines

1. **Be concise:** Keep tooltips to 1-2 sentences max
2. **Focus on purpose:** Explain WHAT the field is for, not HOW to fill it
3. **Provide context:** Explain how the field affects calculations or other features
4. **Use examples:** Include specific examples when helpful (e.g., "e.g., 'Prusa MK4'")
5. **Mention defaults:** If a field auto-fills or has a default, mention it
6. **Avoid jargon:** Use simple, clear language

### Good Examples

✅ "Total time this plate takes to print, in hours. This affects electricity and machine costs."
✅ "Select which 3D printer you'll use for this job. This affects electricity cost calculations."
✅ "Cost per gram for this filament. Auto-filled from your filament library."

### Bad Examples

❌ "Enter the printing time" (too vague)
❌ "The amount of time in hours that the printer will take to complete the print job for this specific plate configuration" (too verbose)
❌ "Input numerical value representing temporal duration" (too technical/jargon)

## Testing Strategy

### Manual Testing
1. Enable info popups via navbar toggle
2. Navigate to each form
3. Hover over each info icon
4. Verify tooltip content is helpful and accurate
5. Disable info popups
6. Verify all icons are hidden
7. Test in all 7 supported languages

### Automated Testing
Component tests already exist in:
- `test/components/shared/info_popup_component_test.rb`

Additional system tests should be added for:
- [ ] Toggle functionality in navbar
- [ ] Persistence of user preference
- [ ] Visibility of popups based on preference

## Accessibility Considerations

The info popup system includes:
- ✅ `role="button"` for semantic meaning
- ✅ `tabindex="0"` for keyboard navigation
- ✅ Hover AND focus triggers for tooltips
- ✅ Bootstrap Tooltip ARIA attributes
- ✅ Text alternatives via tooltip content

Future enhancements:
- [ ] Screen reader announcements when popups are toggled
- [ ] Keyboard shortcut to toggle all popups (e.g., Alt+H)
- [ ] Persistent popup mode for users who need constant reference

## Mobile User Experience

### Adaptive Tooltip Strategy

The info popup system uses different approaches for mobile vs desktop to provide optimal UX:

#### Desktop Experience (≥768px)
- **Trigger:** Hover or focus
- **Component:** Bootstrap Tooltip
- **Behavior:** Appears on mouse hover with 200ms delay
- **Dismissal:** Automatic on mouse leave
- **Visual:** Small, compact tooltip
- **Performance:** ~1-5ms per tooltip initialization

#### Mobile Experience (<768px)
- **Trigger:** Tap/focus
- **Component:** Bootstrap Popover
- **Behavior:** Appears on tap, requires explicit dismissal
- **Dismissal:** Tap outside popover or tap another element
- **Visual:** Larger, more readable popover (90vw max-width)
- **Performance:** ~1-5ms per popover initialization

### Why Popovers on Mobile?

**Mobile devices have unique constraints:**
1. ❌ No hover state (touch-based interaction)
2. ❌ Smaller screens need larger hit targets
3. ❌ Tooltips can be hard to read on small screens
4. ✅ Explicit tap-to-show is more intentional
5. ✅ Popovers stay visible until dismissed (better for reading)
6. ✅ Larger text size and padding for mobile readability

### Mobile Popover Features

**Optimized for Touch:**
- Larger tap target (info icon)
- Focus-based trigger (tap to show)
- Tap-away-to-dismiss behavior
- Responsive max-width (90vw, capped at 300px)
- Comfortable padding (0.75rem)
- Slightly larger font size (0.9rem)
- Enhanced shadow for better visibility

**Accessibility:**
- Works with screen readers
- Keyboard accessible (focus trigger)
- Respects `prefers-reduced-motion`
- Proper ARIA attributes from Bootstrap

### Testing Mobile Experience

**Manual Testing:**
1. Open CalcuMake on mobile device or use browser dev tools (F12 → Device toolbar)
2. Navigate to any form with info popups (e.g., New Print Pricing)
3. Tap an info icon
4. ✅ Popover should appear immediately
5. ✅ Popover should be readable (not too small)
6. ✅ Tap outside to dismiss
7. ✅ Tap another icon to switch popovers

**Browser DevTools Testing:**
- Chrome: F12 → Toggle device toolbar (Ctrl+Shift+M)
- Firefox: F12 → Responsive Design Mode (Ctrl+Shift+M)
- Safari: Develop → Enter Responsive Design Mode
- Set viewport to mobile (e.g., iPhone 12 Pro, 390x844)
- Test tap interactions

## Performance Considerations

### Optimized Implementation ⚡

**Multi-Layer Performance Strategy:**

#### 1. **CSS-First Approach (Zero JavaScript)**
- Pure CSS tooltips using `::before` and `::after` pseudo-elements
- Instant rendering with no initialization overhead
- Works immediately on page load
- Fallback for users with JavaScript disabled
- **Performance:** 0ms initialization time

#### 2. **Adaptive Mobile/Desktop Strategy**
- **Mobile (<768px):** Bootstrap Popovers with tap-to-show (focus trigger)
- **Desktop (≥768px):** Bootstrap Tooltips with hover-to-show
- **Why different?** Mobile has no hover, needs explicit tap interaction
- Respects `prefers-reduced-motion` accessibility setting
- **Performance:** 200ms delay on desktop hover prevents accidental triggers

#### 3. **Request-Level Memoization**
- `info_popups_enabled?` helper method caches user preference
- Single DB query per request instead of per popup
- Reduces DB overhead from 50+ queries to 1 query per page
- **Performance:** Saves ~5ms × number of popups per page

#### 4. **Component-Level Skip Rendering**
- `render?` method returns false when popups disabled
- Popups don't render at all when toggled off
- Saves component render time AND DOM size
- **Performance:** 100% saving when disabled

#### 5. **Smart Tooltip Initialization**
- Lazy initialization only when needed
- Checks conditions before creating Bootstrap instance
- Disposes properly to prevent memory leaks
- **Performance:** ~1-5ms per tooltip (only on desktop)

### Performance Benchmarks

| Page Type | Popups | Toggled OFF | Mobile (Popover) | Desktop (Tooltip) |
|-----------|--------|-------------|------------------|-------------------|
| **Small form** | 5-10 | ~0ms | ~5-50ms | ~10-50ms |
| **Medium form** | 15-25 | ~0ms | ~15-125ms | ~30-125ms |
| **Large form** | 30-50 | ~0ms | ~30-250ms | ~60-250ms |

**Key Insights:**
- Mobile popovers: Similar overhead to desktop tooltips (~1-5ms each)
- Desktop tooltips: Includes 200ms hover delay for better UX
- Toggled OFF: Zero overhead regardless of device
- Lazy initialization: Only creates instances when first needed

### Memory Impact

**Toggle OFF:**
- ✅ No component rendering
- ✅ No DOM elements added
- ✅ No JavaScript initialization
- ✅ Zero memory footprint

**CSS-Only (Mobile):**
- ✅ No JavaScript objects
- ✅ Minimal DOM attributes
- ✅ CSS loaded once globally
- ✅ ~1-2KB total overhead

**Bootstrap Enhanced (Desktop):**
- Popper.js instances: ~2-5KB per tooltip
- 50 tooltips = ~100-250KB memory
- Properly disposed on toggle off
- Acceptable for desktop browsers

### Network Impact

| Resource | Size | When Loaded |
|----------|------|-------------|
| `info_popup.css` | ~3KB | Every page (cached) |
| Bootstrap Tooltip | ~0KB | Already loaded |
| Popper.js | ~0KB | Already loaded |
| **Total Additional** | **~3KB** | **One-time download** |

### Caching Strategy

#### Application-Level Caching
```ruby
# ApplicationController helper (memoized)
def info_popups_enabled?
  @info_popups_enabled ||= user_signed_in? ? current_user.info_popups_enabled? : true
end
```

#### Fragment Caching (Future Enhancement)
```erb
<%# Form sections with many popups %>
<% cache ["form_section", current_user, info_popups_enabled?, I18n.locale] do %>
  <%= render "form_section_with_popups" %>
<% end %>
```

#### Browser Caching
- CSS file cached with asset pipeline
- Translation lookups cached by Rails I18n
- LocalStorage for toggle state (instant client-side)

### Completed Optimizations ✅
- [x] CSS-only tooltips for instant rendering
- [x] Progressive enhancement (desktop-only Bootstrap)
- [x] Request-level memoization of user preference
- [x] Component skip rendering when disabled
- [x] Lazy initialization with conditions check
- [x] Respects `prefers-reduced-motion`
- [x] Mobile-optimized (no JS overhead)
- [x] Proper cleanup and disposal

### Future Optimizations
- [ ] Fragment cache form sections with popups
- [ ] Intersection Observer for lazy popup initialization
- [ ] Service Worker caching for offline support
- [ ] Compress tooltip content for long descriptions

## Rollout Timeline

### Week 1 (Current)
- [x] Complete core infrastructure
- [x] First implementation in Print Pricing form
- [ ] Complete Phase 1: Print Pricing forms
- [ ] Complete Phase 1: Invoice forms

### Week 2
- [ ] Complete Phase 1: Printer, Filament, Client forms
- [ ] Complete Phase 2: User Profile settings

### Week 3
- [ ] Complete Phase 3: Dashboard stats
- [ ] Complete Phase 4: Public calculator

### Week 4
- [ ] Translation verification
- [ ] User testing and feedback
- [ ] Final adjustments and deployment

## Metrics for Success

Track these metrics post-deployment:
- [ ] Support ticket reduction for "How do I use X?" questions
- [ ] User engagement with info popups (track toggle usage)
- [ ] Time to complete first print pricing (should decrease)
- [ ] User feedback on tooltip helpfulness

## Future Enhancements

### Contextual Help System
- [ ] Link tooltips to full documentation pages
- [ ] Video tutorials for complex features
- [ ] Interactive guided tours for new users

### Smart Defaults
- [ ] Pre-fill fields based on user's previous inputs
- [ ] Suggest common values based on printer type

### Analytics
- [ ] Track which tooltips are viewed most
- [ ] Identify confusing fields based on tooltip usage
- [ ] A/B test tooltip content for clarity

## References

- Component: `app/components/shared/info_popup_component.rb`
- Stimulus Controller: `app/javascript/controllers/info_popup_controller.js`
- Toggle Controller: `app/javascript/controllers/info_toggle_controller.js`
- Translations: `config/locales/en/info_popups.yml`
- Tests: `test/components/shared/info_popup_component_test.rb`
- Migration: `db/migrate/XXXXXX_add_info_popups_enabled_to_users.rb`

---

**Last Updated:** 2025-11-28
**Status:** Phase 1 in progress
**Owner:** Development Team
