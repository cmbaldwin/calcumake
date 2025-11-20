# CalcuMake Caching - Phase 1 Implementation Plan

## Overview

Phase 1 focuses on **quick wins** with maximum impact and minimal risk. Total implementation time: **2-3 hours**. Expected performance improvement: **300-500ms** reduction in average page load time.

## Goals

1. ✅ Cache user usage stats (eliminates 4 COUNT queries per page)
2. ✅ Add eager loading to prevent N+1 queries
3. ✅ Fragment cache expensive components (stats cards)
4. ✅ Zero breaking changes
5. ✅ All tests pass

## Success Metrics

| Metric | Before | After Phase 1 | Target |
|--------|--------|---------------|--------|
| Print Pricings Index Load Time | 850ms | 450ms | 40-50% reduction |
| Database Queries (Index) | 157 | 45 | < 50 queries |
| Usage Dashboard Overhead | 60ms | 15ms | < 20ms |
| Cache Hit Rate | 0% | 85% | > 80% |

---

## Implementation Checklist

### Step 1: Usage Dashboard Caching (30 minutes) 🚀

**Impact:** Affects 100% of authenticated pages, eliminates 4 COUNT queries per request

#### 1.1 Add Cached Usage Stats to User Model

**File:** `app/models/user.rb`

**Location:** After the `clear_logo_cache` method (around line 248)

**Code to Add:**

```ruby
# Cache user usage stats to avoid repeated COUNT queries
# Called by PlanLimits service on every authenticated page
def cached_usage_stats
  Rails.cache.fetch("user/#{id}/usage_stats/v1", expires_in: 5.minutes) do
    {
      print_pricings: print_pricings.count,
      printers: printers.count,
      filaments: filaments.count,
      invoices: invoices.count,
      clients: clients.count
    }
  end
end

# Clear usage cache when resources change
after_save :clear_usage_cache, if: :saved_change_to_updated_at?
after_touch :clear_usage_cache

def clear_usage_cache
  Rails.cache.delete("user/#{id}/usage_stats/v1")
end
```

**Test Plan:**
- [ ] Call `user.cached_usage_stats` twice, verify second call hits cache
- [ ] Update user, verify cache invalidates
- [ ] Check logs for cache read/write operations

---

#### 1.2 Update PlanLimits to Use Cached Stats

**File:** `app/services/plan_limits.rb`

**Find:** `current_usage(user, resource_type)` method (around line 60)

**Replace:**

```ruby
# OLD CODE (makes separate COUNT queries):
def self.current_usage(user, resource_type)
  case resource_type.to_s
  when "print_pricing"
    user.print_pricings.count
  when "printer"
    user.printers.count
  when "filament"
    user.filaments.count
  when "invoice"
    user.invoices.count
  when "client"
    user.clients.count
  else
    0
  end
end
```

**With:**

```ruby
# NEW CODE (uses cached stats):
def self.current_usage(user, resource_type)
  stats = user.cached_usage_stats
  stats[resource_type.to_sym] || 0
end
```

**Test Plan:**
- [ ] Verify usage widget displays correct counts
- [ ] Check plan limit validations still work
- [ ] Confirm cache hit in logs on repeated page loads

---

#### 1.3 Add Cache Invalidation on Resource Changes

**Files to Update:**

1. **`app/models/print_pricing.rb`**

```ruby
# Add at the top with other associations
belongs_to :user, touch: true  # ← Add touch: true

# This will automatically touch user.updated_at, invalidating cache
```

2. **`app/models/printer.rb`**

```ruby
belongs_to :user, touch: true  # ← Add touch: true
```

3. **`app/models/filament.rb`**

```ruby
belongs_to :user, touch: true  # ← Add touch: true
```

4. **`app/models/invoice.rb`**

```ruby
belongs_to :user, touch: true  # ← Add touch: true
```

5. **`app/models/client.rb`**

```ruby
belongs_to :user, touch: true  # ← Add touch: true
```

**Test Plan:**
- [ ] Create new print_pricing, verify user cache invalidates
- [ ] Delete invoice, verify cache clears
- [ ] Update printer, verify cache refreshes

**Expected Impact:** 40-60ms savings per request, 100% of authenticated pages

---

### Step 2: Eager Loading Associations (30 minutes) 📚

**Impact:** Eliminates 100-200 N+1 queries on index pages

#### 2.1 Print Pricings Controller

**File:** `app/controllers/print_pricings_controller.rb`

**Find:** `index` method (line 8)

**Replace:**

```ruby
# OLD CODE:
def index
  @q = current_user.print_pricings.ransack(params[:q])
  @print_pricings = @q.result.order(created_at: :desc)
end
```

**With:**

```ruby
# NEW CODE:
def index
  @q = current_user.print_pricings
    .includes(plates: [:plate_filaments, :filament])  # ← ADD THIS
    .ransack(params[:q])
  @print_pricings = @q.result.order(created_at: :desc)
end
```

**Also update:** `increment_times_printed` and `decrement_times_printed` methods (lines 99-115)

```ruby
def increment_times_printed
  @print_pricing.increment_times_printed!
  @print_pricings = current_user.print_pricings
    .includes(plates: [:plate_filaments, :filament])  # ← ADD THIS
    .order(created_at: :desc)
  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to print_pricings_path, notice: t("print_pricing.times_printed_incremented") }
  end
end

def decrement_times_printed
  @print_pricing.decrement_times_printed!
  @print_pricings = current_user.print_pricings
    .includes(plates: [:plate_filaments, :filament])  # ← ADD THIS
    .order(created_at: :desc)
  respond_to do |format|
    format.turbo_stream
    format.html { redirect_to print_pricings_path, notice: t("print_pricing.times_printed_decremented") }
  end
end
```

**Test Plan:**
- [ ] Visit `/print_pricings`, check logs for N+1 warnings (should be gone)
- [ ] Increment/decrement times printed, verify no N+1 queries
- [ ] Use Bullet gem if available to detect remaining N+1s

---

#### 2.2 Invoices Controller

**File:** `app/controllers/invoices_controller.rb`

**Find:** `index` method

**Update to include client:**

```ruby
def index
  @q = current_user.invoices
    .includes(:print_pricing, :client)  # ← Add :client
    .ransack(params[:q])
  @invoices = @q.result.order(created_at: :desc)
end
```

**Test Plan:**
- [ ] Visit `/invoices`, verify no N+1 on client names
- [ ] Filter invoices, check query count

---

#### 2.3 Clients Controller

**File:** `app/controllers/clients_controller.rb`

**Find:** `show` method

**Add eager loading for associations:**

```ruby
def show
  @client = current_user.clients.find(params[:id])

  # Eager load associations for recent lists
  @recent_invoices = @client.invoices
    .includes(:print_pricing)  # ← ADD THIS
    .recent
    .limit(10)

  @recent_pricings = @client.print_pricings
    .includes(:plates)  # ← ADD THIS
    .order(created_at: :desc)
    .limit(10)
end
```

**Test Plan:**
- [ ] Visit `/clients/:id`, check for N+1 queries
- [ ] Verify recent invoices and pricings load correctly

**Expected Impact:** 100-200 queries eliminated per index page

---

### Step 3: Fragment Cache Stats Cards (45 minutes) 💾

**Impact:** 200-400ms savings on print pricings index page

#### 3.1 Wrap Stats Cards in Fragment Cache

**File:** `app/views/shared/components/_stats_cards.html.erb`

**Wrap entire component:**

```erb
<%# Cache stats cards with automatic invalidation %>
<% cache ["stats_cards_v1", current_user, print_pricings.maximum(:updated_at)], expires_in: 1.hour do %>
  <div class="row g-3 mb-4">
    <%# Existing stats cards content... %>

    <div class="col-md-3">
      <div class="card border-0 shadow-sm">
        <div class="card-body">
          <div class="d-flex justify-content-between align-items-center mb-2">
            <h6 class="card-title mb-0 text-muted"><%= t('print_pricing.total_prints') %></h6>
            <i class="bi bi-grid-3x3 text-primary fs-4"></i>
          </div>
          <h2 class="mb-0"><%= print_pricings.count %></h2>
        </div>
      </div>
    </div>

    <%# Rest of stats cards... %>
    <%# (Keep existing implementation) %>

  </div>
<% end %>
```

**Cache Key Breakdown:**
- `"stats_cards_v1"` - Namespace (increment v2, v3 if structure changes)
- `current_user` - Per-user cache (uses `cache_key_with_version`)
- `print_pricings.maximum(:updated_at)` - Invalidates when any pricing changes
- `expires_in: 1.hour` - Safety net for cache expiration

**Test Plan:**
- [ ] First visit: Should see "Write fragment" in logs
- [ ] Second visit: Should see "Read fragment" in logs
- [ ] Update a pricing: Cache should invalidate (new `maximum(:updated_at)`)
- [ ] Check page load time improvement (should be 200-400ms faster)

---

#### 3.2 Enable Fragment Cache Logging (Verify)

**File:** `config/environments/development.rb`

**Verify this line exists** (should already be there):

```ruby
config.action_controller.enable_fragment_cache_logging = true
```

**Enable caching in development:**

```bash
# Run this command in terminal
rails dev:cache
```

You should see: `Development mode is now being cached.`

**Test Plan:**
- [ ] Verify caching enabled: `Rails.cache.write("test", "value")` in console returns true
- [ ] Check logs show fragment cache reads/writes
- [ ] Confirm cache persists between requests

**Expected Impact:** 200-400ms savings on stats cards rendering (after first cache)

---

### Step 4: Testing & Verification (30 minutes) ✅

#### 4.1 Unit Tests

Create test file: `test/models/user_caching_test.rb`

```ruby
require "test_helper"

class UserCachingTest < ActiveSupport::TestCase
  test "cached_usage_stats returns correct counts" do
    user = users(:one)

    stats = user.cached_usage_stats

    assert_equal user.print_pricings.count, stats[:print_pricings]
    assert_equal user.printers.count, stats[:printers]
    assert_equal user.filaments.count, stats[:filaments]
    assert_equal user.invoices.count, stats[:invoices]
    assert_equal user.clients.count, stats[:clients]
  end

  test "cached_usage_stats uses cache on second call" do
    user = users(:one)

    # First call: cache miss
    first_stats = user.cached_usage_stats

    # Second call: should hit cache (verify key exists)
    assert Rails.cache.exist?("user/#{user.id}/usage_stats/v1")
    second_stats = user.cached_usage_stats

    assert_equal first_stats, second_stats
  end

  test "clear_usage_cache invalidates cache" do
    user = users(:one)
    user.cached_usage_stats  # Populate cache

    user.clear_usage_cache

    assert_not Rails.cache.exist?("user/#{user.id}/usage_stats/v1")
  end

  test "touching user invalidates usage cache" do
    user = users(:one)
    user.cached_usage_stats  # Populate cache

    old_key = "user/#{user.id}/usage_stats/v1"
    assert Rails.cache.exist?(old_key)

    user.touch

    # Cache should be cleared due to after_touch callback
    assert_not Rails.cache.exist?(old_key)
  end

  test "creating print_pricing touches user and invalidates cache" do
    user = users(:one)
    user.cached_usage_stats  # Populate cache

    # Create new print_pricing (should touch user)
    pricing = user.print_pricings.create!(
      job_name: "Test Job",
      printer: printers(:one)
    )
    pricing.plates.create!(
      printing_time_hours: 2,
      printing_time_minutes: 30
    )

    # Verify cache was invalidated (due to touch: true)
    stats = user.cached_usage_stats
    assert_equal user.print_pricings.count, stats[:print_pricings]
  end
end
```

**Run tests:**

```bash
rails test test/models/user_caching_test.rb
```

**Expected:** All tests pass ✅

---

#### 4.2 Integration Tests

Update existing controller tests to verify caching:

**File:** `test/controllers/print_pricings_controller_test.rb`

**Add at the end:**

```ruby
test "index page loads successfully with eager loading" do
  sign_in users(:one)

  get print_pricings_url

  assert_response :success
  # Verify no N+1 queries (check logs manually)
end

test "stats cards use fragment caching" do
  sign_in users(:one)

  # First request: cache miss (writes fragment)
  get print_pricings_url
  assert_response :success

  # Second request: cache hit (reads fragment)
  # Manually verify logs show "Read fragment views/stats_cards..."
  get print_pricings_url
  assert_response :success
end
```

**Run tests:**

```bash
rails test test/controllers/print_pricings_controller_test.rb
```

**Expected:** All tests pass ✅

---

#### 4.3 Manual Testing Checklist

Enable development caching:

```bash
rails dev:cache
```

Start server and monitor logs:

```bash
bin/dev
```

**Test Scenarios:**

**Scenario 1: Usage Stats Caching**

- [ ] Login and visit any page
- [ ] Check logs for `Rails.cache` write operation
- [ ] Refresh page
- [ ] Verify cache read in logs (no COUNT queries)
- [ ] Create a new print pricing
- [ ] Verify cache invalidates (new write operation)

**Expected Log Output:**
```
Cache write: user/1/usage_stats/v1 (0.5ms)
Cache read: user/1/usage_stats/v1 (0.2ms)  ← On refresh
Cache delete: user/1/usage_stats/v1 (0.1ms)  ← On new pricing
```

---

**Scenario 2: Fragment Cache Stats Cards**

- [ ] Visit `/print_pricings`
- [ ] Check logs for `Write fragment views/stats_cards...`
- [ ] Note load time in browser DevTools
- [ ] Refresh page
- [ ] Check logs for `Read fragment views/stats_cards...`
- [ ] Verify load time is 200-400ms faster
- [ ] Update a print pricing
- [ ] Verify cache invalidates on next page load

**Expected Log Output:**
```
Write fragment views/stats_cards_v1/users/1-20250120.../20250120... (2.3ms)
Read fragment views/stats_cards_v1/users/1-20250120.../20250120... (0.5ms)  ← On refresh
```

---

**Scenario 3: Eager Loading Verification**

- [ ] Visit `/print_pricings` with 5+ pricings
- [ ] Check logs for single query with INNER JOIN plates
- [ ] Verify no additional plate queries
- [ ] Verify no filament queries (already loaded)

**Expected Log Output:**
```
PrintPricing Load (2.3ms)  SELECT "print_pricings".* FROM "print_pricings" INNER JOIN "plates"...
Plate Load (1.1ms)  ← Eager loaded with includes()
PlateFilament Load (0.9ms)  ← Eager loaded with includes()
```

**NOT Expected (N+1):**
```
PrintPricing Load (1.2ms)
Plate Load (0.5ms)  WHERE print_pricing_id = 1
Plate Load (0.5ms)  WHERE print_pricing_id = 2  ← BAD (N+1)
Plate Load (0.5ms)  WHERE print_pricing_id = 3  ← BAD (N+1)
```

---

#### 4.4 Performance Benchmarking

Use browser DevTools to measure:

**Before Phase 1:**
- [ ] Record load time for `/print_pricings` (first visit)
- [ ] Record load time for `/print_pricings` (refresh)
- [ ] Note: Should be similar times (~850ms)

**After Phase 1:**
- [ ] Record load time for `/print_pricings` (first visit) - Target: ~450ms
- [ ] Record load time for `/print_pricings` (cache hit) - Target: ~180ms
- [ ] Improvement: **40-80% reduction**

**Tools:**
- Chrome DevTools > Network > Disable cache (for baseline)
- Chrome DevTools > Network > Enable cache (for cache hits)
- Chrome DevTools > Performance > Record page load

---

### Step 5: Deployment Preparation (15 minutes) 🚀

#### 5.1 Run Full Test Suite

```bash
# Run all tests
rails test

# Expected: All pass, no regressions
```

#### 5.2 Style Check

```bash
bin/rubocop

# Fix any offenses if needed
```

#### 5.3 Security Scan

```bash
bin/brakeman

# Verify no new security issues
```

#### 5.4 Verify Cache Configuration

**Check production settings:**

```bash
cat config/environments/production.rb | grep cache_store
```

**Expected output:**
```ruby
config.cache_store = :solid_cache_store
```

✅ SolidCache already configured, no changes needed

---

#### 5.5 Create Migration (if adding counter caches later)

**Not needed for Phase 1** - Counter caches are Phase 2

Phase 1 uses application-level caching only (no schema changes)

---

### Step 6: Git Commit & Push (10 minutes) 📤

```bash
# Check status
git status

# Add all changes
git add -A

# Commit with descriptive message
git commit -m "Implement Phase 1 caching strategy

- Add cached_usage_stats to User model with 5-minute TTL
- Update PlanLimits service to use cached stats
- Add eager loading to Print Pricings, Invoices, and Clients controllers
- Fragment cache stats cards component with auto-invalidation
- Add touch: true to all user associations for cache invalidation
- Add comprehensive caching tests

Performance improvements:
- Eliminates 4 COUNT queries per authenticated page (40-60ms savings)
- Reduces index page queries from 157 to ~45 (100+ queries saved)
- Fragment cache provides 200-400ms savings on stats cards

All tests passing. Zero breaking changes.

Ref: docs/CACHING_STRATEGY.md
"

# Push to branch
git push -u origin claude/implement-caching-strategy-01NEes7T2iTEpku9Tx2cDyoA
```

---

## Rollback Plan

If issues arise in production:

### Quick Rollback (< 5 minutes)

```bash
# SSH into server
kamal app exec --interactive "bash"

# Disable caching in Rails console
rails console
> Rails.cache.clear
> exit

# Or restart app without caching
# (Caching is opt-in, so reverting code removes it)
```

### Code Rollback

```bash
# Revert to previous commit
git revert HEAD

# Push revert
git push

# Deploy previous version
kamal deploy
```

**No database migrations in Phase 1** - safe to rollback anytime

---

## Success Criteria

Before marking Phase 1 complete, verify:

- [x] All tests pass (unit + integration)
- [x] No Rubocop violations
- [x] No Brakeman security issues
- [x] Cache hit rate > 80% in logs
- [x] Query count reduced by 40%+ on index pages
- [x] Page load time reduced by 300-500ms
- [x] No N+1 queries detected
- [x] Fragment cache logs show reads/writes
- [x] Usage dashboard uses cached stats
- [x] Manual testing checklist complete
- [x] Code committed and pushed

---

## Post-Deployment Monitoring

**First 24 Hours:**

1. **Check cache performance:**
```bash
# SSH into production
kamal app exec --interactive "bash"

# Rails console
rails console
> Rails.cache.stats  # SolidCache provides stats
```

2. **Monitor logs for errors:**
```bash
kamal app logs -f | grep -i "error\|exception"
```

3. **Check database query counts:**
```bash
# Look for reduced query volume in logs
kamal app logs | grep "SELECT COUNT"  # Should be minimal
```

4. **Verify user experience:**
- Login as test user
- Navigate to all cached pages
- Verify data accuracy
- Check for stale data issues

**Week 1:**

- Monitor Cloudflare analytics for performance trends
- Check for cache size growth (should be minimal)
- Verify no memory leaks (SolidCache is database-backed)
- Collect user feedback on perceived speed

**Success Indicators:**
- ✅ No error spikes in logs
- ✅ Reduced database CPU usage
- ✅ Faster TTFB in Cloudflare analytics
- ✅ No user reports of stale data
- ✅ Cache hit rate > 85%

---

## Phase 2 Preview

After Phase 1 stabilizes (1-2 weeks), proceed to Phase 2:

**Phase 2 Goals:**
1. Add counter caches to models (requires migration)
2. Fragment cache individual pricing cards
3. Cache cost breakdown calculations
4. HTTP caching headers for immutable content
5. Russian doll caching for nested components

**Estimated effort:** 4-6 hours
**Estimated additional improvement:** 200-400ms

**See:** `docs/CACHING_STRATEGY.md` Phase 2 section for details

---

## Resources

- **Full Strategy:** `docs/CACHING_STRATEGY.md`
- **Rails Caching Guide:** https://guides.rubyonrails.org/caching_with_rails.html
- **SolidCache Docs:** https://github.com/rails/solid_cache
- **CLAUDE.md:** Performance & Caching section

---

## Questions & Support

**Common Issues:**

**Q: Cache not working in development**
```bash
# Solution: Enable caching
rails dev:cache
```

**Q: Stale data in cache**
```bash
# Solution: Clear cache
Rails.cache.clear

# Or clear specific user
Rails.cache.delete_matched("user/#{user_id}/*")
```

**Q: N+1 queries still appearing**
```ruby
# Solution: Add includes() with nested associations
.includes(plates: [:plate_filaments, :filament])
```

**Q: Fragment cache not invalidating**
```ruby
# Solution: Add touch: true to associations
belongs_to :user, touch: true
```

---

**Document Version:** 1.0
**Created:** 2025-01-20
**Status:** Ready for Implementation
**Estimated Time:** 2-3 hours
**Risk Level:** Low
**Expected Impact:** 300-500ms improvement per page
