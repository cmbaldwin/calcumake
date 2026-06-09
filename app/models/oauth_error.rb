# frozen_string_literal: true

class OAuthError < StandardError
  attr_reader :error_code

  def initialize(message = "server_error", error_code: "server_error")
    super(message)
    @error_code = error_code
  end
end
