class PrinterProfile < ApplicationRecord
  CATEGORIES = [
    "Budget FDM", "Mid-Range FDM", "Premium FDM", "Professional FDM", "Industrial FDM",
    "Budget Resin", "Mid-Range Resin", "Professional Resin", "Industrial Resin"
  ].freeze

  enum :technology, { fdm: "fdm", resin: "resin" }, default: :fdm

  validates :manufacturer, :model, presence: true
  validates :model, uniqueness: { scope: :manufacturer, case_sensitive: false }
  validates :technology, inclusion: { in: technologies.keys }
  validates :category, inclusion: { in: CATEGORIES }, allow_blank: true

  scope :by_technology, ->(tech) { where(technology: tech) }
  scope :search, ->(q) {
    where("manufacturer ILIKE :q OR model ILIKE :q OR category ILIKE :q", q: "%#{q}%")
  }

  def display_name
    "#{manufacturer} #{model}"
  end

  def full_display_name
    parts = [ manufacturer, model ]
    parts << "(#{category})" if category.present?
    parts.join(" ")
  end
end
