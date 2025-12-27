# frozen_string_literal: true

# Public controller for printer profile reference data
# No authentication required - this is publicly accessible for form helpers
class PrinterProfilesController < ApplicationController
  def index
    @profiles = PrinterProfile.order(:manufacturer, :model)

    if params[:technology].present?
      @profiles = @profiles.by_technology(params[:technology])
    end

    if params[:q].present?
      @profiles = @profiles.search(params[:q])
    end

    # This endpoint is primarily for JSON API access by the form helper
    # HTML format also returns JSON for convenience
    respond_to do |format|
      format.json { render json: @profiles.map { |p| profile_json(p) } }
      format.any { render json: @profiles.map { |p| profile_json(p) } }
    end
  end

  private

  def profile_json(profile)
    {
      id: profile.id,
      manufacturer: profile.manufacturer,
      model: profile.model,
      display_name: profile.display_name,
      full_display_name: profile.full_display_name,
      category: profile.category,
      technology: profile.technology,
      power_consumption_avg_watts: profile.power_consumption_avg_watts,
      power_consumption_peak_watts: profile.power_consumption_peak_watts,
      cost_usd: profile.cost_usd&.to_f
    }
  end
end
