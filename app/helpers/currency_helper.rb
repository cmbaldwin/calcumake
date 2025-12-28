module CurrencyHelper
  # Map currencies to their appropriate locales for proper number formatting
  CURRENCY_CONFIGS = {
    "USD" => {
      name: "US Dollar (USD)",
      decimals: 2,
      symbol: "$",
      locale: :en,
      # Energy: US average is ~$0.18/kWh (2025)
      sample_values: { spool_price: "25.00", prep_cost: "20.00", energy_cost: "0.18", printer_cost: "500.00" }
    },
    "EUR" => {
      name: "Euro (EUR)",
      decimals: 2,
      symbol: "€",
      locale: :de, # Changed to :de (Germany) as largest EU economy
      # Energy: EU average is ~€0.28/kWh (varies from €0.12 in Spain to €0.38 in Germany)
      sample_values: { spool_price: "25.00", prep_cost: "20.00", energy_cost: "0.28", printer_cost: "450.00" }
    },
    "GBP" => {
      name: "British Pound (GBP)",
      decimals: 2,
      symbol: "£",
      locale: :en,
      # Energy: UK price cap remains high, average £0.26/kWh (2025)
      sample_values: { spool_price: "22.00", prep_cost: "18.00", energy_cost: "0.26", printer_cost: "400.00" }
    },
    "JPY" => {
      name: "Japanese Yen (¥)",
      decimals: 0,
      symbol: "¥",
      locale: :ja,
      # Energy: Japan average is ¥38/kWh (2025)
      sample_values: { spool_price: "4000", prep_cost: "3000", energy_cost: "38", printer_cost: "75000" }
    },
    "CAD" => {
      name: "Canadian Dollar (CAD)",
      decimals: 2,
      symbol: "C$",
      locale: :en,
      # Energy: Canada average is C$0.16/kWh (2025)
      sample_values: { spool_price: "35.00", prep_cost: "25.00", energy_cost: "0.16", printer_cost: "680.00" }
    },
    "AUD" => {
      name: "Australian Dollar (AUD)",
      decimals: 2,
      symbol: "A$",
      locale: :en,
      # Energy: Australia average is A$0.32/kWh (2025)
      sample_values: { spool_price: "40.00", prep_cost: "30.00", energy_cost: "0.32", printer_cost: "750.00" }
    },
    "CNY" => {
      name: "Chinese Yuan (CNY)",
      decimals: 2,
      symbol: "¥",
      locale: :'zh-CN',
      # Energy: China residential rate is ¥0.60/kWh (2025)
      sample_values: { spool_price: "150.00", prep_cost: "130.00", energy_cost: "0.60", printer_cost: "3500.00" }
    },
    "INR" => {
      name: "Indian Rupee (INR)",
      decimals: 2,
      symbol: "₹",
      locale: :hi,
      # Energy: India average is ₹8.50/kWh (2025)
      sample_values: { spool_price: "2200.00", prep_cost: "1800.00", energy_cost: "8.50", printer_cost: "45000.00" }
    },
    "ARS" => {
      name: "Argentine Peso (ARS)",
      decimals: 2,
      symbol: "$",
      locale: :es,
      # Energy: Argentina ~120 ARS/kWh due to inflation (2025)
      sample_values: { spool_price: "35000.00", prep_cost: "28000.00", energy_cost: "120.00", printer_cost: "750000.00" }
    },
    "SAR" => {
      name: "Saudi Riyal (SAR)",
      decimals: 2,
      symbol: "﷼",
      locale: :ar,
      # Energy: Residential rate is 0.18 SAR (18 Halalah) for first 6000kWh
      sample_values: { spool_price: "100.00", prep_cost: "80.00", energy_cost: "0.18", printer_cost: "2000.00" }
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

  # Convert USD amount to specified currency and format for display
  def convert_and_format_currency(usd_amount, to_currency)
    return number_to_currency(usd_amount, unit: "$") if to_currency == "USD"

    converted = CurrencyConverter.convert(usd_amount, from: "USD", to: to_currency)

    if converted
      symbol = currency_symbol(to_currency)
      formatted = format_currency(converted, to_currency)
      "#{symbol}#{formatted}"
    else
      # Fallback to USD if conversion fails
      number_to_currency(usd_amount, unit: "$")
    end
  end
end
