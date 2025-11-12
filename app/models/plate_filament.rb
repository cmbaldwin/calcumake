class PlateFilament < ApplicationRecord
  belongs_to :plate
  belongs_to :filament

  validates :filament_weight, presence: true, numericality: { greater_than: 0 }
  validates :filament_id, uniqueness: { scope: :plate_id, message: :already_added }

  delegate :user, to: :plate
  delegate :print_pricing, to: :plate
  delegate :cost_per_gram, :material_type, :display_name, to: :filament, allow_nil: true

  def total_cost
    return 0 unless filament_weight.present? && filament&.cost_per_gram.to_f > 0
    base_cost = filament_weight * filament.cost_per_gram
    markup_multiplier = 1 + ((markup_percentage || 0) / 100.0)
    base_cost * markup_multiplier
  end
end
