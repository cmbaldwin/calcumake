class Printer < ApplicationRecord
  belongs_to :user, touch: true
  has_many :print_pricings, dependent: :destroy

  # Material technology enum (matches Plate model)
  enum :material_technology, { fdm: "fdm", resin: "resin" }, default: :fdm

  MANUFACTURERS = [
    "Prusa",
    "Bambu Lab",
    "Creality",
    "Ender",
    "Ultimaker",
    "MakerBot",
    "Formlabs",
    "Anycubic",
    "Qidi Tech",
    "Artillery",
    "Elegoo",
    "Flashforge",
    "Raise3D",
    "Zortrax",
    "Lulzbot",
    "Markforged",
    "Stratasys",
    "XYZprinting",
    "Other"
  ].freeze

  COMMON_DEFAULTS = {
    "Prusa i3 MK4" => {
      manufacturer: "Prusa",
      power_consumption: 120,
      cost: 799,
      daily_usage_hours: 8,
      payoff_goal_years: 2,
      material_technology: "fdm"
    },
    "Bambu Lab P1P" => {
      manufacturer: "Bambu Lab",
      power_consumption: 350,
      cost: 699,
      daily_usage_hours: 8,
      payoff_goal_years: 2,
      material_technology: "fdm"
    },
    "Bambu Lab X1 Carbon" => {
      manufacturer: "Bambu Lab",
      power_consumption: 500,
      cost: 1199,
      daily_usage_hours: 8,
      payoff_goal_years: 2,
      material_technology: "fdm"
    },
    "Creality Ender 3 V3" => {
      manufacturer: "Creality",
      power_consumption: 270,
      cost: 249,
      daily_usage_hours: 8,
      payoff_goal_years: 1,
      material_technology: "fdm"
    },
    "Prusa Mini+" => {
      manufacturer: "Prusa",
      power_consumption: 75,
      cost: 459,
      daily_usage_hours: 8,
      payoff_goal_years: 1,
      material_technology: "fdm"
    },
    "Anycubic Kobra 2" => {
      manufacturer: "Anycubic",
      power_consumption: 300,
      cost: 299,
      daily_usage_hours: 8,
      payoff_goal_years: 1,
      material_technology: "fdm"
    }
  }.freeze

  validates :name, presence: true
  validates :power_consumption, :cost, :payoff_goal_years, :daily_usage_hours, presence: true
  validates :power_consumption, :cost, numericality: { greater_than: 0 }
  validates :payoff_goal_years, :daily_usage_hours, numericality: { greater_than: 0, only_integer: true }
  validates :repair_cost_percentage, numericality: { greater_than_or_equal_to: 0 }

  before_save :set_date_added

  def paid_off?
    return false unless date_added && payoff_goal_years
    Date.current >= date_added.to_date + payoff_goal_years.years
  end

  def months_to_payoff
    return 0 if paid_off?
    return nil unless date_added && payoff_goal_years

    target_date = date_added.to_date + payoff_goal_years.years
    ((target_date - Date.current) / 30.44).ceil
  end

  private

  def set_date_added
    self.date_added ||= Time.current
  end
end
