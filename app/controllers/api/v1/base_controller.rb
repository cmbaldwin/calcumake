# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods

      before_action :authenticate_api_token!
      after_action :log_api_access

      rescue_from ActiveRecord::RecordNotFound, with: :not_found
      rescue_from ActiveRecord::RecordInvalid, with: :unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :bad_request

      private

      def authenticate_api_token!
        authenticate_with_http_token do |token, _options|
          @current_api_token = ApiToken.authenticate(token)
          @current_user = @current_api_token&.user
        end

        return if @current_user.present?

        render json: {
          errors: [ {
            status: "401",
            code: "unauthorized",
            title: "Unauthorized",
            detail: "Invalid or missing API token"
          } ]
        }, status: :unauthorized
      end

      def current_user
        @current_user
      end

      def current_api_token
        @current_api_token
      end

      def log_api_access
        return unless @current_api_token

        Rails.logger.info({
          event: "api_access",
          token_hint: @current_api_token.token_hint,
          user_id: @current_api_token.user_id,
          ip: request.remote_ip,
          path: request.path,
          method: request.method,
          status: response.status,
          timestamp: Time.current.iso8601
        }.to_json)
      end

      def not_found
        render json: {
          errors: [ {
            status: "404",
            code: "not_found",
            title: "Not Found",
            detail: "The requested resource could not be found"
          } ]
        }, status: :not_found
      end

      def unprocessable_entity(exception)
        render json: {
          errors: exception.record.errors.map do |error|
            {
              status: "422",
              code: "validation_error",
              title: "Validation Failed",
              detail: error.full_message,
              source: { pointer: "/data/attributes/#{error.attribute}" }
            }
          end
        }, status: :unprocessable_entity
      end

      def bad_request(exception)
        render json: {
          errors: [ {
            status: "400",
            code: "bad_request",
            title: "Bad Request",
            detail: "Missing required parameter: #{exception.param}"
          } ]
        }, status: :bad_request
      end

      # Pagination helpers
      def pagination_meta(collection)
        {
          current_page: collection.current_page,
          total_pages: collection.total_pages,
          total_count: collection.total_count,
          per_page: collection.limit_value
        }
      end

      def pagination_links(collection, path)
        {
          self: "#{path}?page=#{collection.current_page}",
          first: "#{path}?page=1",
          prev: collection.prev_page ? "#{path}?page=#{collection.prev_page}" : nil,
          next: collection.next_page ? "#{path}?page=#{collection.next_page}" : nil,
          last: "#{path}?page=#{collection.total_pages}"
        }
      end
    end
  end
end
