class Plate < ApplicationRecord
  belongs_to :print_pricing

  validates :filament_type, presence: true
  validates :printing_time_hours, :printing_time_minutes, numericality: { greater_than_or_equal_to: 0 }
  validates :filament_weight, :spool_price, :spool_weight, :markup_percentage,
            numericality: { greater_than: 0 }

  def total_printing_time_minutes
    (printing_time_hours || 0) * 60 + (printing_time_minutes || 0)
  end

  def total_filament_cost
    return 0 unless filament_weight && spool_price && spool_weight
    (filament_weight * spool_price / spool_weight) * (1 + (markup_percentage || 0) / 100)
  end
end
