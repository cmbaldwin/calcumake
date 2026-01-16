SitemapGenerator::Sitemap.default_host = "https://calcumake.com"
SitemapGenerator::Sitemap.create_index = true
SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.create do
  add root_path, priority: 1.0, changefreq: "daily"

  add new_user_session_path, priority: 0.8, changefreq: "monthly"
  add new_user_registration_path, priority: 0.8, changefreq: "monthly"

  # Markdown directory (for AI crawlers)
  add markdown_index_path(format: :md), priority: 0.9, changefreq: "weekly"

  # About page (HTML and Markdown)
  add about_path, priority: 0.9, changefreq: "monthly"
  add about_path(format: :md), priority: 0.85, changefreq: "monthly"

  # Support page (HTML and Markdown)
  add support_path, priority: 0.9, changefreq: "monthly"
  add support_path(format: :md), priority: 0.85, changefreq: "monthly"

  # Legal pages (HTML and Markdown)
  add privacy_policy_path, priority: 0.7, changefreq: "yearly"
  add privacy_policy_path(format: :md), priority: 0.65, changefreq: "yearly"

  add user_agreement_path, priority: 0.7, changefreq: "yearly"
  add user_agreement_path(format: :md), priority: 0.65, changefreq: "yearly"
end
