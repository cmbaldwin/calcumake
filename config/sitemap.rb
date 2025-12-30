SitemapGenerator::Sitemap.default_host = "https://calcumake.com"
SitemapGenerator::Sitemap.create_index = false  # No index needed for small sites (<50k URLs)
SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.create do
  # Note: sitemap_generator automatically adds root_path, so we don't need to add it explicitly

  # Public tools - high value for SEO and lead generation
  add pricing_calculator_path, priority: 1.0, changefreq: "weekly"
  # Note: /landing is NOT included - root_path already points to the landing page
  # Including both creates duplicate content issues in Google Search Console
  add commerce_disclosure_path, priority: 0.6, changefreq: "yearly"

  # Note: Auth pages (sign_in, sign_up) are NOT included - they're blocked by robots.txt
  # Including blocked pages in sitemap sends contradictory signals to crawlers

  add support_path, priority: 0.9, changefreq: "monthly"
  add privacy_policy_path, priority: 0.7, changefreq: "yearly"
  add user_agreement_path, priority: 0.7, changefreq: "yearly"

  # Blog index pages - add English explicitly, then loop for other locales
  add blog_path, priority: 0.9, changefreq: "weekly"  # English /blog

  # Blog articles - multilingual with all 7 locales
  # Priority: 0.9 for blog index, 0.8 for individual articles
  # Changefreq: weekly for index, monthly for articles
  I18n.available_locales.each do |locale|
    # Blog index for non-English locales
    unless locale == :en
      add blog_path(locale: locale),
          priority: 0.9,
          changefreq: "weekly"
    end

    # Individual articles in each locale
    Article.published.includes(:translations).find_each do |article|
      # Get the translation for this locale (falls back to English if missing)
      I18n.with_locale(locale) do
        next unless article.slug.present?

        add article_path(slug: article.slug, locale: locale == :en ? nil : locale),
            priority: 0.8,
            changefreq: "monthly",
            lastmod: article.updated_at
      end
    end
  end
end
