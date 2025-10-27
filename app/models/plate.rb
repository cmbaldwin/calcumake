class Plate < ApplicationRecord
  belongs_to :print_pricing
  has_many :plate_filaments, dependent: :destroy
  has_many :filaments, through: :plate_filaments

  accepts_nested_attributes_for :plate_filaments, allow_destroy: true, reject_if: :all_blank

  validates :printing_time_hours, :printing_time_minutes, numericality: { greater_than_or_equal_to: 0 }
  validate :must_have_at_least_one_filament
  validate :no_duplicate_filaments

  delegate :user, to: :print_pricing

  def total_printing_time_minutes
    (printing_time_hours || 0) * 60 + (printing_time_minutes || 0)
  end

  def total_filament_cost
    plate_filaments.sum(&:total_cost)
  end

  def total_filament_weight
    plate_filaments.sum(&:filament_weight)
  end

  def filament_types
    plate_filaments.includes(:filament).map { |pf| pf.filament.material_type }.uniq.join(", ")
  end

  private

  def must_have_at_least_one_filament
    if plate_filaments.reject(&:marked_for_destruction?).empty?
      errors.add(:base, :no_filaments)
    end
  end

  def no_duplicate_filaments
    active_filaments = plate_filaments.reject(&:marked_for_destruction?)
    filament_ids = active_filaments.map(&:filament_id).compact

    if filament_ids.uniq.length != filament_ids.length
      # Add error to the parent print_pricing so it appears at the top level
      print_pricing.errors.add(:base, :duplicate_filaments_on_plate)
    end
  end
end
