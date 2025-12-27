# frozen_string_literal: true

module Api
  module V1
    class PrinterProfilesController < BaseController
      # Public endpoint - skip authentication for browsing printer profiles
      skip_before_action :authenticate_api_token!

      def index
        @profiles = PrinterProfile.all

        # Apply search filter
        @profiles = @profiles.search(params[:q]) if params[:q].present?

        # Apply technology filter
        @profiles = @profiles.by_technology(params[:technology]) if params[:technology].present?

        # Sort by manufacturer and model
        @profiles = @profiles.order(:manufacturer, :model)

        render json: {
          data: @profiles.map { |profile| serialize_profile(profile) },
          meta: {
            total_count: @profiles.count,
            technologies: PrinterProfile.technologies.keys,
            categories: PrinterProfile::CATEGORIES
          }
        }
      end

      private

      def serialize_profile(profile)
        {
          id: profile.id.to_s,
          type: "printer_profile",
          attributes: {
            manufacturer: profile.manufacturer,
            model: profile.model,
            technology: profile.technology,
            category: profile.category,
            build_volume_x: profile.build_volume_x,
            build_volume_y: profile.build_volume_y,
            build_volume_z: profile.build_volume_z,
            power_consumption: profile.power_consumption,
            price_usd: profile.price_usd&.to_f,
            display_name: profile.display_name,
            full_display_name: profile.full_display_name
          }
        }
      end
    end
  end
end
