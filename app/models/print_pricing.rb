class PrintPricing < ApplicationRecord
  belongs_to :user, touch: true
  belongs_to :printer, optional: true
  belongs_to :client, optional: true
  has_many :plates, dependent: :destroy
  has_many :invoices, dependent: :destroy

  accepts_nested_attributes_for :plates, allow_destroy: true, reject_if: :all_blank

  validates :job_name, presence: true
  validates :times_printed, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :listing_cost_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validates :payment_processing_cost_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }, allow_nil: true
  validate :must_have_at_least_one_plate
  validate :cannot_have_more_than_ten_plates

  before_save :calculate_final_price

  include CurrencyHelper

  delegate :default_currency, :default_energy_cost_per_kwh, to: :user

  scope :search, ->(query) do
    return all if query.blank?

    where("job_name ILIKE ?", "%#{sanitize_sql_like(query)}%")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "final_price", "id", "id_value", "job_name", "other_costs", "postprocessing_cost_per_hour", "postprocessing_time_minutes", "prep_cost_per_hour", "prep_time_minutes", "printer_id", "times_printed", "updated_at", "user_id", "vat_percentage" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "invoices", "plates", "printer", "user" ]
  end

  def total_printing_time_minutes
    plates.sum(&:total_printing_time_minutes)
  end

  def total_filament_cost
    plates.sum(&:total_filament_cost)
  end

  def total_electricity_cost
    return 0 unless printer&.power_consumption && default_energy_cost_per_kwh
    (printer.power_consumption * total_printing_time_minutes / 60 / 1000) * default_energy_cost_per_kwh
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
    depreciation_cost = hourly_depreciation * (total_printing_time_minutes / 60) * repair_cost_factor

    depreciation_cost
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
    total_filament_cost + total_electricity_cost + total_labor_cost +
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

  private

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
end
