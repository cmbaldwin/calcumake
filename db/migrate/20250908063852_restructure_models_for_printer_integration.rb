class RestructureModelsForPrinterIntegration < ActiveRecord::Migration[8.0]
  def change
    # Add printer reference to print_pricings
    add_reference :print_pricings, :printer, null: true, foreign_key: true

    # Move printer-specific fields from print_pricings to printers
    # First add them to printers if they don't exist
    add_column :printers, :daily_usage_hours, :integer, default: 8 unless column_exists?(:printers, :daily_usage_hours)
    add_column :printers, :investment_return_years, :integer, default: 3 unless column_exists?(:printers, :investment_return_years)
    add_column :printers, :repair_cost_percentage, :decimal, precision: 8, scale: 2, default: 0 unless column_exists?(:printers, :repair_cost_percentage)

    # Remove printer-specific fields from print_pricings
    remove_column :print_pricings, :power_consumption, :decimal if column_exists?(:print_pricings, :power_consumption)
    remove_column :print_pricings, :printer_cost, :decimal if column_exists?(:print_pricings, :printer_cost)
    remove_column :print_pricings, :investment_return_years, :integer if column_exists?(:print_pricings, :investment_return_years)
    remove_column :print_pricings, :daily_usage_hours, :integer if column_exists?(:print_pricings, :daily_usage_hours)
    remove_column :print_pricings, :repair_cost_percentage, :decimal if column_exists?(:print_pricings, :repair_cost_percentage)

    # Remove currency and energy fields from print_pricings (these are now in users)
    remove_column :print_pricings, :currency, :string if column_exists?(:print_pricings, :currency)
    remove_column :print_pricings, :energy_cost_per_kwh, :decimal if column_exists?(:print_pricings, :energy_cost_per_kwh)
  end
end
