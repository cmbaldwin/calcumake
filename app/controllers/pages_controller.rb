require "ostruct"

class PagesController < ApplicationController
  include StructuredDataGenerator

  # Note: Public pages don't require authentication in this app

  def landing
    # Redirect authenticated users to the main app
    redirect_to print_pricings_path if user_signed_in?

    # Set SEO data for landing page
    @page_title = "CalcuMake - 3D Print Cost Calculator & Project Management"
    @meta_description = "Make 3D printing profitable with accurate cost calculations. Multi-currency support, printer management, and instant invoicing. Start free - no credit card required."
    @meta_keywords = "3d print cost calculator, 3d printing calculator, filament cost calculator, 3d printer cost estimation, 3d printing pricing"

    # Generate structured data for SEO (pricing fetched from Stripe API if available)
    @structured_data = landing_page_structured_data
  end

  def pricing_calculator
    # Advanced SPA pricing calculator with quick calculator at top - no authentication required
    @page_title = "Free 3D Print Pricing Calculator | Multi-Plate Cost Estimator"
    @meta_description = "Professional 3D print pricing calculator with multi-plate support, filament tracking, labor costs, and instant PDF/CSV export. Free to use, no signup required."
    @meta_keywords = "3d print calculator, 3d printing cost calculator, filament calculator, multi-plate calculator, 3d printing pricing tool, print cost estimator"
  end
end
