SitemapGenerator::Sitemap.default_host = "https://calcumake.com"
SitemapGenerator::Sitemap.create_index = true
SitemapGenerator::Sitemap.compress = false

SitemapGenerator::Sitemap.create do
  add root_path, priority: 1.0, changefreq: "daily"

  # Public tools - high value for SEO and lead generation
  add pricing_calculator_path, priority: 1.0, changefreq: "weekly"
  add landing_path, priority: 1.0, changefreq: "weekly"
  add commerce_disclosure_path, priority: 0.6, changefreq: "yearly"

  add new_user_session_path, priority: 0.8, changefreq: "monthly"
  add new_user_registration_path, priority: 0.8, changefreq: "monthly"

  add support_path, priority: 0.9, changefreq: "monthly"
  add privacy_policy_path, priority: 0.7, changefreq: "yearly"
  add user_agreement_path, priority: 0.7, changefreq: "yearly"
end
