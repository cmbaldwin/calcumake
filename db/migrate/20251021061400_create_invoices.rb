class CreateInvoices < ActiveRecord::Migration[8.0]
  def change
    create_table :invoices do |t|
      t.references :print_pricing, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :company_name
      t.text :company_address
      t.string :company_email
      t.string :company_phone
      t.text :payment_details
      t.text :notes
      t.string :invoice_number, null: false
      t.date :invoice_date, null: false
      t.date :due_date
      t.string :status, null: false, default: "draft"
      t.string :currency, null: false, default: "USD"

      t.timestamps
    end

    add_index :invoices, :invoice_number, unique: true
    add_index :invoices, :status
  end
end
