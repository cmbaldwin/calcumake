class RemoveUnwantedFilamentProperties < ActiveRecord::Migration[8.0]
  def change
    remove_column :filaments, :food_safe, :boolean
    remove_column :filaments, :recyclable, :boolean
  end
end
