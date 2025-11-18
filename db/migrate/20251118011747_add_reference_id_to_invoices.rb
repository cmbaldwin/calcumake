class AddReferenceIdToInvoices < ActiveRecord::Migration[8.1]
  def change
    add_column :invoices, :reference_id, :string
    add_index :invoices, :reference_id, unique: true
  end
end
