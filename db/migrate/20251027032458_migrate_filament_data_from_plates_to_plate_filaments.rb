class MigrateFilamentDataFromPlatesToPlateFilaments < ActiveRecord::Migration[8.0]
  def up
    # Valid material types from Filament model
    valid_material_types = %w[PLA ABS PETG TPU ASA HIPS Nylon PC PVA Wood Metal Carbon]

    # First, check if any plates have old filament data
    plates_with_old_data = Plate.where.not(filament_weight: nil)

    if plates_with_old_data.any?
      say "Migrating #{plates_with_old_data.count} plates with old filament data..."

      plates_with_old_data.each do |plate|
        # Skip if this plate already has plate_filaments
        next if plate.plate_filaments.any?

        # Get the user to find or create a generic filament
        user = plate.print_pricing.user
        raw_filament_type = plate.filament_type.to_s.strip

        # Normalize the filament type to match valid types
        filament_type = valid_material_types.find { |type| type.casecmp?(raw_filament_type) } || "PLA"

        # Find or create a generic filament for this material type
        filament = user.filaments.find_or_create_by!(
          name: "Migrated #{filament_type}",
          material_type: filament_type
        ) do |f|
          # Set cost per gram from spool price if available
          if plate.spool_price.present? && plate.spool_weight.present? && plate.spool_weight > 0
            f.spool_price = plate.spool_price
            f.spool_weight = plate.spool_weight
          else
            f.spool_price = 20 # Default price
            f.spool_weight = 1000 # 1kg default
          end
          f.diameter = 1.75 # Default diameter
        end

        # Create plate_filament record with the old filament_weight
        if plate.filament_weight.present? && plate.filament_weight > 0
          PlateFilament.create!(
            plate: plate,
            filament: filament,
            filament_weight: plate.filament_weight
          )
          say "  Migrated plate #{plate.id} with #{plate.filament_weight}g of #{filament_type}", true
        end
      end
    else
      say "No plates with old filament data found. Skipping migration."
    end

    # Remove old columns from plates table
    remove_column :plates, :filament_weight, :decimal
    remove_column :plates, :filament_type, :string
    remove_column :plates, :spool_price, :decimal
    remove_column :plates, :spool_weight, :decimal
    remove_column :plates, :markup_percentage, :decimal

    say "Removed old filament columns from plates table"
  end

  def down
    # Re-add the columns
    add_column :plates, :filament_weight, :decimal
    add_column :plates, :filament_type, :string
    add_column :plates, :spool_price, :decimal
    add_column :plates, :spool_weight, :decimal
    add_column :plates, :markup_percentage, :decimal

    say "Re-added old filament columns to plates table"
    say "Note: Data migration cannot be reversed. Old data is lost."
  end
end
