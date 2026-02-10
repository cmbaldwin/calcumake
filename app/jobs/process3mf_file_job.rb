class Process3mfFileJob < ApplicationJob
  queue_as :default

  MAX_PARSE_RETRIES = 3

  def perform(print_pricing_id)
    print_pricing = PrintPricing.find_by(id: print_pricing_id)
    return unless print_pricing

    # Parser implementation is landed separately; keep this job safe to run before that step.
    unless parser_available?
      Rails.logger.info("[Process3mfFileJob] ThreeMfParser is not available yet; skipping PrintPricing ##{print_pricing_id}")
      return
    end

    update_import_status(print_pricing, "processing")
    temp_file = download_file(print_pricing)
    metadata = parse_file(temp_file.path)
    apply_metadata_to_pricing(print_pricing, metadata)
    update_import_status(print_pricing, "completed", nil)
  rescue StandardError => e
    handle_failure(print_pricing, e)
  ensure
    cleanup_temp_file(temp_file)
  end

  private

  def parser_available?
    defined?(ThreeMfParser)
  end

  def parse_file(file_path)
    ThreeMfParser.new(file_path).parse
  end

  def download_file(print_pricing)
    attachment = print_pricing.respond_to?(:three_mf_file) ? print_pricing.three_mf_file : nil
    raise "No 3MF file attached for PrintPricing ##{print_pricing.id}" unless attachment&.attached?

    temp_file = Tempfile.new([ "3mf_import", ".3mf" ])
    attachment.download { |chunk| temp_file.write(chunk) }
    temp_file.rewind
    temp_file
  end

  def apply_metadata_to_pricing(print_pricing, metadata)
    plate = print_pricing.plates.first || print_pricing.plates.build
    material_technology = metadata[:material_technology].presence || "fdm"
    plate.material_technology = material_technology

    if metadata[:print_time].present?
      total_minutes = metadata[:print_time].to_f
      plate.printing_time_hours = (total_minutes / 60).to_i
      plate.printing_time_minutes = (total_minutes % 60).to_i
    end

    plate.save! if plate.new_record?

    if material_technology == "resin" && metadata[:resin_volume_ml].present?
      apply_resin_data(plate, metadata)
    elsif metadata[:filament_weight].present?
      apply_filament_data(plate, metadata)
    end

    plate.save!
    print_pricing.save!
  end

  def apply_filament_data(plate, metadata)
    filament = find_matching_filament(plate.user, metadata[:material_type])
    return unless filament

    plate_filament = plate.plate_filaments.first || plate.plate_filaments.build
    plate_filament.filament = filament
    plate_filament.filament_weight = metadata[:filament_weight].to_f
    plate_filament.save!
  end

  def apply_resin_data(plate, metadata)
    resin = find_matching_resin(plate.user, metadata[:resin_type] || metadata[:material_type])
    return unless resin

    plate_resin = plate.plate_resins.first || plate.plate_resins.build
    plate_resin.resin = resin
    plate_resin.resin_volume_ml = metadata[:resin_volume_ml].to_f
    plate_resin.save!
  end

  def find_matching_filament(user, material_type)
    normalized_type = material_type.to_s.strip

    user.filaments.find_by("material_type ILIKE ?", normalized_type) ||
      user.filaments.find_by("material_type ILIKE ?", "%#{normalized_type}%") ||
      user.filaments.first
  end

  def find_matching_resin(user, resin_type)
    normalized_type = resin_type.to_s.strip

    user.resins.find_by("resin_type ILIKE ?", normalized_type) ||
      user.resins.find_by("resin_type ILIKE ?", "%#{normalized_type}%") ||
      user.resins.find_by("name ILIKE ?", "%#{normalized_type}%") ||
      user.resins.first
  end

  def handle_failure(print_pricing, error)
    update_import_status(print_pricing, "failed", error.message) if print_pricing

    if parse_error?(error) && executions < MAX_PARSE_RETRIES
      retry_job wait: 5.seconds
      return
    end

    raise error
  end

  def parse_error?(error)
    return false unless defined?(ThreeMfParser::ParseError)

    error.is_a?(ThreeMfParser::ParseError)
  end

  def update_import_status(print_pricing, status, error_message = nil)
    return unless print_pricing.respond_to?(:three_mf_import_status)

    attrs = { three_mf_import_status: status }
    attrs[:three_mf_import_error] = error_message if print_pricing.respond_to?(:three_mf_import_error)
    print_pricing.update_columns(attrs)
  end

  def cleanup_temp_file(temp_file)
    return unless temp_file

    temp_file.close
    temp_file.unlink
  end
end
