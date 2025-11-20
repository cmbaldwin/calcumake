class Printer < ApplicationRecord
  belongs_to :user, touch: true
  has_many :print_pricings, dependent: :destroy

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
