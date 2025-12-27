class AddMaterialTechnologyToPlates < ActiveRecord::Migration[8.1]
  def change
    add_column :plates, :material_technology, :string, default: 'fdm', null: false
    add_index :plates, :material_technology
  end
end
