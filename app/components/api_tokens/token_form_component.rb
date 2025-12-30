# frozen_string_literal: true

module ApiTokens
  class TokenFormComponent < ViewComponent::Base
    def initialize(token:)
      @token = token
    end

    def expiration_options
      ApiToken::EXPIRATION_OPTIONS.keys.map do |key|
        [ t("api_tokens.expiration.#{key}"), key ]
      end
    end
  end
end
