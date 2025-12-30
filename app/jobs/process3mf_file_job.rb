class Process3mfFileJob < ApplicationJob
  queue_as :default

  retry_on ThreeMfParser::ParseError, wait: 5.seconds, attempts: 3

  def perform(print_pricing_id)
    print_pricing = PrintPricing.find(print_pricing_id)

    # Update status to processing
    print_pricing.update_column(:three_mf_import_status, "processing")

    # Download the file to a temporary location
    temp_file = download_file(print_pricing)

    begin
      # Parse the 3MF file
      parser = ThreeMfParser.new(temp_file.path)
      metadata = parser.parse

      # Apply the extracted data to the print pricing
      apply_metadata_to_pricing(print_pricing, metadata)

      # Mark as completed
      print_pricing.update!(
        three_mf_import_status: "completed",
        three_mf_import_error: nil
      )

      # Broadcast update via Turbo Stream if needed
      broadcast_completion(print_pricing)
    rescue => e
      # Mark as failed and store error
      print_pricing.update!(
        three_mf_import_status: "failed",
        three_mf_import_error: e.message
      )

      # Re-raise for retry mechanism
      raise
    ensure
      # Clean up temporary file
      temp_file.close
      temp_file.unlink
    end
  end

  private

  def download_file(print_pricing)
    # Download the ActiveStorage file to a temporary location
    temp_file = Tempfile.new([ "3mf_import", ".3mf" ])
    print_pricing.three_mf_file.download do |chunk|
      temp_file.write(chunk)
    end
    temp_file.rewind
    temp_file
  end

  def apply_metadata_to_pricing(print_pricing, metadata)
    # Create or update the first plate with extracted data
    plate = print_pricing.plates.first || print_pricing.plates.build

    # Set material technology based on detected type
    material_tech = metadata[:material_technology] || "fdm"
    plate.material_technology = material_tech

    # Apply print time if available
    if metadata[:print_time].present?
      total_minutes = metadata[:print_time].to_f
      plate.printing_time_hours = (total_minutes / 60).to_i
      plate.printing_time_minutes = (total_minutes % 60).to_i
    end

    # Save the plate first to ensure it exists
    plate.save! if plate.new_record?

    # Apply material data based on technology type
    if material_tech == "resin" && metadata[:resin_volume_ml].present?
      apply_resin_data(plate, metadata)
    elsif metadata[:filament_weight].present?
      apply_filament_data(plate, metadata)
    end

    # Store additional metadata as JSON in a future enhancement
    # For now, we'll just use the basic fields
    plate.save!

    # Recalculate the print pricing
    print_pricing.save!
  end

  def apply_filament_data(plate, metadata)
    weight = metadata[:filament_weight].to_f
    material_type = metadata[:material_type] || "PLA"

    # Try to find an existing filament of this type for the user
    filament = find_or_suggest_filament(plate.user, material_type)

    if filament
      # Create or update the plate filament
      plate_filament = plate.plate_filaments.first || plate.plate_filaments.build
      plate_filament.filament = filament
      plate_filament.filament_weight = weight
      plate_filament.save!
    else
      # If no matching filament found, store the weight in a note or custom field
      # For now, we'll just skip it and log a warning
      Rails.logger.warn("No matching filament found for material type: #{material_type}")
    end
  end

  def find_or_suggest_filament(user, material_type)
    # Try to find a filament matching the material type
    user.filaments.find_by("material_type ILIKE ?", "%#{material_type}%") ||
    user.filaments.where(material_type: material_type.upcase).first ||
    user.filaments.first # Fall back to first available filament
  end

  def apply_resin_data(plate, metadata)
    volume = metadata[:resin_volume_ml].to_f
    resin_type = metadata[:resin_type] || metadata[:material_type] || "Standard"

    # Try to find an existing resin of this type for the user
    resin = find_or_suggest_resin(plate.user, resin_type)

    if resin
      # Create or update the plate resin
      plate_resin = plate.plate_resins.first || plate.plate_resins.build
      plate_resin.resin = resin
      plate_resin.resin_volume_ml = volume
      plate_resin.save!
    else
      # If no matching resin found, log a warning
      Rails.logger.warn("No matching resin found for resin type: #{resin_type}")
    end
  end

  def find_or_suggest_resin(user, resin_type)
    # Try to find a resin matching the resin type
    # Check for exact match first
    user.resins.find_by("resin_type ILIKE ?", "%#{resin_type}%") ||
    user.resins.where(resin_type: resin_type).first ||
    # Try to match on name
    user.resins.find_by("name ILIKE ?", "%#{resin_type}%") ||
    user.resins.first # Fall back to first available resin
  end

  def broadcast_completion(print_pricing)
    # Broadcast a Turbo Stream update to notify the user
    # This would require a Turbo Stream broadcast channel
    # For now, we'll skip this and rely on polling or page refresh
  end
end
