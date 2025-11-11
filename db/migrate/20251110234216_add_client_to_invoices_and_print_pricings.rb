class AddClientToInvoicesAndPrintPricings < ActiveRecord::Migration[8.0]
  def change
    add_reference :invoices, :client, foreign_key: true, null: true
    add_reference :print_pricings, :client, foreign_key: true, null: true
  end
end
