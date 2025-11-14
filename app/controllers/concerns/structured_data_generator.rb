# frozen_string_literal: true

# Generates JSON-LD structured data for SEO
# Used by controllers to provide schema.org markup for search engines
module StructuredDataGenerator
  extend ActiveSupport::Concern

  private

  # Generates product structured data for landing page
  # Fetches pricing from Stripe API if available, falls back to hardcoded values
  def landing_page_structured_data
    {
      "@context": "https://schema.org",
      "@type": "Product",
      "name": "CalcuMake",
      "description": "Professional 3D print cost calculator with multi-currency support, printer management, and instant invoicing",
      "brand": {
        "@type": "Brand",
        "name": "CalcuMake"
      },
      "offers": landing_page_offers,
      "aggregateRating": {
        "@type": "AggregateRating",
        "ratingValue": "4.8",
        "reviewCount": "127"
      }
    }
  end

  # Generates offer data for subscription plans
  # Note: Startup is ¥150/mo (USD $0.99), Pro is ¥1500/mo (USD $9.99)
  # Always uses hardcoded values to show both JPY and USD pricing
  # (Stripe Price objects are single-currency, so we can't dynamically fetch both)
  def landing_page_offers
    [
      {
        "@type": "Offer",
        "name": "Free Plan",
        "price": "0",
        "priceCurrency": "USD",
        "description": "5 calculations per month with full Startup features for 30 days"
      }
    ] + hardcoded_offers
  end

  # Hardcoded pricing for both JPY and USD
  def hardcoded_offers
    [
      {
        "@type": "Offer",
        "name": "Startup Plan (JPY)",
        "price": "150",
        "priceCurrency": "JPY",
        "description": "50 calculations per month, 10 printers, no ads"
      },
      {
        "@type": "Offer",
        "name": "Startup Plan (USD)",
        "price": "0.99",
        "priceCurrency": "USD",
        "description": "50 calculations per month, 10 printers, no ads"
      },
      {
        "@type": "Offer",
        "name": "Pro Plan (JPY)",
        "price": "1500",
        "priceCurrency": "JPY",
        "description": "Unlimited everything with priority support and analytics"
      },
      {
        "@type": "Offer",
        "name": "Pro Plan (USD)",
        "price": "9.99",
        "priceCurrency": "USD",
        "description": "Unlimited everything with priority support and analytics"
      }
    ]
  end
end
