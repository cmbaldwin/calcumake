require "ostruct"

class PagesController < ApplicationController
  include StructuredDataGenerator

  # Note: Public pages don't require authentication in this app

  def landing
    # AI-first minimal landing page
    @page_title = "CalcuMake - AI 3D Print Cost Calculator"
    @meta_description = "Upload your STL or 3MF file to instantly estimate 3D printing costs, or chat with AI. Free calculator with multi-currency support."
    @meta_keywords = "3d print cost calculator, stl cost calculator, 3mf cost analysis, AI 3D printing, filament cost estimator"

    # Generate structured data for SEO (pricing fetched from Stripe API if available)
    @structured_data = landing_page_structured_data
  end

  def about
    # Full product information page (moved from old landing)
    @page_title = "About CalcuMake - 3D Print Cost Calculator & Project Management"
    @meta_description = "Make 3D printing profitable with accurate cost calculations. Multi-currency support, printer management, and instant invoicing. Start free - no credit card required."
    @meta_keywords = "3d print cost calculator, 3d printing calculator, filament cost calculator, 3d printer cost estimation, 3d printing pricing"

    @structured_data = landing_page_structured_data
  end

  def dashboard
    # Authenticated user dashboard - redirects to print pricings index
    redirect_to print_pricings_path
  end

  def pricing_calculator
    # Advanced SPA pricing calculator with quick calculator at top - no authentication required
    @page_title = "Free 3D Print Pricing Calculator | Multi-Plate Cost Estimator"
    @meta_description = "Professional 3D print pricing calculator with multi-plate support, filament tracking, labor costs, and instant PDF/CSV export. Free to use, no signup required."
    @meta_keywords = "3d print calculator, 3d printing cost calculator, filament calculator, multi-plate calculator, 3d printing pricing tool, print cost estimator"
  end
end
