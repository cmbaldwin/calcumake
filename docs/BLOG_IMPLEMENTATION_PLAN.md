# Blog System Implementation Plan - Lexxy + Translation

**Date:** November 25, 2025
**Goal:** Build SEO-optimized blog with Lexxy editor and automated translation to 7 languages

**Current Status:** 🟢 **60% Complete** (Phases 1-7 done, 8-11 remaining)

**Test Status:** ✅ **979 tests passing** (2,486 assertions, 0 failures)

---

## Progress Summary

**Completed:**
- ✅ **Phases 1-7:** Complete blog system with RailsAdmin and automated translation
- ✅ **45 new tests:** 28 model tests + 17 controller tests, all passing
- ✅ **Full i18n support:** Mobility translations configured for all 7 languages with English fallbacks
- ✅ **SEO-optimized:** JSON-LD structured data, Open Graph, Twitter cards, microdata
- ✅ **Performance:** Eager loading to prevent N+1 queries on translations
- ✅ **Content Management:** RailsAdmin with Lexxy editor and locale switching
- ✅ **Translation Automation:** OpenRouter API script with HTML preservation and caching

**Remaining:**
- 📋 **Phase 8:** Sitemap integration
- 📋 **Phases 9-11:** Deployment documentation, testing, user guide

---

## Tech Stack

- ✅ **Lexxy** (v0.1.20.beta) - Basecamp's modern rich text editor
- ✅ **Mobility** (v1.2) - Field-level translations for models
- ✅ **Action Text** - Rails built-in rich text handling
- ✅ **Active Storage + Hetzner S3** - Already configured for image uploads
- ✅ **OpenRouter API** - Already configured for translations
- ✅ **RailsAdmin** - Already installed for admin interface

---

## Implementation Status

### ✅ Phase 1: Foundation (COMPLETED)

- [x] Add Lexxy gem to Gemfile (v0.1.20.beta)
- [x] Add Mobility gem to Gemfile (v1.2)
- [x] Add rails-controller-testing gem for controller tests
- [x] Run bundle install

### ✅ Phase 2: Setup & Configuration (COMPLETED)

- [x] Install Action Text: `rails action_text:install`
- [x] Configure Lexxy in importmap.rb
- [x] Add Lexxy CSS to application layout
- [x] Configure Mobility initializer with table backend
- [x] Set up fallbacks to English for all locales
- [x] Configure locale_accessors for all 7 languages
- [x] Run migrations for Action Text and Mobility

### ✅ Phase 3: Article Model with i18n (COMPLETED)

- [x] Generate Article model with base fields (author, published_at, featured)
- [x] Add Mobility translation tables (article_translations)
- [x] Configure translated fields (title, slug, excerpt, meta_description, meta_keywords, translation_notice)
- [x] Add Action Text rich_text content (translated)
- [x] Add validations (author, title, slug presence)
- [x] Add slug uniqueness validation per locale
- [x] Add auto-slug generation from title
- [x] Add scopes (published, featured, recent, by_locale)
- [x] Add helper methods (published?, publish!, unpublish!, reading_time)
- [x] Create comprehensive model tests (28 tests)
- [x] Create migrations and run them

### ✅ Phase 4: Routes & Controllers (COMPLETED)

- [x] Add /blog routes with locale support
- [x] Create ArticlesController with index and show actions
- [x] Eager load translations and rich_text_content to prevent N+1 queries
- [x] Handle locale switching in ApplicationController (inherited)
- [x] Add English fallback for missing translations
- [x] Flash notice when showing English fallback article
- [x] Add published scope filtering
- [x] Implement proper 404 handling for missing articles
- [x] Create comprehensive controller tests (17 tests)
- [x] Create article and article_translations fixtures

### ✅ Phase 5: Views & SEO (COMPLETED)

- [x] Create articles/index.html.erb (blog listing)
- [x] Create articles/show.html.erb (single article view)
- [x] Add JSON-LD structured data (BlogPosting schema)
- [x] Add Open Graph meta tags
- [x] Add Twitter card meta tags
- [x] Add microdata with itemscope/itemprop
- [x] Add translation notice banner component
- [x] Create ArticlesHelper with SEO methods
- [x] Implement article_structured_data helper
- [x] Implement article_meta_description helper
- [x] Implement article_meta_keywords helper
- [x] Implement article_published_date helper
- [x] Implement article_reading_time helper
- [x] Add translation keys to config/locales/en/articles.yml
- [x] Simple pagination (limit to 20 articles)

### ✅ Phase 6: RailsAdmin Integration (COMPLETED)

- [x] Configure Article model in RailsAdmin config
- [x] Set up field visibility and grouping (Base, Content, SEO)
- [x] Configure Lexxy editor for Action Text content field
- [x] Add Mobility locale switcher in edit form (via URL parameter)
- [x] Configure image upload via Active Storage (built-in)
- [x] Add helpful field descriptions and labels
- [x] Display current editing locale in form
- [x] Test article creation workflow
- [x] Add Lexxy to RailsAdmin importmap

### ✅ Phase 7: Translation Automation (COMPLETED)

- [x] Create bin/translate-articles script (246 lines)
- [x] Implement OpenRouter API integration with Google Gemini 2.0 Flash
- [x] Add HTML-aware translation (preserves all HTML tags and attributes)
- [x] Add translation cache to avoid re-translating (tmp/article_translation_cache/)
- [x] Add force-retranslate option (--force flag)
- [x] Support translating specific articles by ID
- [x] Set translation_notice flag on translated content
- [x] Use Mobility locale accessors (title_en, title_ja, etc.)
- [x] Handle Action Text content via I18n.with_locale context switching

### 📋 Phase 8: Sitemap Integration

- [ ] Update config/sitemap.rb to include articles
- [ ] Add all locale versions with proper lastmod
- [ ] Set priority to 0.8, changefreq to monthly
- [ ] Test sitemap generation

### 📋 Phase 9: Deployment Documentation

- [ ] Document production translation workflow
- [ ] Add article translation to user guide
- [ ] Create example workflow for content admins

### 📋 Phase 10: Testing

- [ ] Model tests (validations, scopes, translations)
- [ ] Controller tests (index, show, locale handling)
- [ ] System tests (navigation, translation switching)
- [ ] Translation script tests

### 📋 Phase 11: Documentation & Seeds

- [ ] Create docs/BLOG_SYSTEM.md user guide
- [ ] Add seed data for example articles
- [ ] Document translation workflow
- [ ] Document SEO best practices

---

## Article Model Structure

### Non-Translated Fields

```ruby
- id (primary key)
- author (string) - article author name
- published_at (datetime) - publication timestamp
- featured (boolean) - highlight on blog index
- created_at, updated_at (timestamps)
```

### Translated Fields (via Mobility)

```ruby
- title (string) - article title
- slug (string) - URL-friendly slug
- excerpt (text) - short summary for SEO
- meta_description (string) - SEO meta description
- meta_keywords (string) - SEO keywords
- content (ActionText::RichText) - main article body
- translation_notice (boolean) - flag for auto-translated content
```

### Supported Locales

- English (en) - Source language
- Japanese (ja)
- Chinese Simplified (zh-CN)
- Hindi (hi)
- Spanish (es)
- French (fr)
- Arabic (ar)

---

## Routes Structure

```ruby
scope "(:locale)", locale: /#{I18n.available_locales.join("|")}/ do
  get 'blog', to: 'articles#index', as: :blog
  get 'blog/:slug', to: 'articles#show', as: :article
end

# Examples:
# /blog                    (default locale: en)
# /ja/blog                 (Japanese)
# /blog/complete-guide     (English article)
# /es/blog/guia-completa   (Spanish translation)
```

---

## SEO Implementation

### Article Schema Markup

```json
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "Article Title",
  "author": {
    "@type": "Person",
    "name": "Author Name"
  },
  "datePublished": "2025-11-25",
  "dateModified": "2025-11-25",
  "image": "https://calcumake.com/featured-image.jpg",
  "publisher": {
    "@type": "Organization",
    "name": "CalcuMake",
    "logo": "https://calcumake.com/icon.png"
  },
  "inLanguage": "en",
  "description": "Article excerpt for SEO"
}
```

### Meta Tags Per Article

- Title: `<title>Article Title | CalcuMake Blog</title>`
- Description: From article.meta_description or excerpt
- Keywords: From article.meta_keywords
- OG tags: Image, title, description, type (article)
- Canonical URL: With locale support

---

## Translation Workflow

### Production Translation Process

**IMPORTANT:** Article translations must be run manually in production after creating English content. DO NOT run translations during deployment.

**Step-by-Step Workflow:**

1. **Write article in English** via RailsAdmin at `/admin/article/new`
   - Write content using Lexxy rich text editor
   - Add featured images via Action Text attachment
   - Set meta_description and meta_keywords
   - Leave published_at blank to save as draft
   - Click "Save" to create English article

2. **SSH to production server** (Kamal/Docker container)
   ```bash
   bin/kamal app exec -i --reuse "bin/rails console"
   ```

3. **Run translation script** in production Rails console:
   ```ruby
   # Translate all articles
   system("bin/translate-articles")

   # Or translate specific articles
   system("bin/translate-articles 1 2 3")

   # Force retranslate existing translations
   system("bin/translate-articles --force")
   ```

4. **Verify translations** in RailsAdmin:
   - Visit `/admin/article/1/edit?locale=ja` to check Japanese
   - Visit `/admin/article/1/edit?locale=es` to check Spanish
   - Spot-check HTML structure and technical terms

5. **Publish to all locales** when ready:
   - Set `published_at` to current time or future date
   - Article goes live in all 7 languages simultaneously

### Script Usage Examples

```bash
# Translate all articles (new translations only)
bin/translate-articles

# Translate specific articles by ID
bin/translate-articles 1 2 3

# Force retranslate existing translations
bin/translate-articles --force

# Combine options
bin/translate-articles 1 --force
```

### Translation Cache

- **Location:** `tmp/article_translation_cache/articles.json`
- **Purpose:** Avoid re-translating unchanged content
- **Behavior:** Script checks cache before calling API
- **Cache key format:** `article_{id}_{locale}_{field}` (e.g., `article_1_ja_title`)
- **Force retranslate:** Use `--force` flag to ignore cache

### Translation Notice Banner

```html
<div class="alert alert-info">
  <i class="bi bi-translate"></i>
  This article was automatically translated from English and reviewed with AI.
  <a href="/blog/article-slug?locale=en">View original</a>
</div>
```

### API Requirements

**Environment Variable:**
- `OPENROUTER_TRANSLATION_KEY` - OpenRouter API key (stored in production secrets)

**API Model:**
- Google Gemini 2.0 Flash (`google/gemini-2.0-flash-001`)
- Temperature: 0.3 (for consistency)
- Max tokens: 8000 (for large articles)

**Translation Prompt:**
- Preserves all HTML tags and attributes
- Maintains 3D printing technical terminology
- Uses professional blog tone
- Returns only translated content (no markdown code blocks)

---

## Content Strategy Integration

### SEO Strategy 2025 - Phase 2A

**Goal:** 15 blog articles in 3 months

**Month 1 Articles:**

1. The Complete Guide to 3D Printing Costs in 2025 (2,500 words)
2. How to Calculate Filament Cost Per Print (1,800 words)
3. Multi-Plate 3D Printing: Maximizing Printer Efficiency (2,000 words)
4. 3D Printing Business Pricing: How to Set Profitable Rates (2,200 words)
5. Electricity Costs for 3D Printing: The Hidden Expense (1,500 words)

### Content Creation Workflow

1. **Draft in English** - Write article using Lexxy editor at `/admin/article/new`
2. **Add media** - Upload featured image via Action Text attachment
3. **SEO metadata** - Set meta_description and meta_keywords
4. **Feature flag** - Set featured=true for important articles
5. **Save draft** - Leave published_at blank, click "Save"
6. **SSH to production** - Connect via Kamal: `bin/kamal app exec -i --reuse "bin/rails console"`
7. **Translate** - Run `bin/translate-articles` to translate to 6 languages
8. **Review** - Spot-check translations in RailsAdmin (?locale=ja, ?locale=es, etc.)
9. **Publish** - Set published_at to go live in all 7 languages
10. **Sitemap** - Auto-updates on next deployment

---

## File Structure

```
app/
  models/
    article.rb                      # Article model with Mobility
    article/
      translation.rb                # Mobility translation model
  controllers/
    articles_controller.rb          # Public blog controller
  views/
    articles/
      index.html.erb                # Blog listing page
      show.html.erb                 # Single article page
      _article_card.html.erb        # Article preview component
      _translation_notice.html.erb  # Translation banner
  helpers/
    articles_helper.rb              # Article schema markup helper
  components/
    articles/
      translation_notice_component.rb

bin/
  translate-articles                # Translation automation script

config/
  initializers/
    mobility.rb                     # Mobility configuration
  importmap.rb                      # Add Lexxy JS

db/
  migrate/
    XXXXXX_create_articles.rb
    XXXXXX_create_article_translations.rb
    XXXXXX_create_action_text_tables.rb

test/
  models/
    article_test.rb
  controllers/
    articles_controller_test.rb
  system/
    articles_test.rb

docs/
  BLOG_SYSTEM.md                    # User guide
  BLOG_IMPLEMENTATION_PLAN.md       # This file
```

---

## Testing Checklist

### Model Tests

- [ ] Validates presence of title (in current locale)
- [ ] Generates slug from title automatically
- [ ] Slug is unique per locale
- [ ] Published scope only returns published articles
- [ ] Translation fallback works correctly
- [ ] Rich text content saves/loads properly

### Controller Tests

- [ ] Index shows published articles only
- [ ] Index respects locale parameter
- [ ] Show displays article in correct locale
- [ ] Show returns 404 for missing translations
- [ ] Pagination works correctly

### System Tests

- [ ] Navigate to /blog
- [ ] Click article to view full content
- [ ] Switch language and see translated version
- [ ] Translation notice appears on translated articles
- [ ] Featured images display correctly

### Translation Tests

- [ ] bin/translate-articles translates all fields
- [ ] Action Text attachments are preserved
- [ ] HTML structure remains valid
- [ ] Translation cache prevents re-translation
- [ ] Force retranslate option works

---

## Deployment Checklist

### Pre-Deploy

- [ ] Run all tests and ensure passing
- [ ] Review article translations for quality
- [ ] Check featured images are uploaded to Hetzner S3
- [ ] Verify sitemap includes all articles

### Deploy

- [ ] Run migrations (Action Text, Mobility, Articles)
- [ ] Translation script runs in pre-build (if flag set)
- [ ] Sitemap regenerates automatically
- [ ] Assets compile including Lexxy CSS/JS

### Post-Deploy

- [ ] Test /blog on production
- [ ] Verify articles display in all locales
- [ ] Check schema.org markup with Rich Results Test
- [ ] Submit updated sitemap to Google Search Console
- [ ] Monitor for any errors in logs

---

## Performance Considerations

### Caching Strategy

- Cache article index per locale
- Cache individual articles per locale
- Expire cache on article update
- Consider fragment caching for article cards

### Database Indexing

```ruby
add_index :articles, :published_at
add_index :articles, :featured
add_index :articles, :slug
add_index :article_translations, [:article_id, :locale]
```

### N+1 Query Prevention

- Eager load translations in index
- Eager load rich_text content
- Eager load featured images

---

## Future Enhancements

### V1.1 - Categories & Tags

- [ ] Add Category model
- [ ] Add Tag model (acts_as_taggable_on)
- [ ] Filter articles by category/tag
- [ ] Category pages with SEO

### V1.2 - Related Articles

- [ ] Algorithm based on keywords/tags
- [ ] Show 3-5 related articles at bottom
- [ ] Track click-through rates

### V1.3 - Comments

- [ ] Add commenting system (or integrate Disqus)
- [ ] Moderation interface
- [ ] Email notifications

### V1.4 - Newsletter Integration

- [ ] Add email signup at bottom of articles
- [ ] Weekly digest of new articles
- [ ] Integration with email service

### V1.5 - Analytics

- [ ] Track article views
- [ ] Track reading time
- [ ] Most popular articles widget
- [ ] A/B test headlines

---

## Success Metrics

### SEO Goals (from SEO Strategy 2025)

- **Month 1:** 5 articles published, 500 organic visitors
- **Month 3:** 15 articles published, 2,500 organic visitors
- **Month 6:** 30 articles published, 10,000 organic visitors

### Translation Goals

- All articles available in 7 languages
- Translation turnaround time: < 5 minutes per article
- Translation quality: Manual spot-check passing rate > 90%

### Engagement Goals

- Average time on page: > 3 minutes
- Bounce rate: < 60%
- Internal link click rate: > 15%

---

## Resources

### Documentation

- Lexxy GitHub: https://github.com/basecamp/lexxy
- Mobility Gem: https://github.com/shioyama/mobility
- Action Text Guide: https://guides.rubyonrails.org/action_text_overview.html
- Schema.org Article: https://schema.org/Article

### Related Docs

- SEO Strategy 2025: docs/SEO_STRATEGY_2025.md
- SEO Implementation Session: docs/SEO_IMPLEMENTATION_SESSION_2025-11-24.md
- Translation System: docs/AUTOMATED_TRANSLATION_SYSTEM.md

---

## Questions & Decisions

### Decisions Made

- ✅ Use Lexxy instead of Trix (modern, better UX)
- ✅ Use Mobility instead of built-in i18n (better for rich text)
- ✅ Use table backend for Mobility (better performance than jsonb)
- ✅ Auto-translate with notice rather than manual-only
- ✅ Integrate with existing RailsAdmin

### Open Questions

- [ ] Should we version article content for revision history?
- [ ] Do we need article drafts, or just unpublished articles?
- [ ] Should translation be sync or async (background job)?
- [ ] Do we need article series/multi-part articles?

---

**Last Updated:** 2025-11-25  
**Status:** Phase 1 Complete, Phase 2 In Progress  
**Next Steps:** Install Action Text, configure Lexxy, create Article model
