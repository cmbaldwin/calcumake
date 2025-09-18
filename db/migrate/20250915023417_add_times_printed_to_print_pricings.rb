class AddTimesPrintedToPrintPricings < ActiveRecord::Migration[8.0]
  def change
    add_column :print_pricings, :times_printed, :integer, default: 0, null: false
    add_index :print_pricings, :times_printed
  end
end
