class AddMaterialTechnologyToPrinters < ActiveRecord::Migration[8.1]
  def change
    add_column :printers, :material_technology, :string, default: "fdm", null: false
    add_index :printers, :material_technology
  end
end
