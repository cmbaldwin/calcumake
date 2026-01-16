# PR Merge Strategy - Systematic Testing & Production Deployment

**Created:** 2025-11-20
**Status:** Active Plan
**Priority:** High - Foundation for future development standards

## Current PR Landscape

### Open PRs (10 Total)

**Strategic/Foundation PRs:**
- **#45** - Caching Strategy Implementation (PRIORITY 1)
- **#46** - ViewComponent Research & Migration Plan (PRIORITY 2)

**Feature PRs:**
- **#47** - Filament Import Tool
- **#44** - SEO Strategy & AI Integration Planning
- **#43** - API Currency Conversion
- **#42** - lib3mf Research & 3MF Import

**Dependency Updates (Dependabot):**
- **#41** - aws-sdk-s3: 1.201.0 → 1.204.0
- **#40** - stripe: 17.2.0 → 18.0.0
- **#38** - bootsnap: 1.18.6 → 1.19.0

**Legacy:**
- **#35** - Todo List Completion (needs review)

---

## Strategic Approach: Foundation First

### Why Caching & ViewComponents First?

1. **Establish Standards** - Creates patterns for all future code
2. **Performance Foundation** - Improves baseline before adding features
3. **Code Quality** - Reduces technical debt before it grows
4. **Developer Efficiency** - Better patterns = faster future development
5. **Test Coverage** - ViewComponents bring 80% view test coverage (from 0%)

---

## Phase 1: Foundation Layer (Week 1) 🏗️

### Stage 1A: Caching Implementation (#45)
**Timeline:** Days 1-2
**Risk Level:** LOW
**Effort:** 2-3 hours implementation + 1 hour testing

#### Pre-Merge Checklist
- [ ] Review `docs/CACHING_STRATEGY.md` for completeness
- [ ] Review `docs/CACHING_PHASE_1_PLAN.md` implementation steps
- [ ] Verify CLAUDE.md updates are accurate
- [ ] Check all code changes compile without errors

#### Testing Strategy
```bash
# 1. Checkout branch
git checkout claude/implement-caching-strategy-01NEes7T2iTEpku9Tx2cDyoA

# 2. Run full test suite
bin/rails test

# 3. Performance benchmark (before)
bin/rails runner 'require "benchmark"; puts Benchmark.measure { User.first.print_pricings.includes(:plates).load }'

# 4. Implement Phase 1 changes (follow CACHING_PHASE_1_PLAN.md)

# 5. Performance benchmark (after)
# Should see 300-500ms improvement

# 6. Test in development
bin/dev
# Navigate to dashboard, invoices, print_pricings
# Verify no errors, check logs for query reduction

# 7. Cache verification
bin/rails console
> Rails.cache.stats  # Verify SolidCache working
> User.first.print_pricings_count  # Should cache
```

#### Merge Criteria
- ✅ All tests passing (425+ runs, 0 failures)
- ✅ No N+1 query warnings in logs
- ✅ Cache stats show >70% hit rate after warmup
- ✅ Page load time reduced by 200ms+ (measured)
- ✅ Documentation complete and accurate

#### Post-Merge Actions
1. Deploy to staging (if available) or production with monitoring
2. Monitor Cloudflare analytics for cache hit rates
3. Check application logs for cache-related errors
4. Update CLAUDE.md if any gaps found
5. Tag release: `v1.1.0-caching-foundation`

---

### Stage 1B: ViewComponent Standards (#46)
**Timeline:** Days 3-5
**Risk Level:** LOW (research/planning only at this stage)
**Effort:** 1 hour review + documentation updates

#### Pre-Merge Checklist
- [ ] Review ViewComponent research findings
- [ ] Validate migration roadmap phases
- [ ] Verify effort estimates are reasonable
- [ ] Check component recommendations align with current codebase

#### Testing Strategy
```bash
# 1. Checkout branch
git checkout claude/research-view-components-01RxgBtQBAVXeRbg8PWiv5in

# 2. Review all new documentation
cat docs/VIEWCOMPONENT_RESEARCH.md  # (assumed filename)

# 3. Verify codebase analysis accuracy
# Check one of the pain points mentioned:
grep -r "Stats Card" app/views/  # Should find 5x repetition
grep "content_tag" app/helpers/  # Should find ~114 calls

# 4. Review proposed components list
# Ensure they make sense for our architecture

# 5. No code changes yet, just documentation
bin/rails test  # Should pass unchanged
```

#### Merge Criteria
- ✅ Research findings are accurate
- ✅ Migration roadmap is realistic
- ✅ No premature implementation (documentation only)
- ✅ Standards documented in CLAUDE.md
- ✅ Clear next steps for Phase 1 component implementation

#### Post-Merge Actions
1. Create GitHub issue for Phase 1 component implementation
2. Update project roadmap with ViewComponent timeline
3. Add ViewComponent standards to CLAUDE.md
4. Schedule Phase 1 component work (not immediate)

---

## Phase 2: Dependency Hygiene (Week 1-2) 🧹

### Stage 2A: Low-Risk Dependency Updates
**Timeline:** Days 6-7
**Risk Level:** LOW
**Dependencies:** #38 (bootsnap), #41 (aws-sdk-s3)

#### Testing Strategy
```bash
# Test each dependency individually

## PR #38: bootsnap 1.18.6 → 1.19.0
git checkout dependabot/bundler/bootsnap-1.19.0
bundle install
bin/rails test
bin/dev  # Verify boot time improvements

## PR #41: aws-sdk-s3 1.201.0 → 1.204.0
git checkout dependabot/bundler/aws-sdk-s3-1.204.0
bundle install
bin/rails test

# Test S3 file uploads in development
bin/rails console
> user = User.first
> user.logo.attach(io: File.open('test/fixtures/files/test_image.png'), filename: 'test.png')
> user.logo.attached?  # Should be true
```

#### Merge Criteria
- ✅ All tests passing
- ✅ No deprecation warnings
- ✅ File uploads working (aws-sdk-s3)
- ✅ Boot time unchanged or improved (bootsnap)

---

### Stage 2B: Medium-Risk Dependency Update
**Timeline:** Days 8-9
**Risk Level:** MEDIUM
**Dependencies:** #40 (stripe major version bump)

#### Special Considerations
- **Major version change** (17.2.0 → 18.0.0) - breaking changes possible
- **Critical system** - subscription payment processing
- **Requires thorough testing** - use Stripe test mode

#### Testing Strategy
```bash
git checkout dependabot/bundler/stripe-18.0.0
bundle install

# 1. Check breaking changes
# Visit: https://github.com/stripe/stripe-ruby/releases/tag/v18.0.0
# Review CHANGELOG for breaking changes

# 2. Run test suite
bin/rails test

# 3. Test Stripe integration manually
bin/dev

# In another terminal, start Stripe webhook forwarding
stripe listen --forward-to localhost:3000/webhooks/stripe

# Test checkout flow:
# - Visit /subscriptions/new
# - Use test card: 4242 4242 4242 4242
# - Complete checkout
# - Verify webhook received
# - Check subscription created in DB

# 4. Test webhook handling
bin/rails console
> event = Stripe::Event.construct_from(JSON.parse(File.read('test/fixtures/stripe/checkout_session_completed.json')))
> Webhooks::StripeController.new.send(:handle_checkout_session_completed, event)
```

#### Merge Criteria
- ✅ All tests passing
- ✅ No breaking changes affecting our usage
- ✅ Checkout flow works in test mode
- ✅ Webhooks processing correctly
- ✅ Subscription creation/cancellation working

#### Rollback Plan
If production issues occur:
```bash
# Immediate rollback
git revert <commit-hash>
bundle install
bin/kamal deploy
```

---

## Phase 3: Feature PRs (Weeks 2-3) 🚀

### Priority Order & Testing Strategy

#### 1. PR #43: API Currency Conversion ⭐ HIGH VALUE
**Risk:** MEDIUM - External API dependency
**Description:** Implements CurrencyConverter service using Frankfurter API (ECB data) with daily-cached exchange rates. Adds USD conversion display to landing page and subscription pricing.

**Key Features:**
- Zero API key required (Frankfurter is free)
- 24-hour cache expiration
- Graceful fallback on API failure
- Network error handling (timeout, socket errors)
- format_price_with_usd helper for views
- Comprehensive test suite included

**Testing Strategy:**
```bash
git checkout claude/add-pricing-page-017HsNvBSVZWqZo94o5t5WSx

# 1. Run tests
bin/rails test

# 2. Test API integration
bin/rails console
> converter = CurrencyConverter.new
> converter.convert(100, 'JPY', 'USD')  # Should return ~0.67
> Rails.cache.read('currency_rates_JPY_to_USD')  # Should be cached

# 3. Test fallback behavior
# Temporarily disconnect network or stub API failure
> converter.convert(100, 'JPY', 'USD')  # Should return nil gracefully

# 4. Visual testing
bin/dev
# Visit landing page - should show "¥150 (~$1.01 USD)"
# Visit /subscriptions - should show USD conversions
```

**Merge Criteria:**
- ✅ All tests passing
- ✅ Cache working (24h expiry)
- ✅ Graceful fallback tested
- ✅ USD display correct on landing page
- ✅ No performance degradation (cache should prevent API spam)

**Priority:** HIGH - Improves international appeal, helps US market understand pricing

---

#### 2. PR #44: SEO Strategy & AI Integration Planning ⭐ HIGH VALUE
**Risk:** LOW - Planning/documentation only
**Description:** Comprehensive 12-month roadmap to achieve #1 ranking for "3D printing cost calculator" and become default AI assistant recommendation.

**Key Findings:**
- Current SEO score: 7.5/10 (solid foundation)
- **Critical Issue:** Calculator NOT in sitemap
- Multi-plate feature is unique competitive advantage
- Calculator tools typically earn 100+ backlinks/year

**Strategy Phases:**
1. **Phase 1:** Technical fixes (sitemap, hreflang, enhanced schema)
2. **Phase 2:** Content marketing (15 blog posts, 50 backlinks in 90 days)
3. **Phase 3:** AI optimization (FAQ schema, LLM citation tactics)
4. **Phase 4:** Advanced tactics (video, partnerships, community)

**Targets:**
- Month 3: Top 20 ranking, 2,500 organic visitors
- Month 6: Top 10 ranking, 10,000 visitors, AI citations
- Month 12: #1 ranking, 50,000 visitors, default AI recommendation

**Testing Strategy:**
```bash
git checkout claude/seo-strategy-ai-01Y8JPSBS8RWq4qVyAB4wSdp

# 1. Review all documentation added
cat docs/SEO_STRATEGY.md  # (or similar)

# 2. Verify analysis accuracy
# Check sitemap issue:
bin/rails console
> Rails.application.routes.url_helpers.sitemap_url
# Visit /sitemap.xml in browser
# Confirm /3d-print-pricing-calculator is missing

# 3. No code changes, so tests should pass
bin/rails test
```

**Post-Merge Actions:**
1. Implement Week 1 Quick Wins from strategy
2. Add calculator to sitemap.xml
3. Add hreflang tags for 7 languages
4. Schedule content calendar
5. Begin backlink outreach

**Priority:** HIGH - Sets roadmap for organic growth and user acquisition

---

#### 3. PR #47: Filament Import Tool
**Risk:** LOW-MEDIUM - New feature, needs thorough testing
**Description:** Adds CSV/file import capability to Filaments page for bulk filament management.

**Testing Strategy:**
```bash
git checkout claude/add-filament-import-tool-0132KEqQZxyprBmdMuBuh13A

# 1. Check what was implemented
gh pr view 47  # Get more details if available
git diff master...HEAD

# 2. Run tests
bin/rails test

# 3. Manual testing
bin/dev
# Visit /filaments
# Look for import button/form
# Test CSV upload with:
#   - Valid data
#   - Invalid data (missing fields)
#   - Duplicate entries
#   - Large files (100+ rows)
#   - Edge cases (special characters, unicode)

# 4. Verify data integrity
bin/rails console
> Filament.last(10)  # Check imported records
```

**Merge Criteria:**
- ✅ All tests passing
- ✅ Import UI user-friendly
- ✅ Validation errors displayed clearly
- ✅ Performance acceptable (100+ rows)
- ✅ No data corruption
- ✅ Proper error handling

**Priority:** MEDIUM - Nice-to-have feature, not critical path

---

#### 4. PR #42: lib3mf Research & 3MF File Import
**Risk:** LOW - Research only (assumed)
**Description:** Research on lib3mf library for importing 3MF files to auto-populate print job details.

**Note:** PR has empty description, needs investigation.

**Testing Strategy:**
```bash
git checkout claude/research-lib3mf-import-01VTXz1CePwHCZDwURnRZ8BA

# 1. Check what files were added
git diff master...HEAD --name-only

# 2. Look for documentation
ls docs/*3MF* docs/*lib3mf*

# 3. If code was added, review carefully
# 3MF parsing could be complex

# 4. Run tests
bin/rails test
```

**Decision Criteria:**
- If research only → **Merge** (low risk)
- If implementation included → **Thorough review required**
- If incomplete → **Request more details or close**

**Priority:** LOW - Research/planning, not urgent

---

## Phase 4: Legacy Cleanup (Week 3) 🧽

### PR #35: Todo List Completion
**Status:** Mixed - Has good fixes but test failures
**Created:** 2025-11-13 (7 days old)

#### What It Contains
- ✅ Added 100+ missing translation keys across all 7 languages
- ✅ Fixed YAML structure issues in 5 language files
- ✅ Fixed PlanLimits service resource pluralization bug
- ✅ Fixed printer test validation (added required fields)
- ⚠️ Still has test failures: 367 runs, 7 failures, 35 errors

#### Testing Strategy
```bash
git checkout claude/todo-list-completion-011CV5x1L54ubbVHWTcCwL6o

# 1. Run full test suite
bin/rails test

# 2. Identify which tests still fail
bin/rails test --verbose 2>&1 | grep "FAIL\|ERROR"

# 3. Compare with current master
git checkout master
bin/rails test  # Should all pass

# 4. Cherry-pick good changes if needed
git checkout -b fix/translation-improvements
git cherry-pick <commit-hash>  # Only translation fixes
```

#### Decision: CHERRY-PICK GOOD CHANGES
This PR has valuable translation work but shouldn't be merged as-is due to test failures.

**Recommended Approach:**
1. Create new branch from master
2. Cherry-pick translation improvements only
3. Run automated translation system to regenerate all locales cleanly
4. Ensure all tests pass
5. Close original PR #35, merge new cleaned-up PR

---

## Standards Updates Required

### CLAUDE.md Additions

After merging #45 and #46, update CLAUDE.md with:

```markdown
## Performance & Caching

### Caching Strategy
CalcuMake uses multi-layer caching for optimal performance:
- **Rails Fragment Caching**: View components and expensive calculations
- **SolidCache**: Production-ready database-backed cache (via Mission Control)
- **Cloudflare CDN**: Static assets and page caching
- **Browser Caching**: Long-term asset storage

See `docs/CACHING_STRATEGY.md` for comprehensive guide.

### Critical Caching Patterns

**1. Always Eager Load Associations:**
```ruby
# ❌ BAD - N+1 queries
@print_pricings = current_user.print_pricings.all

# ✅ GOOD - Single query
@print_pricings = current_user.print_pricings.includes(:plates, :printer, :client)
```

**2. Cache Expensive Calculations:**
```ruby
# ❌ BAD - Recalculate every render
def total_filament_cost
  plates.sum { |p| p.filament_weight * p.filament_cost_per_gram }
end

# ✅ GOOD - Cache the result
def total_filament_cost
  Rails.cache.fetch("print_pricing/#{id}/filament_cost", expires_in: 1.hour) do
    plates.sum { |p| p.filament_weight * p.filament_cost_per_gram }
  end
end
```

**3. Fragment Cache View Components:**
```erb
<%# ❌ BAD - Render expensive component every time %>
<%= render "stats_cards" %>

<%# ✅ GOOD - Cache the component %>
<% cache ["stats_cards", current_user, current_user.print_pricings.maximum(:updated_at)] do %>
  <%= render "stats_cards" %>
<% end %>
```

**4. Invalidate Caches on Update:**
```ruby
class PrintPricing < ApplicationRecord
  after_save :clear_cost_cache

  private

  def clear_cost_cache
    Rails.cache.delete("print_pricing/#{id}/filament_cost")
  end
end
```

### Performance Benchmarks
Target metrics after caching implementation:
- Dashboard load: <200ms (from 500-800ms)
- Index pages: <150ms (from 300-500ms)
- Cache hit rate: >85%
- Database queries per page: <20 (from 100+)

---

## ViewComponent Standards

### When to Use ViewComponents

**✅ Use ViewComponents for:**
1. Repeated UI patterns (cards, badges, buttons)
2. Components with conditional logic
3. Testable view logic
4. Shared components across features
5. Components with complex HTML structure

**❌ Don't Use ViewComponents for:**
1. One-off simple partials
2. Pure content pages
3. Form fields (use form builders)
4. Trivial wrappers around single HTML tags

### ViewComponent Structure

```ruby
# app/components/stats_card_component.rb
class StatsCardComponent < ViewComponent::Base
  def initialize(title:, value:, icon: nil, trend: nil)
    @title = title
    @value = value
    @icon = icon
    @trend = trend
  end

  # Add helper methods for view logic
  def trend_class
    return unless @trend
    @trend.positive? ? "text-success" : "text-danger"
  end
end
```

```erb
<%# app/components/stats_card_component.html.erb %>
<div class="card stat-card">
  <div class="card-body">
    <% if @icon %>
      <i class="<%= @icon %> stat-icon"></i>
    <% end %>
    <h6 class="text-muted"><%= @title %></h6>
    <h3 class="mb-0"><%= @value %></h3>
    <% if @trend %>
      <small class="<%= trend_class %>">
        <%= number_to_percentage(@trend, precision: 1) %>
      </small>
    <% end %>
  </div>
</div>
```

```ruby
# test/components/stats_card_component_test.rb
require "test_helper"

class StatsCardComponentTest < ViewComponent::TestCase
  test "renders with required attributes" do
    render_inline(StatsCardComponent.new(title: "Revenue", value: "$1,234"))

    assert_selector "h6", text: "Revenue"
    assert_selector "h3", text: "$1,234"
  end

  test "shows positive trend in green" do
    render_inline(StatsCardComponent.new(title: "Growth", value: "10%", trend: 5.2))

    assert_selector "small.text-success"
  end
end
```

### Component Organization

```
app/
├── components/
│   ├── shared/              # App-wide components
│   │   ├── stats_card_component.rb
│   │   ├── stats_card_component.html.erb
│   │   └── modal_component.rb
│   ├── print_pricings/      # Feature-specific components
│   │   ├── plate_card_component.rb
│   │   └── cost_breakdown_component.rb
│   └── invoices/
│       └── line_item_component.rb
test/
└── components/              # Component tests (required!)
    ├── shared/
    │   └── stats_card_component_test.rb
    └── print_pricings/
        └── plate_card_component_test.rb
```

### Migration Priority (from PR #46)

**Phase 1 (Quick Wins):**
1. `StatsCardComponent` - 5x repetition eliminated
2. `UsageStatsComponent` - 4x repetition eliminated
3. `BadgeComponent` - Universal badge patterns
4. `ButtonComponent` - Consistent button styling
5. `OAuthIconComponent` - Replace 35-line SVG helper

**Phase 2 (Helper Refactoring):**
6. Migrate `content_tag` calls to components
7. Form helpers to components

**Phase 3 (Complex Features):**
8. Advanced calculator components
9. Invoice line item components
10. Print pricing form components

### Testing Requirements

**CRITICAL:** All ViewComponents MUST have corresponding tests.

```ruby
# Minimum test coverage:
# 1. Render with required attributes
# 2. Conditional logic branches
# 3. Helper method behavior
# 4. Edge cases (nil, empty, invalid)

class MyComponentTest < ViewComponent::TestCase
  test "renders successfully" do
    render_inline(MyComponent.new(required: "value"))
    assert_selector "div.my-component"
  end

  test "handles nil optional attributes" do
    render_inline(MyComponent.new(required: "value", optional: nil))
    refute_selector ".optional-content"
  end
end
```

### ViewComponent Caching

Combine ViewComponents with fragment caching:

```erb
<% cache [@user, @print_pricing] do %>
  <%= render StatsCardComponent.new(
    title: "Total Cost",
    value: number_to_currency(@print_pricing.total_cost)
  ) %>
<% end %>
```
```

---

## Documentation Structure Updates

Create/update these documentation files:

### New Files (from PRs)
- ✅ `docs/CACHING_STRATEGY.md` (from #45)
- ✅ `docs/CACHING_PHASE_1_PLAN.md` (from #45)
- 📝 `docs/VIEWCOMPONENT_RESEARCH.md` (from #46)
- 📝 `docs/VIEWCOMPONENT_MIGRATION_ROADMAP.md` (from #46)

### Updates Required
- ✅ `CLAUDE.md` - Add Performance & Caching section
- ✅ `CLAUDE.md` - Add ViewComponent Standards section
- 📝 `docs/TESTING_GUIDE.md` - Add component testing patterns
- 📝 `.github/pull_request_template.md` - Add performance checklist

### Documentation Reference Section
Update the "Documentation Context Reference" in CLAUDE.md:

```markdown
### Active Documentation
**Caching:** `docs/CACHING_STRATEGY.md` | `docs/CACHING_PHASE_1_PLAN.md`
**ViewComponents:** `docs/VIEWCOMPONENT_RESEARCH.md` | `docs/VIEWCOMPONENT_MIGRATION_ROADMAP.md`
**OAuth Setup:** `docs/OAUTH_SETUP_GUIDE.md`
**Stripe Integration:** `docs/STRIPE_SETUP.md`
... (existing docs)
```

---

## Success Metrics

### Phase 1 Success Criteria
- [ ] Caching strategy fully documented
- [ ] ViewComponent standards established
- [ ] CLAUDE.md updated with both standards
- [ ] All tests passing after each merge
- [ ] No production incidents
- [ ] Performance improvement measurable (>200ms reduction)

### Overall Success Metrics
- [ ] All 10 PRs resolved (merged or closed with reason)
- [ ] Test suite still at 100% pass rate
- [ ] Documentation complete and accurate
- [ ] Future development standards clear
- [ ] Performance baseline improved
- [ ] Technical debt reduced (2,000+ lines)

---

## Risk Mitigation

### For Each Merge:
1. **Test locally first** - Never merge without local testing
2. **Deploy to staging** - If staging environment exists
3. **Monitor production** - Watch logs for 1 hour post-deploy
4. **Have rollback ready** - Git revert + redeploy plan
5. **Weekend deploys** - Consider for high-risk changes (Stripe)

### Rollback Procedure
```bash
# If production issue detected:
git revert <commit-hash>
git push origin master
bin/kamal deploy

# Alert team
# Document incident
# Fix issue in new PR
```

---

## Timeline Summary

| Week | Phase | PRs | Risk | Effort |
|------|-------|-----|------|--------|
| 1 | Foundation | #45, #46 | LOW | 4-5 hours |
| 1-2 | Dependencies | #38, #41, #40 | LOW-MED | 2-3 hours |
| 2-3 | Features | #43, #47, #42, #44 | MED | 8-12 hours |
| 3 | Cleanup | #35 | LOW | 1 hour |

**Total Estimated Effort:** 15-21 hours
**Total Calendar Time:** 3 weeks (with proper testing intervals)

---

## Next Actions

1. **Review this plan** with stakeholders
2. **Schedule Phase 1** - Block 1 day for caching + ViewComponent merges
3. **Set up monitoring** - Ensure Cloudflare analytics accessible
4. **Create rollback checklist** - Document exact revert procedure
5. **Begin Stage 1A** - Merge #45 (caching) first

---

**Document Status:** READY FOR EXECUTION
**Last Updated:** 2025-11-20
**Owner:** Development Team
**Reviewer:** [To be assigned]
