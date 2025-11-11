class AddListingAndPaymentCostsToPrintPricings < ActiveRecord::Migration[8.0]
  def change
    add_column :print_pricings, :listing_cost_percentage, :decimal, precision: 5, scale: 2
    add_column :print_pricings, :payment_processing_cost_percentage, :decimal, precision: 5, scale: 2
  end
end
