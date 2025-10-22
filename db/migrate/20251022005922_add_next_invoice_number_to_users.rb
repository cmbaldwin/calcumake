class AddNextInvoiceNumberToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :next_invoice_number, :integer, null: false, default: 1
  end
end
