# Service for converting currencies using Frankfurter API (European Central Bank)
# Caches exchange rates for 24 hours to minimize API calls
# API: https://www.frankfurter.app/
require 'net/http'
require 'openssl'

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

      # Configure HTTP client with SSL options
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 5
      http.read_timeout = 5

      # In development, be more lenient with SSL verification
      if Rails.env.development?
        http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      end

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      return nil unless response.is_a?(Net::HTTPSuccess)

      data = JSON.parse(response.body)
      data.dig("rates", to)&.to_f
    rescue JSON::ParserError, SocketError, Timeout::Error, OpenSSL::SSL::SSLError => e
      Rails.logger.error "CurrencyConverter API error: #{e.message}"

      # Use fallback rates in development if API fails
      fallback_rate(from, to)
    end

    # Fallback exchange rates for development when API is unavailable
    # Rates are approximate and updated periodically
    # @param from [String] Source currency code
    # @param to [String] Target currency code
    # @return [Float, nil] Exchange rate or nil if pair not in fallback table
    def fallback_rate(from, to)
      # Only use fallback in development/test
      return nil unless Rails.env.development? || Rails.env.test?

      # Approximate rates as of December 2025
      fallback_rates = {
        "USD" => { "JPY" => 156.0, "EUR" => 0.92, "GBP" => 0.79, "CAD" => 1.35, "AUD" => 1.48 },
        "JPY" => { "USD" => 0.0064, "EUR" => 0.0059, "GBP" => 0.0051, "CAD" => 0.0087, "AUD" => 0.0095 },
        "EUR" => { "USD" => 1.09, "JPY" => 170.0, "GBP" => 0.86, "CAD" => 1.47, "AUD" => 1.61 },
        "GBP" => { "USD" => 1.27, "JPY" => 197.0, "EUR" => 1.16, "CAD" => 1.71, "AUD" => 1.87 },
        "CAD" => { "USD" => 0.74, "JPY" => 115.0, "EUR" => 0.68, "GBP" => 0.58, "AUD" => 1.10 },
        "AUD" => { "USD" => 0.68, "JPY" => 105.0, "EUR" => 0.62, "GBP" => 0.53, "CAD" => 0.91 }
      }

      rate = fallback_rates.dig(from, to)

      if rate
        Rails.logger.warn "CurrencyConverter: Using fallback rate for #{from} -> #{to}: #{rate}"
      end

      rate
    end
  end
end
