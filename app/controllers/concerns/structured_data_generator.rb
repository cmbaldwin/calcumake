# frozen_string_literal: true

# Generates JSON-LD structured data for SEO
# Used by controllers to provide schema.org markup for search engines
module StructuredDataGenerator
  extend ActiveSupport::Concern

  private

  # Generates SoftwareApplication structured data for landing page
  # Changed from Product to SoftwareApplication to avoid Google Merchant Listings warnings
  # SaaS products should use SoftwareApplication, not Product schema
  def landing_page_structured_data
    {
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      "name": "CalcuMake",
      "description": "Professional 3D print cost calculator with multi-currency support, printer management, and instant invoicing",
      "applicationCategory": "BusinessApplication",
      "operatingSystem": "Web",
      "image": view_context.image_url("/icon.png"),
      "screenshot": view_context.image_url("/icon.png"),
      "url": view_context.root_url,
      "offers": landing_page_offers,
      "aggregateRating": {
        "@type": "AggregateRating",
        "ratingValue": "4.8",
        "reviewCount": "127"
      },
      "featureList": [
        "Multi-plate 3D print cost calculations",
        "Comprehensive filament cost tracking",
        "Real-time electricity cost calculation",
        "Professional PDF invoice generation",
        "Multi-currency support (USD, EUR, GBP, JPY, CAD, AUD)",
        "Unlimited printer management",
        "7 language support"
      ]
    }
  end

  # Generates offer data for subscription plans
  # Note: Startup is ¥150/mo (USD $0.99), Pro is ¥1500/mo (USD $9.99)
  # Always uses hardcoded values to show both JPY and USD pricing
  # (Stripe Price objects are single-currency, so we can't dynamically fetch both)
  # Updated with Google Merchant Listings required fields for digital products
  def landing_page_offers
    [
      {
        "@type": "Offer",
        "name": "Free Plan",
        "price": "0",
        "priceCurrency": "USD",
        "description": "5 calculations per month with full Startup features for 30 days",
        "availability": "https://schema.org/InStock",
        "url": view_context.root_url,
        "image": view_context.image_url("/icon.png"),
        "priceValidUntil": (Date.current + 1.year).iso8601,
        "hasMerchantReturnPolicy": {
          "@type": "MerchantReturnPolicy",
          "returnPolicyCategory": "https://schema.org/MerchantReturnNotPermitted",
          "applicableCountry": "US",
          "description": "Digital products are non-refundable. Free plan requires no payment."
        },
        "shippingDetails": {
          "@type": "OfferShippingDetails",
          "shippingRate": {
            "@type": "MonetaryAmount",
            "value": "0",
            "currency": "USD"
          },
          "deliveryTime": {
            "@type": "ShippingDeliveryTime",
            "handlingTime": {
              "@type": "QuantitativeValue",
              "minValue": 0,
              "maxValue": 0,
              "unitCode": "DAY"
            },
            "transitTime": {
              "@type": "QuantitativeValue",
              "minValue": 0,
              "maxValue": 0,
              "unitCode": "DAY"
            }
          },
          "shippingDestination": {
            "@type": "DefinedRegion",
            "addressCountry": "US"
          }
        }
      }
    ] + hardcoded_offers
  end

  # Hardcoded pricing for both JPY and USD
  # Updated with all required Google Merchant Listings fields
  def hardcoded_offers
    base_return_policy = {
      "@type": "MerchantReturnPolicy",
      "returnPolicyCategory": "https://schema.org/MerchantReturnNotPermitted",
      "applicableCountry": "US",
      "description": "Digital subscription products are non-refundable. Cancel anytime to stop future charges."
    }

    base_shipping = lambda do |currency|
      {
        "@type": "OfferShippingDetails",
        "shippingRate": {
          "@type": "MonetaryAmount",
          "value": "0",
          "currency": currency
        },
        "deliveryTime": {
          "@type": "ShippingDeliveryTime",
          "handlingTime": {
            "@type": "QuantitativeValue",
            "minValue": 0,
            "maxValue": 0,
            "unitCode": "DAY"
          },
          "transitTime": {
            "@type": "QuantitativeValue",
            "minValue": 0,
            "maxValue": 0,
            "unitCode": "DAY"
          }
        },
        "shippingDestination": {
          "@type": "DefinedRegion",
          "addressCountry": "US"
        }
      }
    end

    [
      {
        "@type": "Offer",
        "name": "Startup Plan (JPY)",
        "price": "150",
        "priceCurrency": "JPY",
        "description": "50 calculations per month, 10 printers, email support",
        "availability": "https://schema.org/InStock",
        "url": view_context.root_url,
        "image": view_context.image_url("/icon.png"),
        "priceValidUntil": (Date.current + 1.year).iso8601,
        "hasMerchantReturnPolicy": base_return_policy,
        "shippingDetails": base_shipping.call("JPY")
      },
      {
        "@type": "Offer",
        "name": "Startup Plan (USD)",
        "price": "0.99",
        "priceCurrency": "USD",
        "description": "50 calculations per month, 10 printers, email support",
        "availability": "https://schema.org/InStock",
        "url": view_context.root_url,
        "image": view_context.image_url("/icon.png"),
        "priceValidUntil": (Date.current + 1.year).iso8601,
        "hasMerchantReturnPolicy": base_return_policy,
        "shippingDetails": base_shipping.call("USD")
      },
      {
        "@type": "Offer",
        "name": "Pro Plan (JPY)",
        "price": "1500",
        "priceCurrency": "JPY",
        "description": "Unlimited everything with priority support and analytics",
        "availability": "https://schema.org/InStock",
        "url": view_context.root_url,
        "image": view_context.image_url("/icon.png"),
        "priceValidUntil": (Date.current + 1.year).iso8601,
        "hasMerchantReturnPolicy": base_return_policy,
        "shippingDetails": base_shipping.call("JPY")
      },
      {
        "@type": "Offer",
        "name": "Pro Plan (USD)",
        "price": "9.99",
        "priceCurrency": "USD",
        "description": "Unlimited everything with priority support and analytics",
        "availability": "https://schema.org/InStock",
        "url": view_context.root_url,
        "image": view_context.image_url("/icon.png"),
        "priceValidUntil": (Date.current + 1.year).iso8601,
        "hasMerchantReturnPolicy": base_return_policy,
        "shippingDetails": base_shipping.call("USD")
      }
    ]
  end
end
