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
  before_validation :calculate_total_price

  # Scopes
  scope :ordered, -> { order(:order_position) }

  private

  def calculate_total_price
    self.total_price = (quantity || 0) * (unit_price || 0)
  end
end
