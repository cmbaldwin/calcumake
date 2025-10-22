module CurrencyHelper
  # Map currencies to their appropriate locales for proper number formatting
  CURRENCY_CONFIGS = {
    "USD" => {
      name: "US Dollar (USD)",
      decimals: 2,
      symbol: "$",
      locale: :en,
      sample_values: { spool_price: "25.00", prep_cost: "20.00", energy_cost: "0.12", printer_cost: "500.00" }
    },
    "EUR" => {
      name: "Euro (EUR)",
      decimals: 2,
      symbol: "€",
      locale: :fr,
      sample_values: { spool_price: "22.50", prep_cost: "18.00", energy_cost: "0.10", printer_cost: "450.00" }
    },
    "GBP" => {
      name: "British Pound (GBP)",
      decimals: 2,
      symbol: "£",
      locale: :en,
      sample_values: { spool_price: "20.00", prep_cost: "15.00", energy_cost: "0.09", printer_cost: "400.00" }
    },
    "JPY" => {
      name: "Japanese Yen (¥)",
      decimals: 0,
      symbol: "¥",
      locale: :ja,
      sample_values: { spool_price: "3000", prep_cost: "2500", energy_cost: "15", printer_cost: "60000" }
    },
    "CAD" => {
      name: "Canadian Dollar (CAD)",
      decimals: 2,
      symbol: "C$",
      locale: :en,
      sample_values: { spool_price: "30.00", prep_cost: "25.00", energy_cost: "0.15", printer_cost: "650.00" }
    },
    "AUD" => {
      name: "Australian Dollar (AUD)",
      decimals: 2,
      symbol: "A$",
      locale: :en,
      sample_values: { spool_price: "35.00", prep_cost: "28.00", energy_cost: "0.18", printer_cost: "700.00" }
    },
    "CNY" => {
      name: "Chinese Yuan (CNY)",
      decimals: 2,
      symbol: "¥",
      locale: :'zh-CN',
      sample_values: { spool_price: "160.00", prep_cost: "130.00", energy_cost: "0.80", printer_cost: "3200.00" }
    },
    "INR" => {
      name: "Indian Rupee (INR)",
      decimals: 2,
      symbol: "₹",
      locale: :hi,
      sample_values: { spool_price: "2000.00", prep_cost: "1600.00", energy_cost: "10.00", printer_cost: "40000.00" }
    },
    "ARS" => {
      name: "Argentine Peso (ARS)",
      decimals: 2,
      symbol: "$",
      locale: :es,
      sample_values: { spool_price: "8000.00", prep_cost: "6500.00", energy_cost: "40.00", printer_cost: "160000.00" }
    },
    "SAR" => {
      name: "Saudi Riyal (SAR)",
      decimals: 2,
      symbol: "﷼",
      locale: :ar,
      sample_values: { spool_price: "95.00", prep_cost: "75.00", energy_cost: "0.45", printer_cost: "1900.00" }
    }
  }.freeze

  def currency_options
    CURRENCY_CONFIGS.map { |code, config| [ config[:name], code ] }
  end

  def format_currency(amount, currency_code)
    return "0" if amount.nil? || amount == 0

    config = CURRENCY_CONFIGS[currency_code] || CURRENCY_CONFIGS["USD"]
    precision = config[:decimals]

    number_with_precision(amount, precision: precision, delimiter: delimiter_for_locale(config[:locale]))
  end

  def delimiter_for_locale(locale)
    # Use comma for most locales, but some use different delimiters
    case locale
    when :fr, :'zh-CN'
      " " # French and Chinese use space
    when :de
      "." # German uses period
    else
      "," # English, Spanish, Japanese, etc. use comma
    end
  end

  def currency_decimals(currency_code)
    CURRENCY_CONFIGS.dig(currency_code, :decimals) || 2
  end

  def zero_decimal_currencies
    CURRENCY_CONFIGS.select { |_, config| config[:decimals] == 0 }.keys
  end

  def currency_symbol(currency_code)
    CURRENCY_CONFIGS.dig(currency_code, :symbol) || "$"
  end

  def currency_sample_values(currency_code)
    CURRENCY_CONFIGS.dig(currency_code, :sample_values) || CURRENCY_CONFIGS["USD"][:sample_values]
  end
end
