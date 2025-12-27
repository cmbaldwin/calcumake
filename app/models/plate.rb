class Plate < ApplicationRecord
  belongs_to :print_pricing
  has_many :plate_filaments, dependent: :destroy
  has_many :filaments, through: :plate_filaments
  has_many :plate_resins, dependent: :destroy
  has_many :resins, through: :plate_resins

  accepts_nested_attributes_for :plate_filaments, allow_destroy: true, reject_if: :reject_plate_filament?
  accepts_nested_attributes_for :plate_resins, allow_destroy: true, reject_if: :reject_plate_resin?

  enum :material_technology, { fdm: "fdm", resin: "resin" }, default: :fdm

  validates :printing_time_hours, :printing_time_minutes, numericality: { greater_than_or_equal_to: 0 }
  validate :must_have_at_least_one_filament, if: :fdm?
  validate :must_have_at_least_one_resin, if: :resin?
  validate :no_duplicate_filaments, if: :fdm?

  delegate :user, to: :print_pricing

  def total_printing_time_minutes
    (printing_time_hours || 0) * 60 + (printing_time_minutes || 0)
  end

  def total_material_cost
    fdm? ? total_filament_cost : total_resin_cost
  end

  def total_filament_cost
    plate_filaments.sum(&:total_cost)
  end

  def total_resin_cost
    plate_resins.sum(&:total_cost)
  end

  def total_filament_weight
    plate_filaments.sum(&:filament_weight)
  end

  def total_resin_volume
    plate_resins.sum(&:resin_volume_ml)
  end

  def filament_types
    plate_filaments.includes(:filament).map { |pf| pf.filament.material_type }.uniq.join(", ")
  end

  def resin_types
    plate_resins.includes(:resin).map { |pr| pr.resin.resin_type }.uniq.join(", ")
  end

  def material_types
    fdm? ? filament_types : resin_types
  end

  private

  def must_have_at_least_one_filament
    if plate_filaments.reject(&:marked_for_destruction?).empty?
      errors.add(:base, :no_filaments)
    end
  end

  def must_have_at_least_one_resin
    if plate_resins.reject(&:marked_for_destruction?).empty?
      errors.add(:base, :no_resins)
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

  # Reject plate_filaments when essential fields are blank
  # Note: Controller filters out mismatched technology attributes before they reach here
  def reject_plate_filament?(attributes)
    attributes["filament_id"].blank? && attributes["filament_weight"].blank?
  end

  # Reject plate_resins when essential fields are blank
  # Note: Controller filters out mismatched technology attributes before they reach here
  def reject_plate_resin?(attributes)
    attributes["resin_id"].blank? && attributes["resin_volume_ml"].blank?
  end
end
