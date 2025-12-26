# frozen_string_literal: true

module ApiTokens
  class TokenRevealComponent < ViewComponent::Base
    def initialize(token:, plain_token:)
      @token = token
      @plain_token = plain_token
    end
  end
end
