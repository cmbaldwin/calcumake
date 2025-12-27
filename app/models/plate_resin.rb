# frozen_string_literal: true

class PlateResin < ApplicationRecord
  belongs_to :plate
  belongs_to :resin

  validates :resin_volume_ml, presence: true, numericality: { greater_than: 0 }
  validates :resin_id, uniqueness: { scope: :plate_id, message: :already_added }

  delegate :user, to: :plate
  delegate :print_pricing, to: :plate
  delegate :cost_per_ml, :resin_type, :display_name, to: :resin, allow_nil: true

  def total_cost
    return 0 unless resin_volume_ml.present? && resin&.cost_per_ml.to_f > 0
    base_cost = resin_volume_ml * resin.cost_per_ml
    markup_multiplier = 1 + ((markup_percentage || 0) / 100.0)
    base_cost * markup_multiplier
  end
end
