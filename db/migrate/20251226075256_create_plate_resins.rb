class CreatePlateResins < ActiveRecord::Migration[8.1]
  def change
    create_table :plate_resins do |t|
      t.references :plate, null: false, foreign_key: true
      t.references :resin, null: false, foreign_key: true
      t.decimal :resin_volume_ml, precision: 10, scale: 2, null: false
      t.decimal :markup_percentage, precision: 5, scale: 2, default: 20.0

      t.timestamps
    end

    add_index :plate_resins, [ :plate_id, :resin_id ], unique: true
  end
end
