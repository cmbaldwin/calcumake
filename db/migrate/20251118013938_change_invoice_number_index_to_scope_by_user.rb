class ChangeInvoiceNumberIndexToScopeByUser < ActiveRecord::Migration[8.1]
  def change
    # Remove the old unique index on invoice_number only
    remove_index :invoices, :invoice_number

    # Add a new composite unique index on [user_id, invoice_number]
    # This allows each user to have their own sequence of invoice numbers
    add_index :invoices, [ :user_id, :invoice_number ], unique: true
  end
end
