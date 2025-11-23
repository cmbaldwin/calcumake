# Service for converting currencies using Frankfurter API (European Central Bank)
# Caches exchange rates for 24 hours to minimize API calls
# API: https://www.frankfurter.app/
class CurrencyConverter
  CACHE_EXPIRY = 24.hours
  API_URL = "https://api.frankfurter.app"

  class << self
    # Convert amount from one currency to another
    # @param amount [Numeric] The amount to convert
    # @param from [String] Source currency code (e.g., 'JPY')
    # @param to [String] Target currency code (e.g., 'USD')
    # @return [Float, nil] Converted amount or nil if conversion fails
    def convert(amount, from:, to:)
      return amount.to_f if from.upcase == to.upcase
      return nil if amount.nil? || amount.zero?

      rate = fetch_rate(from, to)
      return nil unless rate

      (amount.to_f * rate).round(2)
    end

    # Get exchange rate from one currency to another
    # @param from [String] Source currency code
    # @param to [String] Target currency code
    # @return [Float, nil] Exchange rate or nil if fetch fails
    def fetch_rate(from, to)
      from = from.to_s.upcase
      to = to.to_s.upcase

      cache_key = "exchange_rate:#{from}:#{to}"

      # Try to fetch from cache first
      cached_rate = Rails.cache.read(cache_key)
      return cached_rate if cached_rate

      # Fetch from API
      rate = fetch_rate_from_api(from, to)

      # Cache the rate if successful
      Rails.cache.write(cache_key, rate, expires_in: CACHE_EXPIRY) if rate

      rate
    rescue StandardError => e
      Rails.logger.error "CurrencyConverter: Failed to fetch rate #{from} -> #{to}: #{e.message}"
      nil
    end

    private

    # Fetch exchange rate from Frankfurter API
    # @param from [String] Source currency code
    # @param to [String] Target currency code
    # @return [Float, nil] Exchange rate or nil if fetch fails
    def fetch_rate_from_api(from, to)
      uri = URI("#{API_URL}/latest?from=#{from}&to=#{to}")
      response = Net::HTTP.get_response(uri)

      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      data.dig("rates", to)&.to_f
    rescue JSON::ParserError, SocketError, Timeout::Error => e
      Rails.logger.error "CurrencyConverter API error: #{e.message}"
      nil
    end
  end
end
