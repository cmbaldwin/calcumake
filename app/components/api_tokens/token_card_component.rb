# frozen_string_literal: true

module ApiTokens
  class TokenCardComponent < ViewComponent::Base
    include ActionView::Helpers::DateHelper

    def initialize(token:)
      @token = token
    end

    def status_badge_class
      if @token.revoked?
        "bg-danger"
      elsif @token.expired?
        "bg-warning text-dark"
      else
        "bg-success"
      end
    end

    def status_text
      if @token.revoked?
        t("api_tokens.status.revoked")
      elsif @token.expired?
        t("api_tokens.status.expired")
      else
        t("api_tokens.status.active")
      end
    end

    def expires_text
      return t("api_tokens.never_expires") if @token.never_expires?
      return t("api_tokens.expired_on", date: l(@token.expires_at, format: :short)) if @token.expired?

      t("api_tokens.expires_on", date: l(@token.expires_at, format: :short))
    end

    def last_used_text
      return t("api_tokens.never_used") unless @token.last_used_at

      t("api_tokens.last_used", time: time_ago_in_words(@token.last_used_at))
    end

    def created_text
      t("api_tokens.created", date: l(@token.created_at, format: :short))
    end
  end
end
