class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :print_pricings, dependent: :destroy
  has_many :printers, dependent: :destroy
  has_many :invoices, dependent: :destroy
  has_one_attached :company_logo

  validates :default_currency, presence: true
  validates :default_energy_cost_per_kwh, presence: true, numericality: { greater_than: 0 }
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, allow_blank: true
  validates :next_invoice_number, presence: true, numericality: { greater_than: 0, only_integer: true }

  before_validation :set_default_locale, on: :create
  before_validation :set_default_next_invoice_number, on: :create

  # Synchronize invoice counter with existing invoices
  def synchronize_invoice_counter!
    max_invoice_number = invoices.joins("").where("invoice_number ~ '^INV-[0-9]+$'")
                                .maximum("CAST(SUBSTRING(invoice_number FROM 5) AS INTEGER)")
    correct_next_number = (max_invoice_number || 0) + 1
    update!(next_invoice_number: correct_next_number)
  end

  private

  def set_default_locale
    self.locale ||= "en"
  end

  def set_default_next_invoice_number
    self.next_invoice_number ||= 1
  end
end
