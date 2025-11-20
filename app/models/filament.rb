# frozen_string_literal: true

class Filament < ApplicationRecord
  belongs_to :user, touch: true
  has_many :plate_filaments, dependent: :destroy
  has_many :plates, through: :plate_filaments

  validates :name, presence: true, uniqueness: { scope: :user_id }
  validates :material_type, presence: true, inclusion: { in: %w[PLA ABS PETG TPU ASA HIPS Nylon PC PVA Wood Metal Carbon] }
  validates :diameter, presence: true, inclusion: { in: [ 1.75, 2.85, 3.0 ] }
  validates :spool_weight, :spool_price, numericality: { greater_than: 0 }, allow_blank: true
  validates :print_temperature_min, :print_temperature_max, :heated_bed_temperature,
            numericality: { greater_than: 0, less_than: 500 }, allow_blank: true
  validates :print_speed_max, numericality: { greater_than: 0, less_than: 1000 }, allow_blank: true
  validates :storage_temperature_max, numericality: { greater_than: -50, less_than: 100 }, allow_blank: true
  validates :density, numericality: { greater_than: 0, less_than: 10 }, allow_blank: true

  validate :temperature_range_valid

  scope :search, ->(query) do
    return all if query.blank?

    where(
      "name ILIKE ? OR brand ILIKE ? OR material_type ILIKE ? OR color ILIKE ?",
      "%#{sanitize_sql_like(query)}%",
      "%#{sanitize_sql_like(query)}%",
      "%#{sanitize_sql_like(query)}%",
      "%#{sanitize_sql_like(query)}%"
    )
  end

  scope :by_material_type, ->(type) { where(material_type: type) if type.present? }

  def self.ransackable_attributes(auth_object = nil)
    [ "brand", "color", "created_at", "density", "diameter", "finish", "heated_bed_temperature", "id", "material_type", "moisture_sensitive", "name", "notes", "print_speed_max", "print_temperature_max", "print_temperature_min", "spool_price", "spool_weight", "storage_temperature_max", "updated_at", "user_id" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "plate_filaments", "plates", "user" ]
  end

  def display_name
    "#{brand.present? ? "#{brand} " : ""}#{name} (#{material_type}#{color.present? ? " - #{color}" : ""})"
  end

  def temperature_range
    if print_temperature_min.present? && print_temperature_max.present?
      "#{print_temperature_min}-#{print_temperature_max}°C"
    elsif print_temperature_min.present?
      "#{print_temperature_min}°C+"
    elsif print_temperature_max.present?
      "up to #{print_temperature_max}°C"
    else
      "Not specified"
    end
  end

  def cost_per_gram
    return 0 unless spool_price.present? && spool_weight.present? && spool_weight > 0
    spool_price / spool_weight
  end

  private

  def temperature_range_valid
    return unless print_temperature_min.present? && print_temperature_max.present?

    if print_temperature_min >= print_temperature_max
      errors.add(:print_temperature_max, :temperature_range)
    end
  end
end
