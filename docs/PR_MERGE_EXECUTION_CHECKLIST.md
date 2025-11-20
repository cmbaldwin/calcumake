# PR Merge Execution Checklist

**Quick Reference:** Step-by-step execution guide for [docs/PR_MERGE_STRATEGY.md](PR_MERGE_STRATEGY.md)

---

## Phase 1: Foundation Layer (Days 1-5)

### ✅ Stage 1A: Caching Implementation (#45)
**When:** Days 1-2 | **Effort:** 3-4 hours

```bash
# 1. Checkout and review
git checkout claude/implement-caching-strategy-01NEes7T2iTEpku9Tx2cDyoA
cat docs/CACHING_STRATEGY.md
cat docs/CACHING_PHASE_1_PLAN.md

# 2. Run tests
bin/rails test

# 3. Merge to master
git checkout master
git merge --no-ff claude/implement-caching-strategy-01NEes7T2iTEpku9Tx2cDyoA
git push origin master

# 4. Deploy
bin/kamal deploy

# 5. Monitor (1 hour)
# - Watch application logs
# - Check Cloudflare analytics
# - Verify no errors in production

# 6. Tag release
git tag v1.1.0-caching-foundation
git push --tags
```

**Success Criteria:**
- [ ] All tests passing
- [ ] Documentation reviewed and accurate
- [ ] No production errors after 1 hour
- [ ] CLAUDE.md reflects new caching standards

---

### ✅ Stage 1B: ViewComponent Standards (#46)
**When:** Days 3-5 | **Effort:** 1 hour review

```bash
# 1. Checkout and review
git checkout claude/research-view-components-01RxgBtQBAVXeRbg8PWiv5in

# 2. Review research findings
# Check for documentation files added by PR
cat docs/VIEWCOMPONENT_RESEARCH.md 2>/dev/null || echo "Check PR for docs"

# 3. Verify no premature implementation
git diff master...HEAD --name-only | grep "app/components" && echo "⚠️ Components found!" || echo "✅ No implementation yet"

# 4. Run tests (should pass unchanged)
bin/rails test

# 5. Merge
git checkout master
git merge --no-ff claude/research-view-components-01RxgBtQBAVXeRbg8PWiv5in
git push origin master

# 6. Create follow-up issue
gh issue create --title "Implement Phase 1 ViewComponents" \
  --body "Per docs/VIEWCOMPONENT_MIGRATION_ROADMAP.md Phase 1:
  - [ ] StatsCardComponent
  - [ ] UsageStatsComponent
  - [ ] BadgeComponent
  - [ ] ButtonComponent
  - [ ] OAuthIconComponent"
```

**Success Criteria:**
- [ ] Research findings validated
- [ ] No code implementation (documentation only)
- [ ] CLAUDE.md updated with ViewComponent standards
- [ ] Follow-up issue created for Phase 1 implementation

---

## Phase 2: Dependency Updates (Days 6-9)

### ✅ Stage 2A: Low-Risk Dependencies (#38, #41)
**When:** Days 6-7 | **Effort:** 1 hour each

#### PR #38: bootsnap 1.18.6 → 1.19.0
```bash
git checkout dependabot/bundler/bootsnap-1.19.0
bundle install
bin/rails test
bin/dev  # Verify boot time

# Merge if passing
git checkout master
git merge --no-ff dependabot/bundler/bootsnap-1.19.0
git push origin master
bin/kamal deploy
```

#### PR #41: aws-sdk-s3 1.201.0 → 1.204.0
```bash
git checkout dependabot/bundler/aws-sdk-s3-1.204.0
bundle install
bin/rails test

# Test S3 uploads
bin/rails console
# Test file upload functionality

# Merge if passing
git checkout master
git merge --no-ff dependabot/bundler/aws-sdk-s3-1.204.0
git push origin master
bin/kamal deploy
```

**Success Criteria:**
- [ ] All tests passing for both PRs
- [ ] No deprecation warnings
- [ ] File uploads still work (aws-sdk-s3)
- [ ] Production stable after deployment

---

### ⚠️ Stage 2B: Medium-Risk Dependency (#40)
**When:** Days 8-9 | **Effort:** 2-3 hours

#### PR #40: stripe 17.2.0 → 18.0.0 (MAJOR VERSION)
```bash
# 1. Check breaking changes
# Visit: https://github.com/stripe/stripe-ruby/releases/tag/v18.0.0

# 2. Checkout and test
git checkout dependabot/bundler/stripe-18.0.0
bundle install
bin/rails test

# 3. Manual integration testing
bin/dev

# In another terminal:
stripe listen --forward-to localhost:3000/webhooks/stripe

# Test:
# - Visit /subscriptions/new
# - Use test card: 4242 4242 4242 4242
# - Complete checkout
# - Verify webhook received
# - Check subscription in database

# 4. If all tests pass, merge
git checkout master
git merge --no-ff dependabot/bundler/stripe-18.0.0
git push origin master

# 5. Deploy with monitoring
bin/kamal deploy

# 6. Monitor production for 2 hours
# - Watch for Stripe webhook errors
# - Test checkout flow in production
# - Have rollback ready
```

**Rollback Plan (if issues):**
```bash
git revert HEAD
git push origin master
bin/kamal deploy
# Alert team, document incident
```

**Success Criteria:**
- [ ] No breaking changes affecting our usage
- [ ] All tests passing
- [ ] Checkout flow works in test mode
- [ ] Webhooks processing correctly
- [ ] Production stable after 2 hours

---

## Phase 3: Feature PRs (Days 10-18)

### ⭐ Priority 1: Currency Conversion (#43)
**When:** Days 10-12 | **Effort:** 2-3 hours

```bash
# 1. Checkout and test
git checkout claude/add-pricing-page-017HsNvBSVZWqZo94o5t5WSx
bin/rails test

# 2. Test API integration
bin/rails console
> converter = CurrencyConverter.new
> converter.convert(100, 'JPY', 'USD')  # Should return ~0.67
> Rails.cache.read('currency_rates_JPY_to_USD')  # Verify cache

# 3. Visual testing
bin/dev
# Check landing page: should show "¥150 (~$1.01 USD)"
# Check /subscriptions: USD conversions present

# 4. Merge
git checkout master
git merge --no-ff claude/add-pricing-page-017HsNvBSVZWqZo94o5t5WSx
git push origin master
bin/kamal deploy
```

**Success Criteria:**
- [ ] All tests passing
- [ ] API integration working
- [ ] 24-hour cache working
- [ ] Graceful fallback tested
- [ ] USD display correct on all pages

---

### ⭐ Priority 2: SEO Strategy (#44)
**When:** Days 13-14 | **Effort:** 2 hours

```bash
# 1. Checkout and review
git checkout claude/seo-strategy-ai-01Y8JPSBS8RWq4qVyAB4wSdp

# 2. Review documentation
ls docs/SEO*.md
cat docs/SEO_STRATEGY.md  # (or similar filename)

# 3. Verify no breaking changes
bin/rails test

# 4. Check sitemap issue mentioned in PR
# Visit /sitemap.xml - verify calculator is missing

# 5. Merge
git checkout master
git merge --no-ff claude/seo-strategy-ai-01Y8JPSBS8RWq4qVyAB4wSdp
git push origin master

# 6. Create follow-up issues
gh issue create --title "SEO Week 1 Quick Wins" \
  --body "Per SEO strategy:
  - [ ] Add calculator to sitemap.xml
  - [ ] Add hreflang tags for 7 languages
  - [ ] Enhanced schema markup
  - [ ] Fix title/meta tags"
```

**Success Criteria:**
- [ ] Documentation reviewed and accurate
- [ ] SEO analysis findings validated
- [ ] No code changes (planning only)
- [ ] Follow-up issues created

---

### Priority 3: Filament Import Tool (#47)
**When:** Days 15-16 | **Effort:** 2-3 hours

```bash
# 1. Checkout and explore
git checkout claude/add-filament-import-tool-0132KEqQZxyprBmdMuBuh13A
git diff master...HEAD --stat

# 2. Run tests
bin/rails test

# 3. Manual testing
bin/dev
# Visit /filaments
# Test CSV upload:
#   - Valid data
#   - Invalid data
#   - Large files (100+ rows)
#   - Edge cases

# 4. Check data integrity
bin/rails console
> Filament.last(10)

# 5. Merge if passing
git checkout master
git merge --no-ff claude/add-filament-import-tool-0132KEqQZxyprBmdMuBuh13A
git push origin master
bin/kamal deploy
```

**Success Criteria:**
- [ ] All tests passing
- [ ] Import UI user-friendly
- [ ] Validation errors clear
- [ ] Performance acceptable
- [ ] No data corruption

---

### Priority 4: lib3mf Research (#42)
**When:** Days 17-18 | **Effort:** 1 hour

```bash
# 1. Investigate what was added
git checkout claude/research-lib3mf-import-01VTXz1CePwHCZDwURnRZ8BA
git diff master...HEAD --name-only

# 2. Look for documentation
ls docs/*3MF* docs/*lib3mf* 2>/dev/null || echo "No docs found"

# 3. Run tests
bin/rails test

# 4. Decision:
# - Research only → Merge
# - Implementation included → Thorough review
# - Incomplete/empty → Close PR

# 5. If merging:
git checkout master
git merge --no-ff claude/research-lib3mf-import-01VTXz1CePwHCZDwURnRZ8BA
git push origin master
```

**Success Criteria:**
- [ ] Content reviewed
- [ ] Tests passing
- [ ] Decision made (merge/close/review)

---

## Phase 4: Legacy Cleanup (Days 19-21)

### PR #35: Todo List Completion
**Status:** Has valuable work but test failures

#### Recommended: Cherry-Pick Approach
```bash
# 1. Review what's in the PR
git checkout claude/todo-list-completion-011CV5x1L54ubbVHWTcCwL6o
bin/rails test  # Will show failures

# 2. Identify good changes
# Translation improvements are valuable
# PlanLimits fix is good
# Test failures are problematic

# 3. Create clean branch
git checkout master
git checkout -b fix/translation-improvements-clean

# 4. Cherry-pick translation commits only
git log claude/todo-list-completion-011CV5x1L54ubbVHWTcCwL6o --oneline
git cherry-pick <commit-hash-for-translations>

# 5. Re-run automated translations to clean up
bin/sync-translations

# 6. Run tests (should all pass)
bin/rails test

# 7. If passing, create PR and merge
gh pr create --title "Translation improvements from PR #35" \
  --body "Cherry-picked translation fixes from #35, regenerated with automated system"

# 8. Close original PR #35
gh pr close 35 --comment "Closed in favor of cleaned-up PR with passing tests"
```

**Success Criteria:**
- [ ] Translation improvements preserved
- [ ] All tests passing
- [ ] PlanLimits fix included (if relevant)
- [ ] Original PR #35 closed with explanation

---

## Post-Phase Verification

### Final Checklist
- [ ] All 10 PRs resolved (merged or closed)
- [ ] Test suite at 100% pass rate
- [ ] No production errors
- [ ] Documentation up to date
- [ ] CLAUDE.md reflects all standards
- [ ] Performance improvements measurable

### Performance Validation
```bash
# Run performance benchmarks
bin/rails runner 'require "benchmark"; puts Benchmark.measure {
  user = User.first
  user.print_pricings.includes(:plates, :printer, :client).load
}'

# Should see:
# - Dashboard load: <200ms (from 500-800ms)
# - Fewer than 20 queries per page
# - Cache hit rate >85%
```

### Documentation Audit
```bash
# Verify all new docs exist
ls -la docs/CACHING_STRATEGY.md
ls -la docs/CACHING_PHASE_1_PLAN.md
ls -la docs/VIEWCOMPONENT_RESEARCH.md
ls -la docs/VIEWCOMPONENT_MIGRATION_ROADMAP.md
ls -la docs/PR_MERGE_STRATEGY.md

# Verify CLAUDE.md updates
grep "Performance & Caching" CLAUDE.md
grep "ViewComponent Standards" CLAUDE.md
```

---

## Emergency Rollback Procedure

If any deployment causes production issues:

```bash
# 1. Immediate rollback
git revert HEAD
git push origin master
bin/kamal deploy

# 2. Alert team
# - Document incident
# - Note symptoms
# - Record time/scope

# 3. Fix in new PR
# - Investigate issue
# - Create fix branch
# - Full testing cycle
# - Document what went wrong

# 4. Post-mortem
# - Update PR_MERGE_STRATEGY.md
# - Add to testing checklist
# - Prevent recurrence
```

---

## Contact & Support

**Questions?** Review:
- [docs/PR_MERGE_STRATEGY.md](PR_MERGE_STRATEGY.md) - Full strategic plan
- [CLAUDE.md](../CLAUDE.md) - Coding standards
- GitHub Issues - Create issue for blockers

**Monitoring Tools:**
- Application logs: `bin/kamal app logs`
- Cloudflare Analytics: Dashboard
- Stripe Dashboard: Webhook logs
- Rails cache stats: `Rails.cache.stats` in console

---

**Document Version:** 1.0
**Last Updated:** 2025-11-20
**Execution Time:** 3 weeks (estimated)
**Total Effort:** 15-21 hours
