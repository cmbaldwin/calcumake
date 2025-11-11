class InvoiceLineItem < ApplicationRecord
  belongs_to :invoice

  # Validations
  validates :description, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :line_item_type, presence: true, inclusion: {
    in: %w[filament electricity labor machine other custom]
  }
  validates :order_position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Callbacks
  before_validation :round_prices_to_currency_precision
  before_validation :calculate_total_price

  # Scopes
  scope :ordered, -> { order(:order_position) }

  private

  def round_prices_to_currency_precision
    return unless invoice&.currency

    precision = currency_decimals
    self.unit_price = unit_price.round(precision) if unit_price
    # Note: quantity is not rounded to currency precision as it represents count of items
  end

  def calculate_total_price
    rounded_quantity = quantity || 0
    rounded_unit_price = unit_price || 0
    calculated_total = rounded_quantity * rounded_unit_price

    # Round the total to currency precision as well
    if invoice&.currency
      precision = currency_decimals
      self.total_price = calculated_total.round(precision)
    else
      self.total_price = calculated_total
    end
  end

  def currency_decimals
    # Zero decimal currencies
    zero_decimal_currencies = %w[JPY KRW VND CLP TWD]

    if zero_decimal_currencies.include?(invoice.currency)
      0
    else
      2
    end
  end
end
