# CalcuMake Blog System - User Guide

**Version:** 1.0
**Last Updated:** November 25, 2025

---

## Table of Contents

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Creating Your First Article](#creating-your-first-article)
4. [Translation System](#translation-system)
5. [Publishing Workflow](#publishing-workflow)
6. [SEO Optimization](#seo-optimization)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

---

## Overview

The CalcuMake blog system is a production-ready, multilingual blogging platform built for SEO excellence. It supports 7 languages with automated translation, modern rich text editing, and comprehensive SEO optimization.

### Key Features

- **7 Languages:** English, Japanese, Spanish, French, Arabic, Hindi, Simplified Chinese
- **Automated Translation:** OpenRouter API with Google Gemini 2.0 Flash
- **Modern Editor:** Lexxy rich text editor from Basecamp
- **SEO Optimized:** Structured data, Open Graph, Twitter cards, multilingual sitemap
- **Admin Interface:** RailsAdmin with locale switching
- **Performance:** Eager loading, N+1 query prevention

### Supported Languages

| Code | Language | Native Name |
|------|----------|-------------|
| `en` | English | English |
| `ja` | Japanese | 日本語 |
| `es` | Spanish | Español |
| `fr` | French | Français |
| `ar` | Arabic | العربية |
| `hi` | Hindi | हिन्दी |
| `zh-CN` | Chinese | 中文 (简体) |

---

## Quick Start

### Access the Admin Interface

1. **Log in** as admin at `/admin` (requires admin privileges)
2. **Navigate** to "Content" → "Articles" in the sidebar
3. **Create** a new article by clicking "Add New"

### URLs

- **Admin Panel:** `https://calcumake.com/admin`
- **Blog Index:** `https://calcumake.com/blog`
- **Japanese Blog:** `https://calcumake.com/ja/blog`
- **Article:** `https://calcumake.com/blog/article-slug`

---

## Creating Your First Article

### Step 1: Draft in English

1. Navigate to `/admin/article/new`
2. Fill in the **Article Details** section:
   - **Author:** Your name (e.g., "CalcuMake Team")
   - **Published At:** Leave blank for draft
   - **Featured:** Check if this should appear on homepage

### Step 2: Add Content

1. **Title:** Write a clear, SEO-friendly title
   - Good: "The Complete Guide to 3D Printing Costs in 2025"
   - Bad: "Costs"

2. **Slug:** Auto-generated from title, or customize
   - Auto: "the-complete-guide-to-3d-printing-costs-in-2025"
   - Custom: "3d-printing-costs-guide"

3. **Excerpt:** Short summary for article listings (optional)
   - Keep it under 200 characters
   - Used in meta descriptions if meta_description is blank

4. **Content:** Write your article using Lexxy editor
   - Use headings (H2, H3) for structure
   - Add images via drag-and-drop
   - Format text with bold, italic, lists
   - Embed links to other articles

### Step 3: SEO Metadata

1. **Meta Description:** Custom description for search engines
   - 150-160 characters optimal
   - Include target keyword
   - Falls back to excerpt if blank

2. **Meta Keywords:** Comma-separated keywords (optional)
   - "3d printing, costs, pricing, business"

3. **Translation Notice:** Auto-checked for translated content
   - Shows banner: "This article was auto-translated from English"

### Step 4: Save Draft

Click **Save** to create the article. It won't be visible publicly until you set `published_at`.

---

## Translation System

### Automated Translation Workflow

**IMPORTANT:** Translations must be run manually in production. Do NOT run during deployment.

### Step-by-Step Translation

#### 1. SSH to Production Server

```bash
bin/kamal app exec -i --reuse "bin/rails console"
```

#### 2. Run Translation Script

**Translate all articles:**
```bash
bin/translate-articles
```

**Translate specific articles by ID:**
```bash
bin/translate-articles 1 2 3
```

**Force retranslate existing translations:**
```bash
bin/translate-articles --force
```

**Combine options:**
```bash
bin/translate-articles 5 --force
```

#### 3. Monitor Progress

The script shows real-time progress:
```
1/1 - Article #5: "Complete Guide to 3D Printing Costs"
  📝 Translating to Japanese...
     🌐 Translating title...
     🌐 Translating excerpt...
     🌐 Translating content (HTML-aware)...
     🌐 Translating meta description...
     ✅ Saved Japanese translation
```

#### 4. Verify Translations

1. Visit `/admin/article/5/edit?locale=ja` to check Japanese
2. Visit `/admin/article/5/edit?locale=es` to check Spanish
3. Spot-check HTML structure and technical terms
4. Review Action Text content rendering

### Translation Cache

**Location:** `tmp/article_translation_cache/articles.json`

**How it works:**
- Script checks cache before calling API
- Saves API costs for unchanged content
- Cache key format: `article_{id}_{locale}_{field}`

**Clear cache:**
```bash
rm tmp/article_translation_cache/articles.json
```

**Force retranslate without clearing cache:**
```bash
bin/translate-articles --force
```

### What Gets Translated

✅ **Title** - Article headline
✅ **Slug** - Auto-generated from translated title
✅ **Excerpt** - Short summary
✅ **Content** - Full article body (HTML-aware)
✅ **Meta Description** - SEO description
❌ **Author** - Not translated (stays in English)
❌ **Meta Keywords** - Not translated
❌ **Published At** - Shared across all locales
❌ **Featured Flag** - Shared across all locales

### HTML Preservation

The translation system preserves:
- All HTML tags (`<p>`, `<h2>`, `<div>`, etc.)
- All attributes (`class`, `id`, `data-*`)
- Action Text attachments (images, embeds)
- Link structures
- Formatting (bold, italic, lists)

---

## Publishing Workflow

### Complete Publishing Process

#### 1. Create Draft in English
- Write article at `/admin/article/new`
- Add images and format content
- Set SEO metadata
- Save without `published_at`

#### 2. Review and Edit
- Proofread content
- Check image alt text
- Verify links work
- Preview formatting

#### 3. Translate to All Languages
- SSH to production
- Run `bin/translate-articles`
- Wait for completion (typically 1-2 minutes per article)

#### 4. Verify Translations
- Spot-check 2-3 languages
- Verify technical terms are correct
- Check HTML rendering
- Review translation notice banner

#### 5. Publish to All Locales
- Set `published_at` to current time (or future date for scheduling)
- Click **Save**
- Article goes live in all 7 languages simultaneously

#### 6. Verify Live Site
- Visit `/blog/article-slug` to see English version
- Visit `/ja/blog/article-slug` to see Japanese version
- Check meta tags in browser inspector
- Verify sitemap includes new article

### Scheduling Articles

Set `published_at` to a future date to schedule publication:

**Example:** Schedule for December 1, 2025 at 9:00 AM JST
```
2025-12-01 09:00:00 +0900
```

The article will automatically appear at that time.

### Unpublishing Articles

To unpublish an article:
1. Edit the article in RailsAdmin
2. Clear the `published_at` field
3. Save

The article immediately becomes unavailable on the public site.

---

## SEO Optimization

### Built-in SEO Features

The blog system automatically generates:

#### 1. JSON-LD Structured Data
```json
{
  "@context": "https://schema.org",
  "@type": "BlogPosting",
  "headline": "Article Title",
  "author": {
    "@type": "Person",
    "name": "CalcuMake Team"
  },
  "datePublished": "2025-11-25",
  "dateModified": "2025-11-25",
  "image": "https://calcumake.com/featured-image.jpg",
  "publisher": {
    "@type": "Organization",
    "name": "CalcuMake"
  },
  "inLanguage": "en"
}
```

#### 2. Open Graph Tags
- `og:title` - Article title
- `og:description` - Meta description or excerpt
- `og:image` - Featured image from Action Text
- `og:type` - "article"
- `og:url` - Canonical URL with locale

#### 3. Twitter Cards
- `twitter:card` - "summary_large_image"
- `twitter:title` - Article title
- `twitter:description` - Meta description
- `twitter:image` - Featured image

#### 4. Multilingual Sitemap
- All 7 blog index pages
- All articles in all 7 languages
- Proper `lastmod` timestamps
- Priority: 0.9 for blog, 0.8 for articles
- Changefreq: weekly for blog, monthly for articles

### SEO Best Practices

#### Title Optimization
- **Length:** 50-60 characters optimal
- **Format:** "Topic | CalcuMake Blog"
- **Keywords:** Include target keyword early
- **Compelling:** Make it click-worthy

**Examples:**
- ✅ "3D Printing Cost Calculator: Complete 2025 Guide"
- ❌ "Costs"

#### Meta Description
- **Length:** 150-160 characters
- **Keywords:** Include 1-2 target keywords
- **CTA:** End with call-to-action
- **Unique:** Different for each article

**Examples:**
- ✅ "Learn how to calculate 3D printing costs accurately. Our complete guide covers filament, electricity, labor, and hidden expenses. Free calculator included."
- ❌ "Article about costs"

#### Content Structure
- **H1:** One per page (automatically the title)
- **H2:** Main sections (5-7 per article)
- **H3:** Subsections under H2
- **Paragraphs:** Keep under 3-4 sentences
- **Lists:** Use bullet points and numbered lists
- **Images:** Include alt text with keywords

#### Internal Linking
- Link to 3-5 related articles
- Use descriptive anchor text
- Link to calculator: `/3d-print-pricing-calculator`
- Link to landing page: `/landing`

#### Image Optimization
- **Format:** WebP or JPEG
- **Size:** Under 200KB per image
- **Alt text:** Descriptive with keywords
- **Filename:** descriptive-with-keywords.jpg

---

## Troubleshooting

### Translation Issues

**Problem:** Translation script fails with API error

**Solution:**
1. Check `OPENROUTER_TRANSLATION_KEY` is set
2. Verify API credits are available
3. Check internet connectivity
4. Review error message for specifics

---

**Problem:** Translations missing for some fields

**Solution:**
1. Run with `--force` flag: `bin/translate-articles 1 --force`
2. Clear translation cache if corrupted
3. Check English content exists before translating

---

**Problem:** HTML tags appear in translated content

**Solution:**
- This is normal - the system preserves HTML
- Check if `is_html: true` is set for content field
- Verify the translation prompt includes HTML preservation rules

---

### Content Issues

**Problem:** Article not appearing on blog index

**Solution:**
1. Check `published_at` is set to past date
2. Verify article has published status
3. Clear cache: `bin/rails tmp:cache:clear`
4. Check locale matches URL

---

**Problem:** Slug already exists error

**Solution:**
1. Slugs must be unique per locale
2. Customize slug manually in admin
3. Check for similar articles in database

---

**Problem:** Images not displaying

**Solution:**
1. Verify Active Storage is configured
2. Check Hetzner S3 connection
3. Ensure image was uploaded successfully
4. Review Action Text attachments

---

### Performance Issues

**Problem:** Blog index loads slowly

**Solution:**
1. Check N+1 queries in logs
2. Verify eager loading is active
3. Enable fragment caching if not already
4. Consider pagination beyond 20 articles

---

**Problem:** Translation script takes too long

**Solution:**
1. Translate specific articles: `bin/translate-articles 1 2 3`
2. Check API response times
3. Verify network connection
4. Consider running during off-peak hours

---

## Best Practices

### Content Strategy

#### Article Length
- **Pillar content:** 2,000-2,500 words
- **How-to guides:** 1,500-2,000 words
- **Quick tips:** 800-1,200 words
- **News/updates:** 500-800 words

#### Publishing Frequency
- **Ideal:** 1-2 articles per week
- **Minimum:** 1 article per week
- **Maximum:** 3 articles per week (quality over quantity)

#### Content Mix
- 40% Educational (how-to guides)
- 30% Informational (industry insights)
- 20% Product-related (calculator features)
- 10% News/updates (announcements)

### Translation Quality

#### Review Priority
1. **High priority:** Title, excerpt, meta description
2. **Medium priority:** First paragraph, headings
3. **Low priority:** Body content (spot-check only)

#### Common Issues to Check
- Technical terms (3D printing, filament, etc.)
- Brand names (CalcuMake, Hetzner, etc.)
- UI terms (calculator, pricing, etc.)
- Numbers and units (¥, kg, hours)

### SEO Maintenance

#### Monthly Tasks
- Review Google Search Console performance
- Check for crawl errors
- Update underperforming articles
- Add internal links to new content
- Verify sitemap is current

#### Quarterly Tasks
- Audit all articles for freshness
- Update statistics and dates
- Refresh images if outdated
- Review and update meta descriptions
- Analyze top-performing content

### Performance Optimization

#### Image Guidelines
- Use WebP format when possible
- Compress images to under 200KB
- Set proper dimensions (max 1200px width)
- Include descriptive alt text
- Use lazy loading (automatic)

#### Database Optimization
- Monitor query performance in logs
- Add indexes if needed for custom queries
- Clean up old draft articles periodically
- Vacuum database monthly

---

## Advanced Features

### Custom Slugs

To customize slugs per locale:

1. Edit article in English: `/admin/article/1/edit`
2. Set custom slug: `3d-printing-guide`
3. Switch to Japanese: `/admin/article/1/edit?locale=ja`
4. Set custom slug: `3d-purintingu-gaido`
5. Repeat for other locales

### Featured Articles

Featured articles appear:
- At the top of blog index
- In special "Featured" section
- With visual indicators

To feature an article:
1. Edit article in admin
2. Check "Featured" checkbox
3. Save

### Translation Notice

The translation notice banner shows:
```
ℹ️ This article was automatically translated from English and reviewed with AI.
View original
```

To hide on specific articles:
1. Edit article in admin
2. Uncheck "Translation Notice"
3. Save

---

## Support and Resources

### Documentation
- **Implementation Plan:** `docs/BLOG_IMPLEMENTATION_PLAN.md`
- **Translation System:** `docs/AUTOMATED_TRANSLATION_SYSTEM.md`
- **SEO Strategy:** `docs/SEO_STRATEGY_2025.md`

### Code Files
- **Article Model:** `app/models/article.rb`
- **Articles Controller:** `app/controllers/articles_controller.rb`
- **Translation Script:** `bin/translate-articles`
- **RailsAdmin Config:** `config/initializers/rails_admin.rb`
- **Sitemap:** `config/sitemap.rb`

### Tests
- **Model Tests:** `test/models/article_test.rb` (28 tests)
- **Controller Tests:** `test/controllers/articles_controller_test.rb` (17 tests)

### External Resources
- **Lexxy Editor:** https://github.com/basecamp/lexxy
- **Mobility Gem:** https://github.com/shioyama/mobility
- **OpenRouter API:** https://openrouter.ai/docs
- **Schema.org Article:** https://schema.org/Article

---

## Quick Reference

### Common Commands

```bash
# Create new article (via admin UI)
https://calcumake.com/admin/article/new

# Translate all articles
bin/translate-articles

# Translate specific articles
bin/translate-articles 1 2 3

# Force retranslate
bin/translate-articles --force

# Regenerate sitemap
bin/rails sitemap:refresh

# Clear cache
bin/rails tmp:cache:clear

# Run tests
bin/rails test test/models/article_test.rb
bin/rails test test/controllers/articles_controller_test.rb
```

### Locale Codes

```ruby
:en      # English (default)
:ja      # Japanese
:es      # Spanish
:fr      # French
:ar      # Arabic
:hi      # Hindi
:"zh-CN" # Simplified Chinese
```

### URL Patterns

```
/blog                    # English blog index
/ja/blog                 # Japanese blog index
/blog/article-slug       # English article
/es/blog/articulo-slug   # Spanish article
/admin/article/new       # Create article
/admin/article/1/edit?locale=ja  # Edit Japanese translation
```

---

**Version:** 1.0
**Last Updated:** November 25, 2025
**Questions?** Contact the development team or refer to the implementation plan.
