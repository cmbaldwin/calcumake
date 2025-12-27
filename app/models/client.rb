class Client < ApplicationRecord
  belongs_to :user, touch: true
  has_many :invoices, dependent: :nullify
  has_many :print_pricings, dependent: :nullify

  validates :name, presence: true

  scope :search, ->(q) {
    where("name ILIKE :q OR company_name ILIKE :q OR email ILIKE :q", q: "%#{q}%")
  }

  def self.ransackable_attributes(auth_object = nil)
    [ "name", "company_name", "email", "phone", "address", "tax_id", "notes", "created_at", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "user", "invoices", "print_pricings" ]
  end

  def display_name
    company_name.present? ? "#{company_name} (#{name})" : name
  end
end
