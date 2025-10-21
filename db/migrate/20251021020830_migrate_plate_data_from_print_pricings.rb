class MigratePlateDataFromPrintPricings < ActiveRecord::Migration[8.0]
  def up
    # Create a plate for each existing print_pricing with the current data
    PrintPricing.find_each do |pricing|
      pricing.plates.create!(
        printing_time_hours: pricing.printing_time_hours,
        printing_time_minutes: pricing.printing_time_minutes,
        filament_weight: pricing.filament_weight,
        filament_type: pricing.filament_type,
        spool_price: pricing.spool_price,
        spool_weight: pricing.spool_weight,
        markup_percentage: pricing.markup_percentage
      )
    end

    # Remove the columns from print_pricings table
    remove_column :print_pricings, :printing_time_hours
    remove_column :print_pricings, :printing_time_minutes
    remove_column :print_pricings, :filament_weight
    remove_column :print_pricings, :filament_type
    remove_column :print_pricings, :spool_price
    remove_column :print_pricings, :spool_weight
    remove_column :print_pricings, :markup_percentage
  end

  def down
    # Re-add the columns to print_pricings
    add_column :print_pricings, :printing_time_hours, :integer
    add_column :print_pricings, :printing_time_minutes, :integer
    add_column :print_pricings, :filament_weight, :decimal
    add_column :print_pricings, :filament_type, :string
    add_column :print_pricings, :spool_price, :decimal
    add_column :print_pricings, :spool_weight, :decimal
    add_column :print_pricings, :markup_percentage, :decimal

    # Migrate data back from first plate to print_pricing
    PrintPricing.find_each do |pricing|
      if pricing.plates.exists?
        first_plate = pricing.plates.first
        pricing.update_columns(
          printing_time_hours: first_plate.printing_time_hours,
          printing_time_minutes: first_plate.printing_time_minutes,
          filament_weight: first_plate.filament_weight,
          filament_type: first_plate.filament_type,
          spool_price: first_plate.spool_price,
          spool_weight: first_plate.spool_weight,
          markup_percentage: first_plate.markup_percentage
        )
      end
    end
  end
end
