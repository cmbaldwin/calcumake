class AddThreeMfImportStatusToPrintPricings < ActiveRecord::Migration[8.1]
  def change
    add_column :print_pricings, :three_mf_import_status, :string
    add_column :print_pricings, :three_mf_import_error, :text
  end
end
