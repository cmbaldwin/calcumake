class PrintPricing < ApplicationRecord
  belongs_to :user
  belongs_to :printer, optional: true

  validates :job_name, presence: true
  validates :filament_type, presence: true
  validates :printing_time_hours, :printing_time_minutes, numericality: { greater_than_or_equal_to: 0 }
  validates :filament_weight, :spool_price, :spool_weight, :markup_percentage,
            numericality: { greater_than: 0 }

  before_save :calculate_final_price

  include CurrencyHelper

  delegate :default_currency, :default_energy_cost_per_kwh, to: :user

  def total_printing_time_minutes
    (printing_time_hours || 0) * 60 + (printing_time_minutes || 0)
  end

  def total_filament_cost
    return 0 unless filament_weight && spool_price && spool_weight
    (filament_weight * spool_price / spool_weight) * (1 + (markup_percentage || 0) / 100)
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

  def calculate_subtotal
    total_filament_cost + total_electricity_cost + total_labor_cost + 
    total_machine_upkeep_cost + (other_costs || 0)
  end

  private

  def calculate_final_price
    subtotal = calculate_subtotal
    vat_amount = subtotal * (vat_percentage || 0) / 100
    self.final_price = subtotal + vat_amount
  end
end
