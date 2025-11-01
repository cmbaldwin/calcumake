require 'ostruct'

class PagesController < ApplicationController
  # Note: Public pages don't require authentication in this app

  def landing
    # Redirect authenticated users to the main app
    redirect_to print_pricings_path if user_signed_in?

    # Set SEO data for landing page
    @page_title = "CalcuMake - 3D Print Cost Calculator & Project Management"
    @meta_description = "Make 3D printing profitable with accurate cost calculations. Multi-currency support, printer management, and instant invoicing. Start free - no credit card required."
    @meta_keywords = "3d print cost calculator, 3d printing calculator, filament cost calculator, 3d printer cost estimation, 3d printing pricing"

    # Landing page specific structured data
    @structured_data = {
      "@context": "https://schema.org",
      "@type": "Product",
      "name": "CalcuMake",
      "description": "Professional 3D print cost calculator with multi-currency support, printer management, and instant invoicing",
      "brand": {
        "@type": "Brand",
        "name": "CalcuMake"
      },
      "offers": [
        {
          "@type": "Offer",
          "name": "Free Plan",
          "price": "0",
          "priceCurrency": "USD",
          "description": "5 calculations per month with full Startup features for 30 days"
        },
        {
          "@type": "Offer",
          "name": "Startup Plan",
          "price": "0.99",
          "priceCurrency": "USD",
          "description": "50 calculations per month, 10 printers, no ads"
        },
        {
          "@type": "Offer",
          "name": "Pro Plan",
          "price": "9.99",
          "priceCurrency": "USD",
          "description": "Unlimited everything with priority support and analytics"
        }
      ],
      "aggregateRating": {
        "@type": "AggregateRating",
        "ratingValue": "4.8",
        "reviewCount": "127"
      }
    }
  end

  def demo
    # Demo page with sample calculator - no authentication required
    @page_title = "CalcuMake Demo - Try Our 3D Print Cost Calculator"
    @meta_description = "Try CalcuMake's 3D print cost calculator with sample data. See how easy it is to calculate accurate pricing for your 3D printing projects."

    # Sample data for demo
    @demo_printer = OpenStruct.new(
      name: "Sample Printer",
      power_consumption: 200,
      cost: 500.00,
      payoff_goal: 3,
      daily_usage: 8,
      repair_factor: 5.0
    )
  end
end