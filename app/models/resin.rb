# frozen_string_literal: true

class Resin < ApplicationRecord
  belongs_to :user, touch: true
  has_many :plate_resins, dependent: :destroy
  has_many :plates, through: :plate_resins

  RESIN_TYPES = %w[Standard ABS-Like Flexible Tough Castable Dental Water-Washable Plant-Based].freeze

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :resin_type, presence: true, inclusion: { in: RESIN_TYPES }
  validates :bottle_volume_ml, :bottle_price, numericality: { greater_than: 0 }, allow_blank: true
  validates :cure_time_seconds, :exposure_time_seconds,
            numericality: { greater_than: 0, less_than: 3600 }, allow_blank: true
  validates :layer_height_min, :layer_height_max,
            numericality: { greater_than: 0, less_than: 1 }, allow_blank: true

  validate :layer_height_range_valid

  scope :search, ->(query) do
    return all if query.blank?

    where(
      "name ILIKE ? OR brand ILIKE ? OR resin_type ILIKE ? OR color ILIKE ?",
      "%#{sanitize_sql_like(query)}%",
      "%#{sanitize_sql_like(query)}%",
      "%#{sanitize_sql_like(query)}%",
      "%#{sanitize_sql_like(query)}%"
    )
  end

  scope :by_resin_type, ->(type) { where(resin_type: type) if type.present? }

  def self.ransackable_attributes(auth_object = nil)
    %w[brand color created_at cure_time_seconds exposure_time_seconds id layer_height_max
       layer_height_min name needs_wash notes resin_type bottle_price bottle_volume_ml updated_at user_id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[plate_resins plates user]
  end

  def display_name
    "#{brand.present? ? "#{brand} " : ""}#{name} (#{resin_type}#{color.present? ? " - #{color}" : ""})"
  end

  def layer_height_range
    if layer_height_min.present? && layer_height_max.present?
      "#{layer_height_min}-#{layer_height_max}mm"
    elsif layer_height_min.present?
      "#{layer_height_min}mm+"
    elsif layer_height_max.present?
      "up to #{layer_height_max}mm"
    else
      "Not specified"
    end
  end

  def cost_per_ml
    return 0 unless bottle_price.present? && bottle_volume_ml.present? && bottle_volume_ml > 0
    bottle_price / bottle_volume_ml
  end

  private

  def layer_height_range_valid
    return unless layer_height_min.present? && layer_height_max.present?

    if layer_height_min >= layer_height_max
      errors.add(:layer_height_max, :layer_height_range)
    end
  end
end
