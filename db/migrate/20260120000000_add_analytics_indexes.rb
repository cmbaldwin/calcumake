class AddAnalyticsIndexes < ActiveRecord::Migration[8.1]
  def change
    # Index for filtering print pricings by date and user
    add_index :print_pricings, [:user_id, :created_at], unless_exists: true

    # Index for filtering invoices by date and user
    add_index :invoices, [:user_id, :invoice_date], unless_exists: true
    add_index :invoices, [:user_id, :status], unless_exists: true

    # Index for aggregating plate data by date
    add_index :plates, :created_at, unless_exists: true

    # Index for client analytics
    add_index :print_pricings, [:client_id, :created_at], unless_exists: true
    add_index :invoices, [:client_id, :status], unless_exists: true
  end
end
