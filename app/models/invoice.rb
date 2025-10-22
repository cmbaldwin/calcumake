class Invoice < ApplicationRecord
  belongs_to :print_pricing
  belongs_to :user
  has_many :invoice_line_items, -> { order(:order_position) }, dependent: :destroy
  has_one_attached :company_logo

  accepts_nested_attributes_for :invoice_line_items, allow_destroy: true, reject_if: :all_blank

  # Validations
  validates :invoice_number, presence: true, uniqueness: true
  validates :invoice_date, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft sent paid cancelled] }
  validates :currency, presence: true

  # Callbacks
  before_validation :generate_invoice_number, on: :create, if: -> { invoice_number.blank? }
  before_validation :set_defaults, on: :create

  # Scopes
  scope :draft, -> { where(status: "draft") }
  scope :sent, -> { where(status: "sent") }
  scope :paid, -> { where(status: "paid") }
  scope :cancelled, -> { where(status: "cancelled") }
  scope :recent, -> { order(invoice_date: :desc) }

  # Instance methods
  def subtotal
    invoice_line_items.sum(:total_price)
  end

  def total
    subtotal
  end

  def overdue?
    due_date.present? && due_date < Date.current && status != "paid"
  end

  def mark_as_sent!
    update(status: "sent")
  end

  def mark_as_paid!
    update(status: "paid")
  end

  def mark_as_cancelled!
    update(status: "cancelled")
  end

  private

  def generate_invoice_number
    last_invoice = Invoice.where(user: user).order(created_at: :desc).first
    if last_invoice && last_invoice.invoice_number =~ /INV-(\d+)/
      number = $1.to_i + 1
    else
      number = 1
    end
    self.invoice_number = "INV-#{number.to_s.rjust(6, '0')}"
  end

  def set_defaults
    self.invoice_date ||= Date.current
    self.currency ||= user&.default_currency || print_pricing&.default_currency || "USD"
    self.status ||= "draft"

    # Set company details from user defaults if not provided
    self.company_name ||= user&.default_company_name
    self.company_address ||= user&.default_company_address
    self.company_email ||= user&.default_company_email || user&.email
    self.company_phone ||= user&.default_company_phone
    self.payment_details ||= user&.default_payment_details
    self.notes ||= user&.default_invoice_notes
  end
end
