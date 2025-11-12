class AddMarkupPercentageToPlateFilaments < ActiveRecord::Migration[8.1]
  def change
    add_column :plate_filaments, :markup_percentage, :decimal, precision: 5, scale: 2, default: 20.0
  end
end
