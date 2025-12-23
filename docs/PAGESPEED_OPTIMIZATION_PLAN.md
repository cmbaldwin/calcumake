# PageSpeed Insights Optimization Plan

## Current Performance Score: 67/100

**Tested Page**: `/3d-print-pricing-calculator` (Advanced Calculator)
**Test Conditions**: Mobile (Moto G Power), Slow 4G, HeadlessChromium

### Key Metrics (Before)
| Metric | Value | Target |
|--------|-------|--------|
| First Contentful Paint (FCP) | 4.6s | <1.8s |
| Largest Contentful Paint (LCP) | 5.2s | <2.5s |
| Total Blocking Time (TBT) | 20ms | <200ms ✅ |
| Cumulative Layout Shift (CLS) | 0 | <0.1 ✅ |
| Speed Index | 5.6s | <3.4s |

---

## Root Cause Analysis

### 1. Render-Blocking CSS (~1,000ms delay)
**Current State**: Bootstrap CSS loaded via `@import` in `application.css`
```css
@import url("https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css");
@import url("https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css");
```

**Problem**: CSS `@import` blocks rendering - browser must download main CSS, parse it, then start downloading imported files sequentially.

### 2. LCP Element Render Delay (2,420ms)
**LCP Element**: `<h1 class="display-4 fw-bold text-primary mb-3">`

**Problem**: The hero headline waits for all CSS to load before rendering. No critical CSS is inlined.

### 3. Unused CSS (~37 KiB)
- Bootstrap CSS: 24 KiB unused
- Bootstrap Icons: 13 KiB unused (loading entire icon font)
- Lexxy CSS: Loading for all pages (only needed for rich text editor)

### 4. Unminified JavaScript (~34 KiB savings)
- `lexxy.js`: 173 KiB unminified

### 5. Third-Party Script Impact
| Script | Transfer Size | Main Thread Time |
|--------|--------------|------------------|
| Google Tag Manager | 140 KiB | 128ms |
| Cloudflare Beacon | 7 KiB | 7ms |
| esm.sh (jsPDF) | 178 KiB | 0ms (async) |

### 6. Missing Connection Optimizations
No `preconnect` or `dns-prefetch` hints for external domains.

---

## Optimization Plan

### Phase 1: Critical Rendering Path (Target: +15-20 points)

#### 1.1 Replace CSS @import with preload links
**File**: `app/views/layouts/application.html.erb`

**Current**:
```erb
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
<%= stylesheet_link_tag "lexxy", "data-turbo-track": "reload" %>
```

**Optimized**:
```erb
<%# Preconnect to CDN domains for faster resource loading %>
<link rel="preconnect" href="https://cdn.jsdelivr.net" crossorigin>
<link rel="dns-prefetch" href="https://cdn.jsdelivr.net">
<link rel="preconnect" href="https://esm.sh" crossorigin>
<link rel="dns-prefetch" href="https://esm.sh">

<%# Preload critical CSS %>
<link rel="preload" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" as="style">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css">

<%# Bootstrap Icons loaded non-blocking with font-display %>
<link rel="preload" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" as="style" onload="this.onload=null;this.rel='stylesheet'">
<noscript><link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css"></noscript>

<%# Application CSS (without @import) %>
<%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
```

**Impact**: Eliminates ~1,000ms render-blocking time

#### 1.2 Remove @import from application.css
**File**: `app/assets/stylesheets/application.css`

Remove lines 7-13 (CSS imports) - they'll be loaded via HTML link tags instead.

**Impact**: CSS loads in parallel instead of sequentially

#### 1.3 Add font-display: swap for Bootstrap Icons
Create override stylesheet or use local font files with proper font-display.

**Impact**: Text remains visible during icon font load

---

### Phase 2: Lazy Loading Non-Critical Resources (Target: +5-10 points)

#### 2.1 Conditionally load Lexxy CSS/JS
**Problem**: Lexxy (rich text editor) loads on every page but is only used in admin/authenticated areas.

**Solution**: Load Lexxy only when needed.

**File**: `app/views/layouts/application.html.erb`
```erb
<% if user_signed_in? && controller_needs_lexxy? %>
  <%= stylesheet_link_tag "lexxy", "data-turbo-track": "reload" %>
<% end %>
```

**File**: `app/helpers/application_helper.rb`
```ruby
def controller_needs_lexxy?
  # Only load for controllers that use rich text editing
  %w[invoices print_pricings].include?(controller_name)
end
```

**Impact**: Saves 5-10 KiB on public pages

#### 2.2 Defer Google Analytics initialization
**Current**: GTM inline script runs immediately

**Optimized**: Use `requestIdleCallback` or `setTimeout` to defer non-critical tracking.

```html
<script>
  // Defer GA initialization until after page load
  window.addEventListener('load', function() {
    requestIdleCallback(function() {
      // Initialize gtag after page is interactive
      gtag('js', new Date());
      gtag('config', 'G-SBESSBTQRQ');
    });
  });
</script>
```

**Impact**: Reduces main thread blocking by ~100ms

---

### Phase 3: CSS Optimization (Target: +5-10 points)

#### 3.1 Create Critical CSS for Landing Page
Extract minimal CSS needed for above-the-fold content and inline it.

**Critical CSS includes**:
- CSS custom properties (`:root` variables)
- Body and container styles
- Hero section styles
- Button primary styles
- Card basic styles
- Text utilities used in hero

**File**: `app/views/pages/landing.html.erb` (add to head)
```erb
<% content_for :head do %>
<style>
  /* Critical CSS for landing page - inline for fastest FCP */
  :root {
    --bs-primary: #c8102e;
    --bs-primary-rgb: 200, 16, 46;
    --bs-secondary: #d2691e;
    /* ... minimal variables */
  }
  body { background: linear-gradient(135deg, #fff8dc 0%, #f5f5dc 100%); min-height: 100vh; }
  .container { width: 100%; max-width: 1320px; margin: 0 auto; padding: 0 12px; }
  .hero-section { padding: 1rem; border-radius: 1rem; }
  .display-4 { font-size: calc(1.475rem + 2.7vw); font-weight: 300; }
  .fw-bold { font-weight: 700 !important; }
  .text-primary { color: var(--bs-primary) !important; }
  .btn { display: inline-block; padding: 0.6rem 1.2rem; border-radius: 0.375rem; text-decoration: none; }
  .btn-primary { background: var(--bs-primary); color: white; }
  .btn-lg { padding: 0.75rem 1.5rem; font-size: 1.125rem; }
  /* ... hero-specific styles */
</style>
<% end %>
```

**Impact**: LCP element renders without waiting for full CSS (~1-2s improvement)

#### 3.2 Split CSS by page type
Create separate stylesheets for public vs authenticated pages:
- `public.css` - Landing page, calculator (minimal)
- `authenticated.css` - Full app styles

**Impact**: Reduces unused CSS on public pages

---

### Phase 4: JavaScript Optimization (Target: +3-5 points)

#### 4.1 Lazy-load jsPDF and html2canvas
These libraries are only needed when user clicks "Export PDF" or "Export CSV".

**File**: `app/javascript/controllers/mixins/export_mixin.js`
```javascript
// Change from static import to dynamic import
async exportToPDF() {
  // Lazy load only when needed
  const [{ default: jsPDF }, { default: html2canvas }] = await Promise.all([
    import('jspdf'),
    import('html2canvas')
  ]);

  // Continue with export logic...
}
```

**Impact**: Saves ~178 KiB from initial bundle

#### 4.2 Minify Lexxy JavaScript
The `lexxy.js` file (173 KiB) can save ~34 KiB with minification.

**Options**:
1. Use minified version from gem (if available)
2. Configure Propshaft to minify JS in production
3. Use terser via a build step (not recommended for importmap-only project)

**Recommendation**: Check if lexxy gem provides `.min.js` version.

---

### Phase 5: Resource Hints (Target: +2-3 points)

#### 5.1 Add comprehensive resource hints
**File**: `app/views/layouts/application.html.erb`

```erb
<%# Connection hints for external resources %>
<link rel="preconnect" href="https://cdn.jsdelivr.net" crossorigin>
<link rel="preconnect" href="https://esm.sh" crossorigin>
<link rel="preconnect" href="https://www.googletagmanager.com">
<link rel="preconnect" href="https://www.google-analytics.com">

<%# DNS prefetch for secondary resources %>
<link rel="dns-prefetch" href="https://static.cloudflareinsights.com">
<link rel="dns-prefetch" href="https://ipapi.co">
```

**Impact**: Reduces connection time for external resources

#### 5.2 Preload LCP element font
If using a web font for the hero headline, preload it:
```erb
<link rel="preload" href="/path/to/font.woff2" as="font" type="font/woff2" crossorigin>
```

---

### Phase 6: Cache Optimization

#### 6.1 Configure longer cache for esm.sh resources
The PageSpeed report shows esm.sh resources have only 1-hour cache.

**Options**:
1. Self-host jsPDF and html2canvas (better cache control)
2. Use jsdelivr CDN instead (1-year cache)
3. Configure service worker to cache these resources

**Recommended**: Use jsdelivr CDN with version pinning:
```ruby
# config/importmap.rb
pin "jspdf", to: "https://cdn.jsdelivr.net/npm/jspdf@3.0.3/dist/jspdf.es.min.js"
```

---

## Implementation Priority

### Quick Wins (Can implement immediately)
1. ✅ Add preconnect/dns-prefetch hints (Phase 5.1)
2. ✅ Replace CSS @import with link tags (Phase 1.1)
3. ✅ Defer GA initialization (Phase 2.2)

### Medium Effort (1-2 hours each)
4. Remove @import from application.css (Phase 1.2)
5. Conditionally load Lexxy (Phase 2.1)
6. Lazy-load export libraries (Phase 4.1)

### Larger Changes (2-4 hours each)
7. Critical CSS inlining (Phase 3.1)
8. CSS splitting (Phase 3.2)
9. Self-host or switch CDN for export libraries (Phase 6.1)

---

## Expected Results

| Metric | Before | After (Est.) | Improvement |
|--------|--------|--------------|-------------|
| Performance Score | 67 | 85-90 | +18-23 |
| FCP | 4.6s | 2.0-2.5s | -2.1-2.6s |
| LCP | 5.2s | 2.5-3.0s | -2.2-2.7s |
| Speed Index | 5.6s | 3.0-3.5s | -2.1-2.6s |

---

## Testing Strategy

1. **Local Testing**:
   ```bash
   # Run lighthouse locally
   npx lighthouse https://localhost:3000/3d-print-pricing-calculator --view
   ```

2. **Staging Testing**:
   - Deploy changes to staging
   - Run PageSpeed Insights on staging URL
   - Compare before/after metrics

3. **Production Monitoring**:
   - Monitor Core Web Vitals in Google Search Console
   - Set up real-user monitoring (RUM) with Web Vitals library

---

## Files to Modify

| File | Changes |
|------|---------|
| `app/views/layouts/application.html.erb` | Add preconnect, preload, defer GA |
| `app/assets/stylesheets/application.css` | Remove @import statements |
| `app/assets/stylesheets/critical.css` | New - critical CSS for above-fold |
| `app/views/pages/landing.html.erb` | Inline critical CSS |
| `app/javascript/controllers/mixins/export_mixin.js` | Dynamic imports |
| `app/helpers/application_helper.rb` | Add controller_needs_lexxy? |
| `config/importmap.rb` | Update jsPDF CDN source |

---

## Risk Assessment

| Change | Risk | Mitigation |
|--------|------|------------|
| CSS restructuring | Layout breaks | Test all pages after changes |
| Dynamic imports | Export might fail | Add loading indicators |
| GA deferral | Data loss | Verify events still tracked |
| Remove Lexxy from public | Editor breaks | Test all authenticated flows |

---

## Notes

- **Rails 8 Importmap Project**: No build tools available, optimizations must work with importmaps
- **TBT and CLS already good**: Focus on FCP and LCP improvements
- **Mobile-first**: All optimizations target mobile performance (desktop will improve too)
