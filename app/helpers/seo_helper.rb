module SeoHelper
  def meta_title(title = nil)
    content_for(:title, title) if title
    content_for(:title) || "CalcuMake - 3D Print Cost Calculator & Project Management"
  end

  def meta_description(description = nil)
    content_for(:meta_description, description) if description
    content_for(:meta_description) || "Free 3D printing cost calculator with comprehensive project management. Calculate filament costs, electricity, labor, and pricing for your 3D print jobs. Multi-currency support."
  end

  def meta_keywords(keywords = nil)
    content_for(:meta_keywords, keywords) if keywords
    content_for(:meta_keywords) || "3d printing calculator, 3d print cost calculator, filament cost calculator, 3d printing pricing, print job calculator, 3d printer cost estimation"
  end

  def meta_image(image_url = nil)
    content_for(:meta_image, image_url) if image_url
    content_for(:meta_image) || image_url("/icon.png")
  end

  def canonical_url(url = nil)
    content_for(:canonical_url, url) if url
    content_for(:canonical_url) || request.original_url.split("?").first
  end

  def meta_tags
    tag.meta(name: "description", content: meta_description) +
    tag.meta(name: "keywords", content: meta_keywords) +
    tag.link(rel: "canonical", href: canonical_url) +
    og_meta_tags +
    twitter_meta_tags
  end

  def og_meta_tags
    tag.meta(property: "og:title", content: meta_title) +
    tag.meta(property: "og:description", content: meta_description) +
    tag.meta(property: "og:image", content: meta_image) +
    tag.meta(property: "og:url", content: canonical_url) +
    tag.meta(property: "og:type", content: "website") +
    tag.meta(property: "og:site_name", content: "CalcuMake")
  end

  def twitter_meta_tags
    tag.meta(name: "twitter:card", content: "summary_large_image") +
    tag.meta(name: "twitter:title", content: meta_title) +
    tag.meta(name: "twitter:description", content: meta_description) +
    tag.meta(name: "twitter:image", content: meta_image)
  end

  def structured_data_organization
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      "name": "CalcuMake",
      "url": root_url,
      "logo": image_url("/icon.png"),
      "description": "3D printing cost calculator and project management software",
      "sameAs": []
    }.to_json
  end

  def structured_data_web_application
    {
      "@context": "https://schema.org",
      "@type": "WebApplication",
      "name": "CalcuMake",
      "url": root_url,
      "applicationCategory": "BusinessApplication",
      "operatingSystem": "Web",
      "image": image_url("/icon.png"),
      "offers": {
        "@type": "Offer",
        "price": "0",
        "priceCurrency": "USD",
        "availability": "https://schema.org/InStock",
        "url": root_url,
        "image": image_url("/icon.png"),
        "priceValidUntil": (Date.current + 1.year).iso8601,
        "hasMerchantReturnPolicy": {
          "@type": "MerchantReturnPolicy",
          "returnPolicyCategory": "https://schema.org/MerchantReturnNotPermitted",
          "applicableCountry": "US",
          "description": "Digital products are non-refundable. Free version requires no payment."
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
      },
      "description": "Free 3D printing cost calculator with comprehensive project management features including filament cost calculation, electricity costs, labor tracking, and multi-currency support.",
      "featureList": [
        "3D print cost calculation",
        "Filament cost tracking",
        "Electricity cost calculation",
        "Labor cost estimation",
        "Multi-currency support",
        "Printer management",
        "Project invoicing"
      ]
    }.to_json
  end

  def structured_data_calculator
    {
      "@context": "https://schema.org",
      "@type": "SoftwareApplication",
      "name": "3D Print Cost Calculator",
      "applicationCategory": "CalculatorApplication",
      "operatingSystem": "Web",
      "image": image_url("/icon.png"),
      "screenshot": image_url("/icon.png"),
      "url": root_url,
      "offers": {
        "@type": "Offer",
        "price": "0",
        "priceCurrency": "USD",
        "availability": "https://schema.org/InStock",
        "url": root_url,
        "image": image_url("/icon.png"),
        "priceValidUntil": (Date.current + 1.year).iso8601,
        "hasMerchantReturnPolicy": {
          "@type": "MerchantReturnPolicy",
          "returnPolicyCategory": "https://schema.org/MerchantReturnNotPermitted",
          "applicableCountry": "US",
          "description": "Digital calculator is free to use. No refunds applicable."
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
      },
      "description": "Calculate accurate 3D printing costs including filament, electricity, labor, and machine upkeep. Supports multiple currencies and custom pricing."
    }.to_json
  end

  def structured_data_faq
    {
      "@context": "https://schema.org",
      "@type": "FAQPage",
      "mainEntity": [
        {
          "@type": "Question",
          "name": "How do I calculate 3D printing costs?",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "CalcuMake calculates 3D printing costs by combining filament costs (based on weight and spool price), electricity costs (power consumption × print time × energy rate), labor costs (prep and post-processing time), and machine upkeep costs (depreciation and repairs)."
          }
        },
        {
          "@type": "Question",
          "name": "What currencies does CalcuMake support?",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "CalcuMake supports USD, EUR, GBP, JPY, CAD, and AUD with automatic formatting and precision for each currency."
          }
        },
        {
          "@type": "Question",
          "name": "Can I track multiple 3D printers?",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "Yes, CalcuMake allows you to manage multiple printers with individual power consumption, purchase costs, and payoff tracking for each printer."
          }
        },
        {
          "@type": "Question",
          "name": "Does CalcuMake include electricity costs?",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "Yes, CalcuMake automatically calculates electricity costs based on your printer's power consumption, print duration, and your local energy rate per kWh."
          }
        },
        {
          "@type": "Question",
          "name": "Is CalcuMake free to use?",
          "acceptedAnswer": {
            "@type": "Answer",
            "text": "Yes, CalcuMake is completely free to use with all features including cost calculation, printer management, and project invoicing."
          }
        }
      ]
    }.to_json
  end

  def breadcrumb_structured_data(items)
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      "itemListElement": items.each_with_index.map do |item, index|
        {
          "@type": "ListItem",
          "position": index + 1,
          "name": item[:name],
          "item": item[:url]
        }
      end
    }.to_json
  end
end
