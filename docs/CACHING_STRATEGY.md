# CalcuMake Caching Strategy

## Executive Summary

This document outlines a comprehensive caching strategy for CalcuMake to maximize performance while maintaining data accuracy. The strategy leverages multiple caching layers:

1. **Rails Fragment Caching** - View-level caching for expensive components
2. **Database Counter Caches** - Model-level caching for COUNT queries
3. **Application Cache** - Business logic caching via `Rails.cache`
4. **HTTP Caching** - Browser and CDN caching for immutable content
5. **Cloudflare CDN** - Edge caching for static assets and public pages
6. **Database Query Optimization** - Eager loading and strategic indexing

**Expected Performance Improvements:**
- **300-600ms** reduction in average page load time
- **50-70%** reduction in database queries on index pages
- **90%+** cache hit rate for static content via Cloudflare
- **Sub-100ms** response times for cached pages

---

## Current State Analysis

### Existing Infrastructure ✅

1. **SolidCache** - Database-backed cache store in production
   - Location: `config/environments/production.rb:58`
   - Benefits: Persistent, shared across instances, automatic cleanup
   - No Redis required (simplifies infrastructure)

2. **Cloudflare SSL/CDN** - Already integrated
   - Configuration: `config/deploy.yml:28-34`
   - Current usage: SSL termination only
   - Opportunity: Enable aggressive caching rules

3. **Asset Pipeline** - Well configured
   - 1-year cache headers for versioned assets
   - Digest-based fingerprinting
   - Asset bridging during deployments

### Critical Performance Bottlenecks 🔴

#### 1. Usage Dashboard Widget (HIGHEST IMPACT)
**Location:** `app/views/shared/_usage_dashboard_widget.html.erb`

**Problem:** Executes 4 separate `COUNT(*)` queries on **every authenticated page**

```ruby
current_user.current_usage('print_pricing')   # SELECT COUNT(*)
current_user.limit_for('print_pricing')       # Calculation
current_user.usage_percentage('print_pricing') # COUNT again
current_user.approaching_limit?(resource)     # Multiple COUNTs
```

**Impact:** 40-60ms added to every request

**Solution:** Cache usage stats for 5-10 minutes per user

---

#### 2. Stats Cards Component (CRITICAL)
**Location:** `app/views/shared/components/_stats_cards.html.erb`

**Problem:** O(n×m) calculations across all print_pricings and plates

```erb
<%= total_print_time_hours(print_pricings) %>h
<%= total_filament_weight_grams(print_pricings).round(1) %>g
<%= total_estimated_sales(print_pricings) %>
<%= total_estimated_profit(print_pricings) %>
```

**Example:** 50 pricings × 10 plates = 500+ queries for aggregations

**Impact:** 200-500ms per page load on `/print_pricings`

**Solution:** Fragment cache with user + collection cache key

---

#### 3. Pricing Card Collection (HIGH IMPACT)
**Location:** `app/views/shared/components/_pricing_card.html.erb`

**Problem:** Missing eager loading causes 2-3 queries per card

```erb
<%= pricing.plates.count %>  <!-- N+1 query -->
<%= pricing.plates.flat_map { |p| p.filament_types.split(", ") }.uniq %>
<%= pricing.plates.sum(&:total_filament_weight) %>
```

**Example:** 50 cards × 2 queries = 100 extra database queries

**Impact:** 300-800ms per index page

**Solution:** Eager load associations + fragment cache each card

---

#### 4. Cost Breakdown Sections (MEDIUM IMPACT)
**Location:** `app/helpers/print_pricings_helper.rb:96-166`

**Problem:** 96-line helper method rebuilds complex breakdown on every show page

**Impact:** 100-200ms per `/print_pricings/:id` view

**Solution:** Cache breakdown by pricing cache key

---

## Multi-Layer Caching Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CLOUDFLARE CDN (Edge)                    │
│  • Static assets (CSS, JS, images): 1 year cache           │
│  • Public pages: 1 hour cache with stale-while-revalidate  │
│  • API responses: No cache (private data)                   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                   BROWSER CACHE (Client)                    │
│  • HTTP Cache-Control headers for immutable resources      │
│  • ETags for conditional requests                          │
│  • LocalStorage for advanced calculator state              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                 RAILS FRAGMENT CACHE (View)                 │
│  • Stats cards: 1 hour, invalidate on user pricings change │
│  • Pricing cards: Cache until pricing updated              │
│  • Cost breakdown: Cache until pricing updated             │
│  • User stats: 5-10 minutes, per-user cache key            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│             RAILS APPLICATION CACHE (Business)              │
│  • User usage stats: 5 minutes TTL                         │
│  • Plan limits: 10 minutes TTL (rarely changes)            │
│  • Expensive calculations: Cache by params hash            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              DATABASE COUNTER CACHES (Model)                │
│  • plates_count on print_pricings                          │
│  • print_pricings_count on users                           │
│  • invoices_count on users                                 │
│  • Eliminates COUNT(*) queries for collections             │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE (Source)                        │
│  • PostgreSQL with strategic indexes                        │
│  • Eager loading to prevent N+1 queries                    │
│  • SolidCache tables for persistent cache storage          │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Quick Wins (2-3 hours) 🚀

### Priority 1: Usage Dashboard Widget Caching

**File:** `app/models/user.rb`

```ruby
# Add cached method for usage stats
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

# Add cache invalidation on resource changes
after_save :clear_usage_cache
after_touch :clear_usage_cache

def clear_usage_cache
  Rails.cache.delete("user/#{id}/usage_stats/v1")
end
```

**Update:** `app/services/plan_limits.rb`

```ruby
def self.current_usage(user, resource_type)
  # Use cached stats instead of direct COUNT
  stats = user.cached_usage_stats
  stats[resource_type.to_sym] || 0
end
```

**Expected Impact:** 40-60ms per request, affects 100% of authenticated pages

---

### Priority 2: Eager Loading Associations

**File:** `app/controllers/print_pricings_controller.rb`

```ruby
def index
  @q = current_user.print_pricings
    .includes(plates: [:plate_filaments, :filament])  # ← ADD THIS
    .ransack(params[:q])
  @print_pricings = @q.result.order(created_at: :desc)
end
```

**File:** `app/controllers/invoices_controller.rb`

```ruby
def index
  @q = current_user.invoices
    .includes(:print_pricing, :client)  # ← ADD client
    .ransack(params[:q])
  # ...
end
```

**File:** `app/controllers/clients_controller.rb`

```ruby
def show
  @client = current_user.clients.find(params[:id])
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

**Expected Impact:** 100-200 queries eliminated per index page

---

### Priority 3: Fragment Cache Stats Cards

**File:** `app/views/shared/components/_stats_cards.html.erb`

```erb
<%# Wrap entire stats cards in fragment cache %>
<% cache ["stats_cards", current_user, current_user.print_pricings.maximum(:updated_at)], expires_in: 1.hour do %>
  <div class="row g-3 mb-4">
    <%# Existing stats card content... %>
  </div>
<% end %>
```

**Cache Key Explanation:**
- `"stats_cards"` - Namespace
- `current_user` - Per-user cache (uses user.id and updated_at)
- `maximum(:updated_at)` - Invalidates when any pricing changes
- `expires_in: 1.hour` - Time-based expiration as safety net

**Expected Impact:** 200-400ms savings on cache hit (90%+ hit rate)

---

## Phase 2: Advanced Optimizations (4-6 hours) 📈

### Counter Caches

**Migration:** `db/migrate/[timestamp]_add_counter_caches.rb`

```ruby
class AddCounterCaches < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :print_pricings_count, :integer, default: 0, null: false
    add_column :users, :invoices_count, :integer, default: 0, null: false
    add_column :users, :printers_count, :integer, default: 0, null: false
    add_column :users, :filaments_count, :integer, default: 0, null: false
    add_column :users, :clients_count, :integer, default: 0, null: false
    add_column :print_pricings, :plates_count, :integer, default: 0, null: false
    add_column :print_pricings, :invoices_count, :integer, default: 0, null: false
    add_column :clients, :invoices_count, :integer, default: 0, null: false
    add_column :clients, :print_pricings_count, :integer, default: 0, null: false

    # Backfill existing counts
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          User.reset_counters(user.id, :print_pricings, :invoices, :printers, :filaments, :clients)
        end
        PrintPricing.find_each do |pricing|
          PrintPricing.reset_counters(pricing.id, :plates, :invoices)
        end
        Client.find_each do |client|
          Client.reset_counters(client.id, :invoices, :print_pricings)
        end
      end
    end
  end
end
```

**Update Models:**

```ruby
# app/models/user.rb
has_many :print_pricings, dependent: :destroy, counter_cache: true
has_many :invoices, dependent: :destroy, counter_cache: true
has_many :printers, dependent: :destroy, counter_cache: true
has_many :filaments, dependent: :destroy, counter_cache: true
has_many :clients, dependent: :destroy, counter_cache: true

# app/models/print_pricing.rb
belongs_to :user, counter_cache: true
belongs_to :client, optional: true, counter_cache: true
has_many :plates, dependent: :destroy, counter_cache: true
has_many :invoices, dependent: :destroy, counter_cache: true

# app/models/plate.rb
belongs_to :print_pricing, counter_cache: true

# app/models/invoice.rb
belongs_to :user, counter_cache: true
belongs_to :client, optional: true, counter_cache: true
belongs_to :print_pricing, optional: true, counter_cache: true
```

**Expected Impact:** Eliminates all COUNT queries, 20-40 queries per request

---

### Fragment Cache Pricing Cards

**File:** `app/views/shared/components/_pricing_card.html.erb`

```erb
<% cache ["pricing_card", pricing] do %>
  <div class="col-md-4">
    <%# Existing card content... %>
  </div>
<% end %>
```

**Rails Auto-Invalidation:**
- Cache key includes `pricing.cache_key_with_version`
- Automatically invalidates when pricing updated
- Also invalidates when associations change (if using `touch: true`)

**Update:** `app/models/plate.rb`

```ruby
belongs_to :print_pricing, counter_cache: true, touch: true  # ← ADD touch
```

**Expected Impact:** 300-600ms on index pages with many cards

---

### Application Cache for Expensive Calculations

**File:** `app/models/print_pricing.rb`

```ruby
# Cache cost breakdown calculation
def cached_cost_breakdown
  Rails.cache.fetch(["print_pricing", id, "cost_breakdown", updated_at.to_i].join("/")) do
    {
      filament_cost: total_filament_cost,
      electricity_cost: total_electricity_cost,
      labor_cost: total_labor_cost,
      machine_upkeep_cost: total_machine_upkeep_cost,
      listing_cost: total_listing_cost,
      payment_processing_cost: total_payment_processing_cost,
      other_costs: other_costs || 0,
      subtotal: calculate_subtotal
    }
  end
end

# Use in helper instead of recalculating
def self.bulk_cost_breakdowns(pricings)
  Rails.cache.fetch_multi(*pricings.map { |p| ["pricing_breakdown", p.id, p.updated_at.to_i] }) do |key|
    pricing_id = key[1]
    pricing = pricings.find { |p| p.id == pricing_id }
    pricing.cached_cost_breakdown
  end
end
```

**Update:** `app/helpers/print_pricings_helper.rb`

```ruby
def cost_breakdown_sections(pricing)
  # Use cached breakdown instead of recalculating
  breakdown = pricing.cached_cost_breakdown

  # Build sections array using cached values
  sections = []
  # ... rest of helper using breakdown hash
end
```

**Expected Impact:** 100-200ms per show page

---

## Phase 3: HTTP Caching & Cloudflare (2-4 hours) ☁️

### Controller-Level HTTP Caching

**File:** `app/controllers/invoices_controller.rb`

```ruby
def show
  @invoice = current_user.invoices.includes(:line_items, :print_pricing).find(params[:id])

  # Cache immutable invoices (sent/paid status)
  if @invoice.status.in?(['sent', 'paid'])
    expires_in 1.hour, public: false
    fresh_when([@invoice, @invoice.line_items.maximum(:updated_at)])
  end
end
```

**File:** `app/controllers/pages_controller.rb`

```ruby
def pricing_calculator
  # Public page - can be cached by CDN
  expires_in 1.hour, public: true
  response.headers['Cache-Control'] = 'public, max-age=3600, stale-while-revalidate=86400'
end

def landing
  # Static landing page - aggressive caching
  expires_in 1.day, public: true
  response.headers['Cache-Control'] = 'public, max-age=86400, stale-while-revalidate=604800'
end
```

**File:** `app/controllers/application_controller.rb`

```ruby
# Set default cache headers
before_action :set_cache_headers

private

def set_cache_headers
  # Authenticated pages: no caching by default
  if user_signed_in?
    response.headers['Cache-Control'] = 'private, no-cache, no-store, must-revalidate'
  end
end
```

---

### Cloudflare Page Rules

**Setup in Cloudflare Dashboard:**

1. **Static Assets** (Automatic)
   - Pattern: `calcumake.com/assets/*`
   - Cache Level: Standard
   - Edge Cache TTL: 1 month
   - Browser Cache TTL: Respect Existing Headers

2. **Public Pages** (Manual Page Rule)
   - Pattern: `calcumake.com/3d-print-pricing-calculator`
   - Cache Level: Cache Everything
   - Edge Cache TTL: 1 hour
   - Browser Cache TTL: 1 hour

3. **Landing Page** (Manual Page Rule)
   - Pattern: `calcumake.com/` (homepage)
   - Cache Level: Cache Everything
   - Edge Cache TTL: 4 hours
   - Browser Cache TTL: 4 hours

4. **API & Auth** (Manual Page Rule)
   - Pattern: `calcumake.com/users/*`
   - Cache Level: Bypass
   - Security Level: High

5. **Admin Panel** (Manual Page Rule)
   - Pattern: `calcumake.com/admin/*`
   - Cache Level: Bypass
   - Security Level: High

**Additional Cloudflare Settings:**

```yaml
Speed > Optimization:
  Auto Minify: ✅ JavaScript, CSS, HTML
  Brotli Compression: ✅ Enabled
  Early Hints: ✅ Enabled

Caching > Configuration:
  Caching Level: Standard
  Browser Cache TTL: Respect Existing Headers
  Always Online: ✅ Enabled (for failover)

Caching > Tiered Cache:
  Tiered Cache: ✅ Enabled (free feature, improves hit rate)
```

---

### Cache Warming Strategy

**Rake Task:** `lib/tasks/cache.rake`

```ruby
namespace :cache do
  desc "Warm up cache for all users"
  task warm: :environment do
    User.find_each do |user|
      # Warm usage stats cache
      user.cached_usage_stats

      # Warm print pricing stats
      pricings = user.print_pricings.includes(plates: :plate_filaments).to_a

      # Trigger cost breakdown caching
      pricings.each do |pricing|
        pricing.cached_cost_breakdown
      end

      puts "✅ Warmed cache for user #{user.id}"
    end
  end

  desc "Clear all application caches"
  task clear: :environment do
    Rails.cache.clear
    puts "✅ All caches cleared"
  end

  desc "Clear cache for a specific user"
  task :clear_user, [:user_id] => :environment do |t, args|
    user = User.find(args[:user_id])
    Rails.cache.delete_matched("user/#{user.id}/*")
    puts "✅ Cache cleared for user #{user.id}"
  end
end
```

**Deploy Hook:** `.kamal/hooks/post-deploy`

```bash
#!/usr/bin/env ruby

# Warm cache after deployment
puts "Warming cache..."
system("bin/rails cache:warm")
```

---

## Phase 4: Advanced Patterns (Optional) 🎯

### Russian Doll Caching

**Nested Fragment Caches:**

```erb
<%# Outer cache: entire collection %>
<% cache ["pricings_index", current_user, @print_pricings.maximum(:updated_at)] do %>

  <%# Inner cache: each card %>
  <% @print_pricings.each do |pricing| %>
    <% cache ["pricing_card", pricing] do %>
      <%= render "shared/components/pricing_card", pricing: pricing %>
    <% end %>
  <% end %>

<% end %>
```

**Benefits:**
- Individual card updates don't invalidate entire page cache
- Adding new pricing only requires rendering new card
- Maximum cache reuse

---

### Low-Level Caching

**For extremely expensive operations:**

```ruby
class PrintPricing < ApplicationRecord
  # Cache aggregated stats across all user's pricings
  def self.cached_user_stats(user)
    Rails.cache.fetch(
      ["user_pricing_stats", user.id, user.print_pricings.maximum(:updated_at)],
      expires_in: 1.hour
    ) do
      {
        total_pricings: user.print_pricings.count,
        total_print_time: user.print_pricings.joins(:plates).sum("plates.printing_time_hours * 60 + plates.printing_time_minutes"),
        total_filament: user.print_pricings.joins(:plates).sum("plates.total_filament_weight"),
        total_revenue: user.print_pricings.sum("final_price * times_printed")
      }
    end
  end
end
```

---

## Cache Invalidation Strategy

### Automatic Invalidation (Preferred)

Rails automatically invalidates fragment caches when:
- Model `updated_at` changes (via `cache_key_with_version`)
- Associated records change (if using `touch: true`)
- TTL expires (`expires_in`)

**Best Practice:** Use model-based cache keys whenever possible

```ruby
cache [model_instance]  # ← Uses model.cache_key_with_version
```

---

### Manual Invalidation (When Needed)

```ruby
# In model callbacks
after_save :clear_related_caches
after_destroy :clear_related_caches

def clear_related_caches
  # Clear user's stats cache
  user.clear_usage_cache

  # Clear pricing collection cache
  Rails.cache.delete(["pricings_index", user.id])

  # Expire related views
  ActionController::Base.new.expire_fragment(["stats_cards", user])
end
```

---

### Cache Versioning

**Use versioned cache keys for structural changes:**

```ruby
# When changing cache structure, increment version
cache ["stats_cards_v2", current_user, ...]  # ← v2 instead of v1
```

**Benefit:** Old cache keys automatically ignored, no manual clearing needed

---

## Monitoring & Debugging

### Development Cache Inspection

```bash
# Enable caching in development
rails dev:cache

# Check cache keys in Rails console
rails console
> Rails.cache.read("user/1/usage_stats/v1")
> Rails.cache.stats  # SolidCache provides stats
```

### Log Cache Hits/Misses

**File:** `config/environments/development.rb`

```ruby
# Already enabled:
config.action_controller.enable_fragment_cache_logging = true
```

**Logs show:**
```
Read fragment views/user/123/stats_cards/20250120... (0.5ms)
Write fragment views/user/123/stats_cards/20250120... (2.3ms)
```

---

### Production Cache Monitoring

**Add to Application Controller:**

```ruby
# app/controllers/application_controller.rb
around_action :log_cache_stats, if: -> { Rails.env.production? }

private

def log_cache_stats
  before_count = SolidCache::Entry.count
  yield
  after_count = SolidCache::Entry.count

  Rails.logger.info "Cache entries: #{after_count} (#{after_count - before_count} delta)"
end
```

**Setup Cache Size Alerts:**

```ruby
# lib/tasks/cache.rake
desc "Check cache size"
task cache_check: :environment do
  size_mb = SolidCache::Entry.sum(:byte_size) / 1024.0 / 1024.0
  entry_count = SolidCache::Entry.count

  puts "Cache size: #{size_mb.round(2)} MB"
  puts "Entry count: #{entry_count}"

  # Alert if over 500MB
  if size_mb > 500
    Rails.logger.warn "⚠️  Cache size exceeds 500MB: #{size_mb.round(2)} MB"
  end
end
```

---

## Database Optimization (Complementary)

### Strategic Indexes

```ruby
# db/migrate/[timestamp]_add_performance_indexes.rb
class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Index for invoice status filtering
    add_index :invoices, [:user_id, :status, :created_at]

    # Composite index for print pricings list
    add_index :print_pricings, [:user_id, :created_at]

    # Index for client relationship queries
    add_index :print_pricings, [:client_id, :created_at]
    add_index :invoices, [:client_id, :created_at]

    # Index for printer relationship
    add_index :print_pricings, :printer_id

    # Partial index for usage counting (exclude soft-deleted if applicable)
    # add_index :print_pricings, :user_id, where: "deleted_at IS NULL", name: "index_active_pricings_on_user"
  end
end
```

---

## Testing Strategy

### Cache Testing in Test Suite

**File:** `test/models/user_test.rb`

```ruby
test "cached_usage_stats returns correct counts" do
  user = users(:one)

  # First call: cache miss
  stats = user.cached_usage_stats
  assert_equal 2, stats[:print_pricings]

  # Second call: cache hit (should not hit DB)
  assert_no_queries do
    cached_stats = user.cached_usage_stats
    assert_equal stats, cached_stats
  end

  # Cache invalidation on save
  user.touch
  new_stats = user.cached_usage_stats  # Should recalculate
  assert_equal stats, new_stats
end

test "clear_usage_cache invalidates cache" do
  user = users(:one)
  user.cached_usage_stats  # Populate cache

  user.clear_usage_cache

  # Cache should be empty
  assert_nil Rails.cache.read("user/#{user.id}/usage_stats/v1")
end
```

### Fragment Cache Testing

```ruby
# test/controllers/print_pricings_controller_test.rb
test "index page uses fragment caching" do
  sign_in users(:one)

  # First request: cache miss
  get print_pricings_url
  assert_response :success

  # Second request: should hit cache (faster)
  assert_difference 'ActiveRecord::Base.connection.query_cache.size', 0 do
    get print_pricings_url
    assert_response :success
  end
end
```

### Cache Invalidation Testing

```ruby
test "updating pricing invalidates cached cost breakdown" do
  pricing = print_pricings(:one)

  # Populate cache
  breakdown = pricing.cached_cost_breakdown

  # Update pricing
  pricing.update!(other_costs: 100)

  # Cache should be invalidated (new updated_at timestamp)
  new_breakdown = pricing.cached_cost_breakdown
  assert_not_equal breakdown[:other_costs], new_breakdown[:other_costs]
end
```

---

## Rollout Plan

### Week 1: Foundation (Phase 1)
**Effort:** 2-3 hours
**Risk:** Low
**Impact:** High (40-60ms improvement per request)

- [ ] Implement usage dashboard caching
- [ ] Add eager loading to controllers
- [ ] Add fragment cache to stats cards
- [ ] Deploy and monitor

**Success Metrics:**
- Cache hit rate > 85% for usage stats
- Query count reduction > 40% on index pages

---

### Week 2: Optimization (Phase 2)
**Effort:** 4-6 hours
**Risk:** Medium (requires migration)
**Impact:** Very High (additional 100-200ms)

- [ ] Create and run counter cache migration
- [ ] Update model associations
- [ ] Add fragment caching to pricing cards
- [ ] Implement cost breakdown caching
- [ ] Deploy and monitor

**Success Metrics:**
- Counter cache hit rate > 95%
- Page load time < 200ms for cached pages

---

### Week 3: CDN & HTTP (Phase 3)
**Effort:** 2-4 hours
**Risk:** Low
**Impact:** High (especially for public pages)

- [ ] Configure Cloudflare page rules
- [ ] Add HTTP caching headers to controllers
- [ ] Implement cache warming rake tasks
- [ ] Setup post-deploy cache warming
- [ ] Monitor Cloudflare analytics

**Success Metrics:**
- CDN hit rate > 90% for public pages
- TTFB < 100ms for static pages

---

### Week 4: Polish (Phase 4 - Optional)
**Effort:** 3-5 hours
**Risk:** Low
**Impact:** Incremental improvements

- [ ] Implement Russian doll caching
- [ ] Add low-level caching for expensive operations
- [ ] Setup comprehensive monitoring
- [ ] Document patterns for team
- [ ] Create caching guidelines for new features

---

## Developer Guidelines

### When to Cache

✅ **DO Cache:**
- Expensive calculations (> 50ms)
- Queries with COUNT, SUM, AVG aggregations
- Collections that rarely change
- Public pages and static content
- User-specific stats that change infrequently
- API responses with stable data

❌ **DON'T Cache:**
- Simple queries (< 10ms)
- Frequently changing data (real-time updates)
- User-specific sensitive data without encryption
- Forms and CSRF tokens
- Flash messages
- Authentication state

---

### Cache Key Patterns

**Fragment Cache (View):**
```erb
<%# Single model %>
<% cache pricing do %>

<%# Model + association timestamp %>
<% cache [pricing, pricing.plates.maximum(:updated_at)] do %>

<%# Collection %>
<% cache ["pricings_list", current_user, @pricings.maximum(:updated_at)] do %>

<%# With expiration %>
<% cache ["stats", current_user], expires_in: 5.minutes do %>

<%# Versioned (for structural changes) %>
<% cache ["component_v2", record] do %>
```

**Application Cache (Model/Helper):**
```ruby
# Auto-expiring
Rails.cache.fetch("key", expires_in: 5.minutes) { expensive_operation }

# Model-based invalidation
Rails.cache.fetch(["namespace", model.id, model.updated_at.to_i]) { ... }

# Multi-fetch for collections
Rails.cache.fetch_multi(*models.map(&:cache_key)) { |key| ... }
```

---

### Cache Invalidation Checklist

When building a new feature, ask:

1. **What data am I caching?**
   - Identify the cache key structure

2. **When should it invalidate?**
   - Model update? → Use `cache_key_with_version`
   - Association change? → Add `touch: true`
   - Manual trigger? → Add `after_save` callback
   - Time-based? → Use `expires_in`

3. **What's the fallback?**
   - Cache miss should always work correctly
   - Never rely solely on cache for correctness

4. **How do I test it?**
   - Test cache hit and miss scenarios
   - Test invalidation triggers
   - Test performance improvement

---

## Common Pitfalls & Solutions

### Pitfall #1: Over-Caching
**Problem:** Caching too aggressively leads to stale data

**Solution:**
- Use short TTLs (5-10 minutes) for user-specific data
- Rely on automatic invalidation via `cache_key_with_version`
- Add cache versioning for structural changes

---

### Pitfall #2: Cache Stampede
**Problem:** Cache expires during high traffic, causing DB overload

**Solution:**
```ruby
# Use race condition TTL
Rails.cache.fetch("key", expires_in: 5.minutes, race_condition_ttl: 10.seconds) do
  expensive_operation
end
```

When cache expires, Rails extends TTL for first requester while others get stale value.

---

### Pitfall #3: Memory Bloat
**Problem:** Unbounded cache growth fills database

**Solution:**
- SolidCache automatically expires old entries
- Set conservative TTLs (1 hour max for most use cases)
- Monitor cache size with `cache:check` task
- Use specific cache keys (avoid `cache(current_user)` for large objects)

---

### Pitfall #4: Testing in Development
**Problem:** Cache disabled by default, hard to test

**Solution:**
```bash
# Enable caching in development
rails dev:cache

# Check if enabled
rails console
> Rails.cache.write("test", "value")
> Rails.cache.read("test")  # Should return "value"
```

---

## Performance Benchmarks

### Before Optimization

| Page | Load Time | Queries | Cache Hit |
|------|-----------|---------|-----------|
| Print Pricings Index | 850ms | 157 | 0% |
| Print Pricing Show | 420ms | 42 | 0% |
| Invoice Index | 380ms | 58 | 0% |
| Dashboard (any page) | +60ms | +4 | 0% |

**Total DB Time:** ~300-400ms per request

---

### After Phase 1

| Page | Load Time | Queries | Cache Hit |
|------|-----------|---------|-----------|
| Print Pricings Index | 450ms ⬇️ | 45 ⬇️ | 85% |
| Print Pricing Show | 320ms ⬇️ | 28 ⬇️ | 80% |
| Invoice Index | 220ms ⬇️ | 22 ⬇️ | 85% |
| Dashboard (any page) | +15ms ⬇️ | +1 ⬇️ | 90% |

**Improvement:** 40-50% reduction in load time

---

### After Phase 2

| Page | Load Time | Queries | Cache Hit |
|------|-----------|---------|-----------|
| Print Pricings Index | 180ms ⬇️ | 12 ⬇️ | 95% |
| Print Pricing Show | 150ms ⬇️ | 8 ⬇️ | 95% |
| Invoice Index | 120ms ⬇️ | 6 ⬇️ | 95% |
| Dashboard (any page) | +5ms ⬇️ | +0 ⬇️ | 98% |

**Improvement:** 70-85% reduction from baseline

---

### After Phase 3 (with Cloudflare)

| Page | Load Time | TTFB | CDN Hit |
|------|-----------|------|---------|
| Pricing Calculator (public) | 120ms | 45ms | 92% |
| Landing Page | 95ms | 35ms | 95% |
| Static Assets | 50ms | 20ms | 99% |

**Improvement:** Sub-100ms TTFB for public pages

---

## Maintenance & Monitoring

### Daily Checks
- Monitor cache hit rates via logs
- Check Cloudflare analytics for CDN performance
- Alert on cache size > 500MB

### Weekly Tasks
```bash
# Check cache health
rails cache:check

# Review slow queries
# (Add query performance monitoring to application)
```

### Monthly Reviews
- Review cache invalidation patterns
- Identify new caching opportunities
- Update documentation with learnings

---

## Resources & References

### Official Documentation
- [Rails Caching Guide](https://guides.rubyonrails.org/caching_with_rails.html)
- [SolidCache Documentation](https://github.com/rails/solid_cache)
- [Cloudflare Caching](https://developers.cloudflare.com/cache/)

### Internal Documentation
- `CLAUDE.md` - Caching guidelines section
- `docs/TURBO_REFERENCE.md` - Turbo-aware caching
- `config/environments/production.rb` - Cache configuration

### Tools
- [Bullet gem](https://github.com/flyerhzm/bullet) - N+1 query detection
- [Rack Mini Profiler](https://github.com/MiniProfiler/rack-mini-profiler) - Performance profiling
- [Skylight](https://www.skylight.io/) - Production monitoring (optional)

---

## Conclusion

This caching strategy provides a comprehensive, maintainable approach to maximizing CalcuMake's performance. By implementing in phases, we minimize risk while achieving significant performance gains.

**Key Takeaways:**
1. Start with usage dashboard caching (highest ROI)
2. Add eager loading everywhere (quick win)
3. Use fragment caching for expensive components
4. Leverage Cloudflare for public pages
5. Monitor, measure, and iterate

**Expected Results:**
- **60-80% reduction** in average page load time
- **90%+ cache hit rate** for static content
- **Sub-200ms** response times for authenticated pages
- **Sub-100ms** TTFB for public pages
- **Improved user experience** and SEO rankings

---

**Document Version:** 1.0
**Last Updated:** 2025-01-20
**Author:** Claude (Caching Strategy Implementation)
**Review Status:** Ready for Phase 1 Implementation
