class AddListingAndPaymentCostsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :default_listing_cost_percentage, :decimal, precision: 5, scale: 2, default: 0.0
    add_column :users, :default_payment_processing_cost_percentage, :decimal, precision: 5, scale: 2, default: 0.0
  end
end
