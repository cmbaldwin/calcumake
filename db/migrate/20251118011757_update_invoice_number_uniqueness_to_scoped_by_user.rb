class UpdateInvoiceNumberUniquenessToScopedByUser < ActiveRecord::Migration[8.1]
  def change
    # Remove the old application-wide unique index
    remove_index :invoices, :invoice_number if index_exists?(:invoices, :invoice_number)

    # Add a new composite unique index scoped to user_id
    add_index :invoices, [ :user_id, :invoice_number ], unique: true
  end
end
