# Stripe AI + GEO/AIEO Integration Plan

> Phased plan for AI-first optimization: Agentic Commerce, AI crawler support, and Generative Engine Optimization.

**Date:** 2026-03-19
**Branch:** `claude/stripe-ai-seo-integration-9O7FX`
**GEO Audit Score:** 32.65/100 (baseline)

---

## Current State Assessment

### GEO Audit Results (calcumake.com)

| Category | Weight | Score | Notes |
|---|---|---|---|
| AI Citability & Visibility | 25% | 35 | No llms.txt, limited factual density |
| Brand Authority Signals | 20% | 10 | Near-zero external mentions (1 HN post, 2 GitHub stars) |
| Content Quality & E-E-A-T | 20% | 25 | 5 blog posts, all product announcements, no educational content |
| Technical Foundations | 15% | 62 | Solid sitemap, 7 languages, good hreflang |
| Structured Data | 10% | 68 | Strong JSON-LD, but unverified AggregateRating is a penalty risk |
| Platform Optimization | 10% | 8 | Not listed on any directories, forums, or review sites |
| **OVERALL** | **100%** | **32.65** | |

### Stripe Status
- Stripe Checkout + webhooks already integrated (PR #26)
- Subscription plans configured: Free, Startup (¥150/mo), Pro (¥1,500/mo)
- `Webhooks::StripeController` handles `checkout.session.completed`
- Stripe API version: `2024-11-20.acacia`

### Key Gaps
1. **No AI crawler awareness** — robots.txt has generic `User-agent: *` only
2. **No llms.txt** — AI models have no structured guide to the site
3. **No Agentic Commerce** — Not discoverable/purchasable through AI agents
4. **Thin content** — 5 product-announcement blog posts, zero educational content
5. **Zero brand mentions** across Reddit, YouTube, Product Hunt, directories

---

## Phase 1: AI Crawler Foundation (Week 1-2)

**Goal:** Make CalcuMake fully visible and well-structured for AI systems.

### 1.1 Create `/llms.txt` and `/llms-full.txt`

Create a route + controller action serving markdown content at `/llms.txt`:

```markdown
# CalcuMake

> CalcuMake is a free 3D print cost calculator and project management SaaS.
> Calculate filament, electricity, labor, and machine costs across multiple
> build plates. Multi-currency (USD, EUR, GBP, JPY, CAD, AUD), 7 languages,
> REST API, invoicing, and client management.

CalcuMake helps 3D printing businesses and hobbyists accurately price print
jobs by breaking down all cost factors: filament weight × price per kg,
printer power consumption × hours × energy rate, labor time, and machine
depreciation. Supports up to 10 plates per job with 16 filaments per plate.

## Tools

- [3D Print Pricing Calculator](https://calcumake.com/3d-print-pricing-calculator): Free no-signup calculator with PDF/CSV export
- [Subscription Plans](https://calcumake.com/subscriptions/pricing): Free, Startup (¥150/mo), Pro (¥1,500/mo)

## API

- [API Documentation](https://calcumake.com/api-documentation): REST API overview and authentication
- [API Health Check](https://calcumake.com/api/v1/health): Public endpoint

## Blog

- [Blog](https://calcumake.com/blog): 3D printing guides, cost analysis, and product updates

## Legal

- [Privacy Policy](https://calcumake.com/privacy-policy)
- [User Agreement](https://calcumake.com/user-agreement)
- [Commerce Disclosure](https://calcumake.com/commerce-disclosure)

## Optional

- [Support](https://calcumake.com/support)
```

**Implementation:**
- Add `get "llms.txt" => "pages#llms_txt"` route (format: :text)
- Add `get "llms-full.txt" => "pages#llms_full_txt"` route
- `llms-full.txt` includes expanded content: calculator methodology, cost formulas, API endpoint descriptions
- Serve with `Content-Type: text/markdown` header

### 1.2 Update `robots.txt` for AI Crawlers

Replace the static `public/robots.txt` with a dynamic route or update the file:

```
# CalcuMake - 3D Print Cost Calculator
# https://calcumake.com

# ===== Traditional Search Engines =====
User-agent: *
Allow: /
Disallow: /admin/
Disallow: /users/
Disallow: /user_profiles/
Disallow: /users/sign_in
Disallow: /users/sign_up
Disallow: /users/password

# ===== AI Search & Retrieval Bots (ALLOW) =====
# These bots power AI-powered search results — we WANT to appear in AI answers

User-agent: ChatGPT-User
Allow: /

User-agent: OAI-SearchBot
Allow: /

User-agent: Claude-User
Allow: /

User-agent: Claude-SearchBot
Allow: /

User-agent: PerplexityBot
Allow: /

User-agent: Perplexity-User
Allow: /

User-agent: Applebot-Extended
Allow: /

User-agent: DuckAssistBot
Allow: /

User-agent: Amzn-SearchBot
Allow: /

# ===== AI Training Bots (BLOCK) =====
# Block model training crawlers — our content is for search visibility, not training data

User-agent: GPTBot
Disallow: /

User-agent: ClaudeBot
Disallow: /

User-agent: Google-Extended
Disallow: /

User-agent: CCBot
Disallow: /

User-agent: Bytespider
Disallow: /

User-agent: Diffbot
Disallow: /

User-agent: cohere-ai
Disallow: /

User-agent: DeepSeekBot
Disallow: /

User-agent: img2dataset
Disallow: /

User-agent: meta-externalagent
Disallow: /

# Sitemap
Sitemap: https://calcumake.com/sitemap.xml
```

### 1.3 Add `BlogPosting` Schema to Articles

Update `app/views/articles/show.html.erb` to include:
- `BlogPosting` JSON-LD with `headline`, `datePublished`, `dateModified`, `author` (Person), `publisher` (Organization)
- `BreadcrumbList` schema for navigation

### 1.4 Fix Structured Data Risks

- **Remove or substantiate AggregateRating** (4.8/5, 127 reviews) — this is a Google penalty risk if reviews aren't on a third-party platform
- Make FAQ schemas page-specific rather than appearing on every page

### 1.5 Add Author/E-E-A-T Signals

- Add author bio section to blog articles with 3D printing credentials
- Add `Person` schema for author with `sameAs` links

**Files to modify:**
- `public/robots.txt` (or create dynamic route)
- `config/routes.rb` (add llms.txt routes)
- `app/controllers/pages_controller.rb` (add llms_txt actions)
- `app/views/articles/show.html.erb` (BlogPosting schema)
- `app/helpers/seo_helper.rb` (fix AggregateRating, add BlogPosting helper)
- `config/sitemap.rb` (add llms.txt to sitemap)

---

## Phase 2: Stripe Agentic Commerce (Week 3-4)

**Goal:** Make CalcuMake subscription plans purchasable through AI agents (ChatGPT, Copilot, etc.) via Stripe's Agentic Commerce Suite.

### Context: What Changed

Stripe launched the **Agentic Commerce Suite** (Dec 2025) and **Machine Payments Protocol** (March 2026). The Agentic Commerce Protocol (ACP), co-developed with OpenAI, enables AI agents to discover products, conduct checkout, and process payments. First live use: ChatGPT Instant Checkout with Etsy/Shopify merchants.

Partners include: **OpenAI (ChatGPT), Microsoft Copilot, Anthropic, Perplexity, Vercel, Lovable, Replit**.

### 2.1 Stripe Dashboard: Enable Agentic Commerce

**No-code steps in Stripe Dashboard:**
1. Navigate to Agentic Commerce Onboarding
2. Create Stripe Profile for CalcuMake
3. Configure policy URLs:
   - Privacy Policy: `https://calcumake.com/privacy-policy`
   - Terms of Service: `https://calcumake.com/user-agreement`
   - Seller Shop Policies: `https://calcumake.com/commerce-disclosure`
4. Enable AI agent channels (ChatGPT, Microsoft Copilot)

### 2.2 Upload Product Catalog

Create a product catalog CSV for Stripe's Agentic Commerce Suite:

```csv
sku,name,description,price,currency,availability,tax_code
calcumake-startup,CalcuMake Startup Plan,3D print cost calculator with project management for small businesses. Up to 50 print pricings/month.,150,jpy,in_stock,txcd_10000000
calcumake-pro,CalcuMake Pro Plan,Full-featured 3D print project management with unlimited pricings and invoicing and API access.,1500,jpy,in_stock,txcd_10000000
```

Upload via API:
```ruby
# lib/tasks/stripe_catalog.rake
namespace :stripe do
  desc "Upload product catalog for agentic commerce"
  task upload_catalog: :environment do
    # Generate CSV, upload via Stripe Files API, create import set
  end
end
```

### 2.3 Handle Agentic Orders

Extend existing webhook handler to recognize agentic checkout sessions:

```ruby
# In Webhooks::StripeController
# Agentic checkouts come through the same checkout.session.completed event
# but include metadata about the AI agent source
def handle_checkout_completed(session)
  # Existing subscription logic works — agentic checkouts use the same flow
  # Add tracking for AI agent attribution
  if session.metadata&.dig("agentic_source")
    Rails.logger.info "Agentic order from: #{session.metadata['agentic_source']}"
    # Track conversion source for analytics
  end
end
```

### 2.4 Stripe API Version Update

Update from `2024-11-20.acacia` to a 2025+ version that supports agentic commerce features. The ACP endpoints require `Stripe-Version: 2025-09-30.clover` or later.

### 2.5 Add Product Descriptions Optimized for AI

Update Stripe product descriptions to be machine-readable and clear:
- Use factual, specific language (not marketing copy)
- Include key capabilities, limits, and pricing in description
- Add `description_for_model` metadata where supported

**Files to modify:**
- `config/initializers/stripe.rb` (API version update)
- `app/controllers/webhooks/stripe_controller.rb` (agentic attribution tracking)
- `lib/tasks/stripe_catalog.rake` (new — catalog upload task)
- Stripe Dashboard (manual configuration)

**New ENV variables:**
- None required — uses existing `STRIPE_SECRET_KEY`

---

## Phase 3: Content & GEO Optimization (Week 5-8)

**Goal:** Build the content corpus and citability that makes AI models recommend CalcuMake.

### 3.1 Educational Content Strategy

Publish 2-4 articles per month targeting informational queries AI models answer:

**Priority articles (highest AI citation potential):**
1. "How to Calculate 3D Printing Costs: The Complete Guide (2026)"
2. "FDM vs Resin Printing: Full Cost Comparison with Real Data"
3. "Hidden Costs of 3D Printing Most People Miss"
4. "How to Price 3D Prints for Profit: A Data-Driven Approach"
5. "Electricity Costs of 3D Printing: What You Actually Pay per kWh"
6. "3D Printing Cost Per Hour: Breaking Down Every Expense"

**Content format for AI citability:**
- Lead with a direct answer in the first 200 words (AI extracts opening content)
- Include specific data points and formulas (e.g., "Filament cost = weight_grams × price_per_kg / 1000")
- Use technical terminology (+28% AI visibility boost per research)
- Add comparison tables with real numbers
- Include FAQ sections with schema markup

### 3.2 Improve Homepage AI Citability

- Add a "How It Works" section with concrete steps and numbers
- Include industry benchmark data (average cost per print hour, filament costs by type)
- Add comparison to competitors (positioned as "CalcuMake includes X, Y, Z that others don't")

### 3.3 Calculator Page GEO Optimization

- Add semantic H2/H3 headings for each cost category
- Include methodology explanation below the calculator
- Add "powered by" badges or citations for formulas used
- Create a dedicated `/3d-printing-cost-methodology` page

### 3.4 API Documentation as GEO Asset

Create a public, crawlable API docs page (currently behind `/api-documentation` but could be more detailed):
- Expand with examples, use cases, and integration guides
- This becomes the page AI models cite when developers ask about 3D printing APIs

---

## Phase 4: Brand Authority & Distribution (Ongoing, starts Week 3)

**Goal:** Generate the external signals AI models use to decide what to recommend.

### 4.1 Platform Launches (Highest ROI)

| Platform | Priority | Action | Expected Impact |
|---|---|---|---|
| Product Hunt | P0 | Full launch with assets | Dozens of backlinks, brand mentions |
| AlternativeTo | P0 | List as alternative to Prusa Calculator | Direct competitor positioning |
| r/3Dprinting | P1 | Educational post + comments | Community authority |
| r/FixMyPrint | P1 | Helpful cost-related answers | Niche authority |
| SaaSHub | P1 | Create listing | Directory presence |
| G2 / Capterra | P2 | Create profiles, seek reviews | Review authority |
| Hacker News | P2 | Re-launch with better positioning | Tech community signal |
| GitHub | P2 | Improve README, add topics, engage | OSS community signal |

### 4.2 Content Distribution

- Submit educational articles to 3D printing publications (All3DP, Fabbaloo)
- Create YouTube short-form content on 3D printing cost breakdowns
- Post on relevant LinkedIn groups

### 4.3 Directory & Listing Strategy

Submit to tool aggregators and directories that AI models frequently cite:
- AlternativeTo, SaaSHub, SaaSWorthy, There's a Reason
- GitHub awesome-3d-printing lists
- 3D printing resource directories

---

## Implementation Priority Matrix

| # | Task | Phase | Effort | Impact | Priority |
|---|---|---|---|---|---|
| 1 | Create `/llms.txt` + route | P1 | Small | High | **Do First** |
| 2 | Update `robots.txt` for AI crawlers | P1 | Small | High | **Do First** |
| 3 | Add `BlogPosting` schema | P1 | Small | Medium | **Do First** |
| 4 | Fix AggregateRating risk | P1 | Small | High (risk) | **Do First** |
| 5 | Enable Stripe Agentic Commerce (Dashboard) | P2 | Small | High | **Week 3** |
| 6 | Upload product catalog to Stripe | P2 | Medium | High | **Week 3** |
| 7 | Update Stripe API version | P2 | Small | Required | **Week 3** |
| 8 | Publish first educational article | P3 | Medium | High | **Week 3** |
| 9 | Product Hunt launch | P4 | Medium | Very High | **Week 4** |
| 10 | Submit to 5+ directories | P4 | Small | Medium | **Week 4** |
| 11 | Content calendar (2-4/month) | P3 | Ongoing | Very High | **Ongoing** |
| 12 | Reddit/forum engagement | P4 | Ongoing | Medium | **Ongoing** |

---

## Success Metrics

| Metric | Baseline | 30-Day Target | 90-Day Target |
|---|---|---|---|
| GEO Score | 32.65 | 50+ | 65+ |
| llms.txt | Missing | Live | Optimized |
| AI crawler directives | 0 specific | 20+ bots configured | Maintained |
| Blog articles | 5 (product only) | 8+ (inc. educational) | 15+ |
| External brand mentions | ~2 | 10+ | 30+ |
| Product Hunt | Not listed | Launched | Top 5 daily |
| Directory listings | 0 | 5+ | 10+ |
| Stripe agentic commerce | Not enabled | Enabled + catalog | Active orders |
| AI search citations | 0 known | Monitoring | Appearing in results |

---

## Technical Notes

### Stripe ACP Architecture

```
AI Agent (ChatGPT/Copilot) ──→ Stripe Hosted ACP ──→ CalcuMake Webhooks
         │                            │                      │
    User intent            Product catalog            checkout.session.completed
    Payment token          SharedPaymentToken          Create subscription
```

CalcuMake uses the **Stripe-hosted ACP** path (low-code). Stripe handles the checkout UI within the AI agent. CalcuMake receives the same `checkout.session.completed` webhook it already handles. Minimal code changes required.

### AI Crawler Tier Strategy

```
Tier 1 (ALLOW): Search & retrieval bots → appear in AI answers
  ChatGPT-User, OAI-SearchBot, Claude-User, Claude-SearchBot, PerplexityBot

Tier 2 (BLOCK): Training bots → don't donate content for free
  GPTBot, ClaudeBot, Google-Extended, CCBot, Bytespider, Diffbot

Tier 3 (MONITOR): New bots → review quarterly
  Check ai-robots-txt/ai.robots.txt GitHub repo for updates
```

### llms.txt Spec Reference

- Format: Markdown with H1 (required), blockquote summary, H2 sections with link lists
- Location: `/llms.txt` at site root
- Companion: `/llms-full.txt` with expanded content (AI agents visit this 2x more)
- Convention: Serve `.md` versions of pages at same URL + `.md` suffix
- Spec: https://llmstxt.org/

---

## References

- [Stripe Agentic Commerce Suite](https://stripe.com/blog/agentic-commerce-suite)
- [Stripe ACP Documentation](https://docs.stripe.com/agentic-commerce/protocol)
- [Agentic Commerce Protocol (GitHub)](https://github.com/agentic-commerce-protocol/agentic-commerce-protocol)
- [OpenAI: Buy it in ChatGPT](https://openai.com/index/buy-it-in-chatgpt/)
- [Stripe Machine Payments Protocol (MPP)](https://stripe.com/newsroom/news/agentic-commerce-suite)
- [llms.txt Specification](https://llmstxt.org/)
- [GEO Complete Guide 2026 (Search Engine Land)](https://searchengineland.com/mastering-generative-engine-optimization-in-2026-full-guide-469142)
- [GEO Guide 2026 (Frase.io)](https://www.frase.io/blog/what-is-generative-engine-optimization-geo)
- [SEO vs AEO vs GEO 2026 (Ladybugz)](https://www.ladybugz.com/seo-aeo-geo-guide-2026/)
- [ai-robots-txt/ai.robots.txt (GitHub)](https://github.com/ai-robots-txt/ai.robots.txt)
- [geo-seo-claude (audit tool)](https://github.com/zubair-trabzada/geo-seo-claude)
