class AddInvoiceDefaultsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :default_company_name, :string
    add_column :users, :default_company_address, :text
    add_column :users, :default_company_email, :string
    add_column :users, :default_company_phone, :string
    add_column :users, :default_payment_details, :text
    add_column :users, :default_invoice_notes, :text
  end
end
