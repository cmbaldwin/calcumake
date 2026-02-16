class AddThreeMfImportToPrintPricings < ActiveRecord::Migration[8.1]
  def change
    add_column :print_pricings, :three_mf_import_status, :string
    add_column :print_pricings, :three_mf_import_error, :text
    add_index :print_pricings, :three_mf_import_status
  end
end
