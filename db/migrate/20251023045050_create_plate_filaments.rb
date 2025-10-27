class CreatePlateFilaments < ActiveRecord::Migration[8.0]
  def change
    create_table :plate_filaments do |t|
      t.references :plate, null: false, foreign_key: true
      t.references :filament, null: false, foreign_key: true
      t.decimal :filament_weight, precision: 8, scale: 2, null: false

      t.timestamps
    end

    add_index :plate_filaments, [:plate_id, :filament_id], unique: true
  end
end
