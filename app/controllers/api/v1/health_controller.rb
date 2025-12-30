# frozen_string_literal: true

module Api
  module V1
    class HealthController < BaseController
      skip_before_action :authenticate_api_token!, only: [ :show ]

      def show
        render json: {
          status: "healthy",
          timestamp: Time.current.iso8601,
          version: "v1"
        }
      end
    end
  end
end
