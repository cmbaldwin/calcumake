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

  def self.ransackable_attributes(auth_object = nil)
    [ "company_name", "created_at", "currency", "due_date", "id", "invoice_date", "invoice_number", "notes", "status", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "print_pricing" ]
  end

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

  def build_default_line_items
    return unless print_pricing

    position = 0

    # Filament cost line items (one per plate)
    print_pricing.plates.each_with_index do |plate, index|
      invoice_line_items.build(
        description: "Plate #{index + 1}: #{plate.total_filament_weight.round(1)}g #{plate.filament_types}",
        quantity: 1,
        unit_price: plate.total_filament_cost,
        line_item_type: "filament",
        order_position: position
      )
      position += 1
    end

    # Electricity cost
    if print_pricing.total_electricity_cost > 0
      invoice_line_items.build(
        description: I18n.t("print_pricing.electricity_cost"),
        quantity: 1,
        unit_price: print_pricing.total_electricity_cost,
        line_item_type: "electricity",
        order_position: position
      )
      position += 1
    end

    # Labor costs
    if print_pricing.total_labor_cost > 0
      invoice_line_items.build(
        description: I18n.t("print_pricing.labor_cost"),
        quantity: 1,
        unit_price: print_pricing.total_labor_cost,
        line_item_type: "labor",
        order_position: position
      )
      position += 1
    end

    # Machine upkeep
    if print_pricing.total_machine_upkeep_cost > 0
      invoice_line_items.build(
        description: I18n.t("print_pricing.machine_upkeep"),
        quantity: 1,
        unit_price: print_pricing.total_machine_upkeep_cost,
        line_item_type: "machine",
        order_position: position
      )
      position += 1
    end

    # Other costs
    if print_pricing.other_costs && print_pricing.other_costs > 0
      invoice_line_items.build(
        description: I18n.t("print_pricing.other_costs"),
        quantity: 1,
        unit_price: print_pricing.other_costs,
        line_item_type: "other",
        order_position: position
      )
    end
  end

  private

  def generate_invoice_number
    return unless user # Skip if no user (for validations)

    # Use database transaction to ensure thread safety
    Invoice.transaction do
      # Lock the user record to prevent race conditions
      user.lock!

      # Get the next invoice number and increment it
      current_number = user.next_invoice_number || 1

      # Check if this number already exists and sync if needed
      proposed_number = "INV-#{current_number.to_s.rjust(6, '0')}"
      if Invoice.exists?(invoice_number: proposed_number)
        # Synchronize counter with existing invoices
        user.synchronize_invoice_counter!
        current_number = user.reload.next_invoice_number
      end

      user.update!(next_invoice_number: current_number + 1)

      # Format the invoice number with zero padding
      self.invoice_number = "INV-#{current_number.to_s.rjust(6, '0')}"
    end
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
