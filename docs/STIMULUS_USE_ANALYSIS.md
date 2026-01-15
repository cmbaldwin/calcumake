# Stimulus-use Analysis for CalcuMake

**Date**: 2026-01-15
**Status**: Research & Evaluation
**Decision**: Optional Enhancement (Not Critical)

## Executive Summary

[stimulus-use](https://github.com/stimulus-use/stimulus-use) is a collection of composable behaviors for Stimulus controllers that could simplify some patterns in CalcuMake. However, **the current manual implementations work well** and refactoring is not a priority. Consider stimulus-use for future features requiring intersection observers, complex debouncing, or keyboard shortcuts.

## What is stimulus-use?

A collection of ~20 mixins (7KB minified) that add common behaviors to Stimulus controllers through composition:

```javascript
import { useDebounce, useIntersection } from 'stimulus-use'

export default class extends Controller {
  connect() {
    useDebounce(this)
    useIntersection(this)
  }

  // Automatically debounced
  search() { /* ... */ }

  // Automatically called when element appears/disappears
  appear(entry) { /* ... */ }
}
```

## Available Behaviors

### Observer-Based Behaviors
| Behavior | Purpose | Use Case in CalcuMake |
|----------|---------|------------------------|
| `useClickOutside` | Detect clicks outside element | Modal/dropdown close (Bootstrap handles this) |
| `useHover` | Mouse enter/leave tracking | Image preview tooltips, hover effects |
| `useIdle` | User inactivity detection | Auto-save when idle, session warnings |
| `useIntersection` | Viewport visibility | Lazy load printer profiles, infinite scroll |
| `useMatchMedia` | CSS media query changes | Responsive layout adjustments |
| `useMutation` | DOM change detection | Dynamic form field monitoring |
| `useResize` | Element size changes | Responsive calculator layout |
| `useVisibility` | Page visibility API | Pause operations when tab inactive |
| `useWindowFocus` | Browser focus/blur | Sync data when returning to tab |
| `useWindowResize` | Window dimension changes | Responsive chart/graph sizing |
| `useHotkeys` | Keyboard shortcuts | Calculator hotkeys (Ctrl+S to save) |

### Performance Optimization
| Behavior | Purpose | Current Implementation |
|----------|---------|------------------------|
| `useDebounce` | Debounce function calls | **Manual in `search_controller.js`** (lines 12-30) |
| `useThrottle` | Throttle function calls | Not currently needed |
| `useMemo` | Cache expensive getters | Could help with calculator totals |

### Animation & Events
| Behavior | Purpose | Use Case |
|----------|---------|----------|
| `useTransition` | CSS class transitions | Toast animations, modal transitions |
| `useDispatch` | Custom events | Already using custom events (modal pattern) |

## Current Manual Implementations

### 1. Manual Debouncing (search_controller.js)
**Current code:**
```javascript
search() {
  if (this.timeout) {
    clearTimeout(this.timeout)
  }

  this.timeout = setTimeout(() => {
    this.performSearch()
  }, this.debounceDelayValue)
}
```

**With stimulus-use:**
```javascript
import { useDebounce } from 'stimulus-use'

connect() {
  useDebounce(this, { wait: 300 })
}

search() {
  this.performSearch() // Automatically debounced
}
```

### 2. Auto-save with Timer (advanced_calculator_controller.js)
**Current code:**
```javascript
setupAutoSave() {
  this.autoSaveInterval = setInterval(() => {
    this.saveToStorage()
  }, 10000)
}
```

**With stimulus-use:**
```javascript
import { useDebounce } from 'stimulus-use'

connect() {
  useDebounce(this, { wait: 10000 })
}

calculate() {
  // ... calculations
  this.saveToStorage() // Auto-debounced save
}
```

### 3. Toast Auto-dismiss (toast_controller.js)
**Current code:**
```javascript
scheduleAutoDismiss() {
  const delay = this.autoDismissValue || 5000

  setTimeout(() => {
    this.dismiss()
  }, delay)
}
```

**With stimulus-use:**
```javascript
import { useTransition } from 'stimulus-use'

connect() {
  useTransition(this, {
    enterActive: 'toastSlideIn',
    leaveActive: 'toastSlideOut',
    leaveTo: 'opacity-0'
  })
}
```

## Importmap Compatibility

### Installation via CDN
CalcuMake uses importmaps (no Node.js/npm in production). stimulus-use can be loaded from CDN:

```ruby
# config/importmap.rb
pin "stimulus-use", to: "https://esm.sh/stimulus-use@0.52.3"
```

**Considerations:**
- ✅ Works with importmaps via esm.sh or jsDelivr
- ❌ No tree-shaking (imports entire library ~7KB)
- ⚠️ CDN dependency (adds external request)
- ✅ Can import specific behaviors: `https://esm.sh/stimulus-use@0.52.3/dist/use-debounce`

## Benefits for CalcuMake

### Immediate Benefits (Low Effort)
1. **Replace manual debouncing** in `search_controller.js` - cleaner, battle-tested
2. **Cleaner auto-save** in `advanced_calculator_controller.js` - less boilerplate
3. **Better error handling** - stimulus-use handles edge cases (disconnect cleanup, etc.)

### Future Benefits (New Features)
1. **Lazy load printer profiles** - `useIntersection` for on-demand loading
2. **Keyboard shortcuts** - `useHotkeys` for power users (Ctrl+S, Ctrl+P, etc.)
3. **Responsive adjustments** - `useResize` for adaptive calculator layout
4. **Auto-pause operations** - `useVisibility` to pause when tab inactive
5. **Image lazy loading** - `useIntersection` for future image galleries

### Code Quality Benefits
- **Less boilerplate** - no manual `setTimeout`, `clearTimeout`, `addEventListener`
- **Consistent patterns** - team learns one way to add behaviors
- **Better testing** - stimulus-use is well-tested (fewer edge case bugs)
- **Easier onboarding** - documented patterns vs custom implementations

## Drawbacks & Concerns

### Technical Concerns
1. **Bundle size** - Adds 7KB (minimal but not zero)
2. **CDN dependency** - Another external request (though cached)
3. **Learning curve** - Team needs to learn stimulus-use API
4. **Limited tree-shaking** - Importmaps can't tree-shake, imports full library
5. **Maintenance** - Another dependency to keep updated

### Current State Assessment
1. **Manual implementations work fine** - No bugs, performance is good
2. **Small codebase** - Only 35 controllers, manual patterns are manageable
3. **Team familiarity** - Current patterns are well understood
4. **No pain points** - No one is complaining about manual debouncing

## Recommendations

### ✅ Consider stimulus-use for:
1. **New features** requiring intersection observers (lazy loading, infinite scroll)
2. **Complex keyboard shortcuts** (`useHotkeys` is hard to implement manually)
3. **Advanced hover effects** (multiple states, timing)
4. **Viewport-based animations** (scroll-triggered animations)
5. **Idle detection** (session timeouts, auto-save when user steps away)

### ❌ Don't use stimulus-use for:
1. **Refactoring existing working code** - not worth the effort
2. **Simple debouncing** - current implementation is fine (5 lines of code)
3. **Bootstrap-handled behaviors** - modals, dropdowns, tooltips already work
4. **One-off behaviors** - if you only need it once, write it inline

### 🤔 Evaluate case-by-case for:
1. **Performance optimization** - `useMemo` for expensive getters (calculator totals?)
2. **Animation timing** - `useTransition` vs manual `setTimeout`
3. **Window resize** - `useWindowResize` vs manual resize listeners

## Implementation Plan (If Adopted)

### Phase 1: Add to Project (15 minutes)
```ruby
# config/importmap.rb
pin "stimulus-use", to: "https://esm.sh/stimulus-use@0.52.3"
```

### Phase 2: Try in New Features (Ongoing)
- Use stimulus-use for **new** controllers with complex behaviors
- Leave existing controllers unchanged unless refactoring anyway

### Phase 3: Document Usage (30 minutes)
- Add stimulus-use examples to `CLAUDE.md`
- Create guide for team: "When to use stimulus-use vs manual implementation"

## Specific Use Cases in CalcuMake

### High Value (Worth Considering)
1. **Lazy load printer profiles** in advanced calculator
   ```javascript
   import { useIntersection } from 'stimulus-use'

   connect() {
     useIntersection(this)
   }

   appear() {
     this.loadPrinterProfiles() // Only load when visible
   }
   ```

2. **Keyboard shortcuts** in calculator
   ```javascript
   import { useHotkeys } from 'stimulus-use'

   connect() {
     useHotkeys(this, {
       'ctrl+s': [this.saveToStorage],
       'ctrl+p': [this.exportPDF],
       'ctrl+c': [this.calculate]
     })
   }
   ```

3. **Idle auto-save** instead of interval
   ```javascript
   import { useIdle } from 'stimulus-use'

   connect() {
     useIdle(this, { ms: 5000 })
   }

   away() {
     this.saveToStorage() // Save when user goes idle
   }
   ```

### Low Value (Not Worth It)
1. **Replace search debouncing** - current code is 5 lines and works perfectly
2. **Modal click outside** - Bootstrap handles this already
3. **Toast animations** - current implementation is simple and effective

## Decision Matrix

| Feature | Manual Implementation | stimulus-use | Recommendation |
|---------|----------------------|--------------|----------------|
| Simple debouncing | ✅ Easy, 5 lines | ⚠️ Overkill | Keep manual |
| Search debouncing | ✅ Works well | ✅ Slightly cleaner | Keep manual |
| Intersection observer | ❌ Complex, error-prone | ✅ Much easier | **Use stimulus-use** |
| Keyboard shortcuts | ❌ Complex, many edge cases | ✅ Battle-tested | **Use stimulus-use** |
| Click outside | ✅ Bootstrap handles | ⚠️ Redundant | Keep Bootstrap |
| Hover effects | ✅ CSS works | ⚠️ Overkill for CSS | Keep CSS |
| Idle detection | ❌ Tricky to get right | ✅ Handles edge cases | **Use stimulus-use** |
| Window resize | ✅ Simple listener | ⚠️ Marginal benefit | Keep manual |

## Conclusion

**stimulus-use is useful but not critical for CalcuMake.**

### Current State (January 2026)
- ✅ Manual implementations work well
- ✅ Codebase is small and maintainable
- ✅ Team understands current patterns
- ❌ No pain points requiring stimulus-use

### Future Recommendation
- ⏸️ **Don't add now** - no immediate need
- 🔍 **Reevaluate when** building features requiring:
  - Intersection observers (lazy loading, infinite scroll)
  - Keyboard shortcuts (power user features)
  - Idle detection (advanced auto-save)
  - Complex hover states (image galleries)
- 📚 **Keep in toolbox** - good to know it exists for future features

### Action Items
- [ ] Bookmark [stimulus-use docs](https://stimulus-use.github.io/stimulus-use)
- [ ] Add this analysis to `docs/` for future reference
- [ ] Revisit decision when building lazy loading or keyboard shortcuts
- [ ] Consider for major refactoring (e.g., if debouncing becomes complex)

---

## Sources
- [GitHub - stimulus-use/stimulus-use](https://github.com/stimulus-use/stimulus-use)
- [Introducing Stimulus-use composable behaviors - DEV Community](https://dev.to/adrienpoly/introducing-stimulus-use-composable-behaviors-for-your-controllers-mlc)
- [Hotwire Discussion - Stimulus-use announcement](https://discuss.hotwired.dev/t/introducing-stimulus-use-a-collection-of-composable-behaviors/1173)
- [npm - stimulus-use package](https://www.npmjs.com/package/stimulus-use)
