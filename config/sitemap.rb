SitemapGenerator::Sitemap.default_host = "https://calcumake.com"
SitemapGenerator::Sitemap.create_index = true
SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.create do
  add root_path, priority: 1.0, changefreq: "daily"

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

  # Blog articles - multilingual with all 7 locales
  # Priority: 0.9 for blog index, 0.8 for individual articles
  # Changefreq: weekly for index, monthly for articles
  I18n.available_locales.each do |locale|
    # Blog index in each locale
    add blog_path(locale: locale == :en ? nil : locale),
        priority: 0.9,
        changefreq: "weekly"

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
