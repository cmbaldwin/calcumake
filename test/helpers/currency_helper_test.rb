require "test_helper"

class CurrencyHelperTest < ActionView::TestCase
  test "currency_options returns correct format" do
    options = currency_options
    assert_includes options, [ "US Dollar (USD)", "USD" ]
    assert_includes options, [ "Euro (EUR)", "EUR" ]
    assert_includes options, [ "Japanese Yen (¥)", "JPY" ]
  end

  test "currency_symbol returns correct symbols" do
    assert_equal "$", currency_symbol("USD")
    assert_equal "€", currency_symbol("EUR")
    assert_equal "£", currency_symbol("GBP")
    assert_equal "¥", currency_symbol("JPY")
    assert_equal "C$", currency_symbol("CAD")
    assert_equal "A$", currency_symbol("AUD")
    assert_equal "$", currency_symbol("UNKNOWN") # fallback
  end

  test "currency_decimals returns correct decimal places" do
    assert_equal 2, currency_decimals("USD")
    assert_equal 2, currency_decimals("EUR")
    assert_equal 0, currency_decimals("JPY")
    assert_equal 2, currency_decimals("UNKNOWN") # fallback
  end

  test "format_currency handles different currencies correctly" do
    assert_equal "25.00", format_currency(25, "USD")
    assert_equal "25.00", format_currency(25, "EUR")
    assert_equal "25", format_currency(25, "JPY")
    assert_equal "0", format_currency(0, "USD")
    assert_equal "0", format_currency(nil, "USD")
  end

  test "zero_decimal_currencies returns JPY" do
    zero_currencies = zero_decimal_currencies
    assert_includes zero_currencies, "JPY"
    assert_not_includes zero_currencies, "USD"
  end

  test "currency_sample_values returns appropriate values" do
    usd_samples = currency_sample_values("USD")
    assert_equal "25.00", usd_samples[:spool_price]
    assert_equal "500.00", usd_samples[:printer_cost]

    jpy_samples = currency_sample_values("JPY")
    assert_equal "3000", jpy_samples[:spool_price]
    assert_equal "60000", jpy_samples[:printer_cost]
  end
end
