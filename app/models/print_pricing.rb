class PrintPricing < ApplicationRecord
  belongs_to :user, touch: true
  belongs_to :printer, optional: true
  belongs_to :client, optional: true
  has_many :plates, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_one_attached :three_mf_file

  accepts_nested_attributes_for :plates, allow_destroy: true, reject_if: :all_blank

  validates :job_name, presence: true
  validates :times_printed, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :units, numericality: { greater_than: 0, only_integer: true }
  validates :failure_rate_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :listing_cost_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :payment_processing_cost_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :must_have_at_least_one_plate
  validate :cannot_have_more_than_ten_plates
  validate :three_mf_file_format

  before_save :calculate_final_price
  after_commit :process_three_mf_file, if: :three_mf_file_attached_and_pending?

  include CurrencyHelper

  delegate :default_currency, :default_energy_cost_per_kwh, to: :user

  scope :search, ->(query) do
    return all if query.blank?

    where("job_name ILIKE ?", "%#{sanitize_sql_like(query)}%")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "failure_rate_percentage", "final_price", "id", "id_value", "job_name", "other_costs", "postprocessing_cost_per_hour", "postprocessing_time_minutes", "prep_cost_per_hour", "prep_time_minutes", "printer_id", "times_printed", "units", "updated_at", "user_id", "vat_percentage" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "invoices", "plates", "printer", "user" ]
  end

  def total_printing_time_minutes
    plates.sum(&:total_printing_time_minutes)
  end

  def total_material_cost
    base_cost = plates.sum(&:total_material_cost)
    apply_failure_rate(base_cost)
  end

  # Alias for backward compatibility
  def total_filament_cost
    total_material_cost
  end

  def total_electricity_cost
    return 0 unless printer&.power_consumption && default_energy_cost_per_kwh
    base_cost = (printer.power_consumption * total_printing_time_minutes / 60 / 1000) * default_energy_cost_per_kwh
    apply_failure_rate(base_cost)
  end

  def total_labor_cost
    prep_cost = prep_time_minutes && prep_cost_per_hour ?
                (prep_time_minutes * prep_cost_per_hour / 60) : 0
    post_cost = postprocessing_time_minutes && postprocessing_cost_per_hour ?
                (postprocessing_time_minutes * postprocessing_cost_per_hour / 60) : 0
    prep_cost + post_cost
  end

  def total_machine_upkeep_cost
    return 0 unless printer&.cost && printer&.payoff_goal_years && printer&.daily_usage_hours

    total_days = printer.payoff_goal_years * 365
    daily_depreciation = printer.cost / total_days
    hourly_depreciation = daily_depreciation / printer.daily_usage_hours

    repair_cost_factor = 1 + (printer.repair_cost_percentage || 0) / 100
    base_cost = hourly_depreciation * (total_printing_time_minutes / 60) * repair_cost_factor

    apply_failure_rate(base_cost)
  end

  def total_listing_cost
    subtotal = calculate_subtotal
    (listing_cost_percentage || user.default_listing_cost_percentage || 0) * subtotal / 100
  end

  def total_payment_processing_cost
    subtotal = calculate_subtotal
    (payment_processing_cost_percentage || user.default_payment_processing_cost_percentage || 0) * subtotal / 100
  end

  def calculate_subtotal
    total_material_cost + total_electricity_cost + total_labor_cost +
    total_machine_upkeep_cost + (other_costs || 0)
  end

  def total_actual_print_time_minutes
    (times_printed || 0) * total_printing_time_minutes
  end

  def increment_times_printed!
    update!(times_printed: (times_printed || 0) + 1)
  end

  def decrement_times_printed!
    new_count = [ (times_printed || 0) - 1, 0 ].max
    update!(times_printed: new_count)
  end

  def per_unit_price
    return 0 if units.nil? || units.zero?
    return 0 if final_price.nil?
    final_price / units
  end

  def three_mf_file_attached_and_pending?
    three_mf_file.attached? && (three_mf_import_status.nil? || three_mf_import_status == "pending")
  end

  def three_mf_processing?
    three_mf_import_status == "processing"
  end

  def three_mf_completed?
    three_mf_import_status == "completed"
  end

  def three_mf_failed?
    three_mf_import_status == "failed"
  end

  private

  def process_three_mf_file
    update_column(:three_mf_import_status, "pending")
    Process3mfFileJob.perform_later(id)
  end

  def apply_failure_rate(cost)
    return cost if failure_rate_percentage.nil? || failure_rate_percentage.zero?
    cost * (1 + failure_rate_percentage / 100)
  end

  def calculate_final_price
    subtotal = calculate_subtotal
    listing_cost = total_listing_cost
    payment_cost = total_payment_processing_cost
    subtotal_with_fees = subtotal + listing_cost + payment_cost
    vat_amount = subtotal_with_fees * (vat_percentage || user.default_vat_percentage || 0) / 100
    self.final_price = subtotal_with_fees + vat_amount
  end

  def must_have_at_least_one_plate
    if plates.reject(&:marked_for_destruction?).empty?
      errors.add(:base, :no_plates)
    end
  end

  def cannot_have_more_than_ten_plates
    if plates.reject(&:marked_for_destruction?).size > 10
      errors.add(:base, :too_many_plates)
    end
  end

  def three_mf_file_format
    return unless three_mf_file.attached?

    unless three_mf_file.content_type.in?([ "application/x-3mf", "application/vnd.ms-package.3dmanufacturing-3dmodel+xml", "application/zip" ]) ||
           three_mf_file.filename.to_s.ends_with?(".3mf")
      errors.add(:three_mf_file, :invalid_format)
    end
  end
end
