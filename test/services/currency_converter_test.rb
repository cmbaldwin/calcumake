require "test_helper"
require "webmock/minitest"

class CurrencyConverterTest < ActiveSupport::TestCase
  setup do
    # Clear cache before each test
    Rails.cache.clear
  end

  test "converts JPY to USD using API" do
    # Stub API response
    stub_request(:get, "https://api.frankfurter.app/latest?from=JPY&to=USD")
      .to_return(
        status: 200,
        body: { "rates" => { "USD" => 0.0067 } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    amount = CurrencyConverter.convert(150, from: "JPY", to: "USD")
    assert_in_delta 1.01, amount, 0.01
  end

  test "caches exchange rates for 24 hours" do
    # Stub first API call
    stub_request(:get, "https://api.frankfurter.app/latest?from=JPY&to=USD")
      .to_return(
        status: 200,
        body: { "rates" => { "USD" => 0.0067 } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # First call should hit the API
    rate1 = CurrencyConverter.fetch_rate("JPY", "USD")
    assert_not_nil rate1

    # Clear stub to ensure second call uses cache
    WebMock.reset!

    # Second call should use cache (won't fail even though we cleared stubs)
    rate2 = CurrencyConverter.fetch_rate("JPY", "USD")
    assert_equal rate1, rate2
  end

  test "returns nil when API fails" do
    # Stub API failure
    stub_request(:get, "https://api.frankfurter.app/latest?from=JPY&to=USD")
      .to_return(status: 500)

    amount = CurrencyConverter.convert(150, from: "JPY", to: "USD")
    assert_nil amount
  end

  test "returns amount unchanged when from and to currencies are the same" do
    amount = CurrencyConverter.convert(150, from: "USD", to: "USD")
    assert_equal 150.0, amount
  end

  test "returns nil when amount is zero" do
    amount = CurrencyConverter.convert(0, from: "JPY", to: "USD")
    assert_nil amount
  end

  test "returns nil when amount is nil" do
    amount = CurrencyConverter.convert(nil, from: "JPY", to: "USD")
    assert_nil amount
  end

  test "handles network errors gracefully" do
    # Stub network error
    stub_request(:get, "https://api.frankfurter.app/latest?from=JPY&to=USD")
      .to_raise(SocketError)

    amount = CurrencyConverter.convert(150, from: "JPY", to: "USD")
    assert_nil amount
  end

  test "handles timeout errors gracefully" do
    # Stub timeout error
    stub_request(:get, "https://api.frankfurter.app/latest?from=JPY&to=USD")
      .to_raise(Timeout::Error)

    amount = CurrencyConverter.convert(150, from: "JPY", to: "USD")
    assert_nil amount
  end

  test "handles invalid JSON response" do
    # Stub invalid JSON
    stub_request(:get, "https://api.frankfurter.app/latest?from=JPY&to=USD")
      .to_return(
        status: 200,
        body: "invalid json",
        headers: { "Content-Type" => "application/json" }
      )

    amount = CurrencyConverter.convert(150, from: "JPY", to: "USD")
    assert_nil amount
  end

  test "rounds converted amount to 2 decimal places" do
    # Stub API response with many decimal places
    stub_request(:get, "https://api.frankfurter.app/latest?from=JPY&to=USD")
      .to_return(
        status: 200,
        body: { "rates" => { "USD" => 0.006666666 } }.to_json,
        headers: { "Content-Type" => "application/json" }
      )

    amount = CurrencyConverter.convert(150, from: "JPY", to: "USD")
    assert_equal 1.0, amount
    assert_kind_of Float, amount
  end
end
