class AddUnitsAndFailureRateToPrintPricings < ActiveRecord::Migration[8.1]
  def change
    add_column :print_pricings, :units, :integer, default: 1, null: false
    add_column :print_pricings, :failure_rate_percentage, :decimal, precision: 5, scale: 2, default: 5.0
  end
end
