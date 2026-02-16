#!/usr/bin/env ruby
# Manual Test Script for 3MF Import Feature
# Run with: bin/rails runner test_3mf_import.rb
# Or copy-paste into: bin/rails console

require "zip"

puts "\n" + "="*80
puts "3MF IMPORT FEATURE - MANUAL TEST SCRIPT"
puts "="*80

# Test 1: Verify fixtures are valid
puts "\n[TEST 1] Verifying test fixtures..."
fixtures = [
  Rails.root.join("test/fixtures/files/sample_fdm.3mf"),
  Rails.root.join("test/fixtures/files/sample_resin.3mf")
]

fixtures.each do |fixture_path|
  if File.exist?(fixture_path)
    puts "  ✓ Found: #{fixture_path.basename}"

    Zip::File.open(fixture_path) do |zip_file|
      has_model = zip_file.find_entry("3D/3dmodel.model").present?
      has_rels = zip_file.find_entry("_rels/.rels").present?

      puts "    - Contains 3D/3dmodel.model: #{has_model ? '✓' : '✗'}"
      puts "    - Contains _rels/.rels: #{has_rels ? '✓' : '✗'}"

      if has_model
        model_entry = zip_file.find_entry("3D/3dmodel.model")
        xml_content = model_entry.get_input_stream.read
        doc = Nokogiri::XML(xml_content)
        metadata_count = doc.xpath("//metadata").count
        puts "    - Metadata elements: #{metadata_count}"

        # Show first 3 metadata elements
        doc.xpath("//metadata").first(3).each do |node|
          puts "      - #{node['name']}: #{node.text[0..50]}"
        end
      end
    end
  else
    puts "  ✗ Missing: #{fixture_path.basename}"
  end
end

# Test 2: Test parser directly
puts "\n[TEST 2] Testing ThreeMfParser directly..."
fixture_path = Rails.root.join("test/fixtures/files/sample_fdm.3mf")

begin
  parser = ThreeMfParser.new(fixture_path.to_s)
  metadata = parser.parse

  puts "  ✓ Parser initialized and executed successfully"
  puts "\n  Extracted metadata:"
  metadata.each do |key, value|
    puts "    - #{key}: #{value.inspect}"
  end
rescue => e
  puts "  ✗ Parser failed: #{e.message}"
  puts "    #{e.backtrace.first(5).join("\n    ")}"
end

# Test 3: Test full workflow with job
puts "\n[TEST 3] Testing full workflow with background job..."

# Find or create test user
user = User.first
unless user
  puts "  ✗ No users found. Please create a user first."
  exit
end

puts "  Using user: #{user.email}"

# Create or find printer
printer = user.printers.first || user.printers.create!(
  name: "Test Printer (3MF Import)",
  power_watts: 100,
  purchase_price: 20000,
  cost: 20000,
  payoff_goal_years: 3,
  daily_usage_hours: 8
)
puts "  Using printer: #{printer.name}"

# Create or find filament
filament = user.filaments.find_by(material_type: "PLA") || user.filaments.create!(
  name: "PLA White (Test)",
  material_type: "PLA",
  price_per_kg: 2500
)
puts "  Using filament: #{filament.name} (#{filament.material_type})"

# Create print pricing with plate (using build to avoid validation issues)
print_pricing = user.print_pricings.build(
  job_name: "3MF Import Test - #{Time.current.to_i}",
  printer: printer,
  units: 1,
  prep_time_minutes: 10,
  prep_cost_per_hour: 1000,
  postprocessing_time_minutes: 15,
  postprocessing_cost_per_hour: 1000
)

# Build plate before saving
plate = print_pricing.plates.build(
  printing_time_hours: 0,
  printing_time_minutes: 0
)

# Add a minimal filament to pass validation (will be replaced by job)
plate_filament = plate.plate_filaments.build(
  filament: filament,
  filament_weight: 1
)

# Now save everything together
print_pricing.save!
puts "  ✓ Created PrintPricing ##{print_pricing.id}"
puts "  ✓ Created initial Plate ##{plate.id}"

# Attach 3MF file
puts "\n  Attaching 3MF file..."
file_path = Rails.root.join("test/fixtures/files/sample_fdm.3mf")
print_pricing.three_mf_file.attach(
  io: File.open(file_path),
  filename: "sample_fdm.3mf",
  content_type: "application/x-3mf"
)

if print_pricing.three_mf_file.attached?
  puts "  ✓ File attached successfully"
  puts "    - Filename: #{print_pricing.three_mf_file.filename}"
  puts "    - Size: #{print_pricing.three_mf_file.byte_size} bytes"
  puts "    - Content Type: #{print_pricing.three_mf_file.content_type}"
else
  puts "  ✗ File attachment failed"
  exit
end

# Check status before job
print_pricing.reload
puts "\n  Initial status: #{print_pricing.three_mf_import_status || 'nil'}"

# Run job synchronously
puts "\n  Running Process3mfFileJob..."
begin
  Process3mfFileJob.perform_now(print_pricing.id)
  puts "  ✓ Job completed"
rescue => e
  puts "  ✗ Job failed: #{e.message}"
  puts "    #{e.backtrace.first(5).join("\n    ")}"
end

# Check results
print_pricing.reload
plate.reload

puts "\n[TEST 4] Verifying results..."
puts "  Import Status: #{print_pricing.three_mf_import_status}"
puts "  Import Error: #{print_pricing.three_mf_import_error}" if print_pricing.three_mf_import_error

if print_pricing.three_mf_completed?
  puts "  ✓ Import completed successfully!"

  puts "\n  Plate data:"
  puts "    - Material Technology: #{plate.material_technology}"
  puts "    - Print Time: #{plate.printing_time_hours}h #{plate.printing_time_minutes}m"
  puts "    - Total Minutes: #{plate.total_printing_time_minutes}"

  if plate.material_technology == "fdm"
    puts "    - Filaments: #{plate.plate_filaments.count}"
    plate.plate_filaments.each do |pf|
      puts "      * #{pf.filament.name}: #{pf.filament_weight}g"
    end
  elsif plate.material_technology == "resin"
    puts "    - Resins: #{plate.plate_resins.count}"
    plate.plate_resins.each do |pr|
      puts "      * #{pr.resin.name}: #{pr.resin_volume_ml}ml"
    end
  end

  puts "\n  Print Pricing costs:"
  puts "    - Material Cost: ¥#{print_pricing.total_material_cost.round(2)}"
  puts "    - Electricity Cost: ¥#{print_pricing.total_electricity_cost.round(2)}"
  puts "    - Labor Cost: ¥#{print_pricing.total_labor_cost.round(2)}"
  puts "    - Machine Upkeep: ¥#{print_pricing.total_machine_upkeep_cost.round(2)}"
  puts "    - Final Price: ¥#{print_pricing.final_price.round(2)}"

elsif print_pricing.three_mf_failed?
  puts "  ✗ Import failed!"
  puts "    Error: #{print_pricing.three_mf_import_error}"
else
  puts "  ⚠ Import in unexpected state: #{print_pricing.three_mf_import_status}"
end

# Test 5: Test resin file
puts "\n[TEST 5] Testing resin 3MF file..."
resin_path = Rails.root.join("test/fixtures/files/sample_resin.3mf")

if File.exist?(resin_path)
  # Create or find resin
  resin = user.resins.first || user.resins.create!(
    name: "Standard Resin (Test)",
    resin_type: "Standard",
    price_per_liter: 3000
  )
  puts "  Using resin: #{resin.name} (#{resin.resin_type})"

  # Create new print pricing for resin
  resin_pricing = user.print_pricings.build(
    job_name: "3MF Resin Test - #{Time.current.to_i}",
    printer: printer,
    units: 1
  )

  resin_plate = resin_pricing.plates.build(
    printing_time_hours: 0,
    printing_time_minutes: 0
  )

  # Add minimal resin to pass validation
  resin_plate.plate_resins.build(
    resin: resin,
    resin_volume_ml: 1
  )

  resin_pricing.save!

  resin_pricing.three_mf_file.attach(
    io: File.open(resin_path),
    filename: "sample_resin.3mf",
    content_type: "application/x-3mf"
  )

  puts "  ✓ Resin file attached"

  Process3mfFileJob.perform_now(resin_pricing.id)

  resin_pricing.reload
  resin_plate.reload

  puts "  Import Status: #{resin_pricing.three_mf_import_status}"
  if resin_pricing.three_mf_completed?
    puts "  ✓ Resin import completed!"
    puts "    - Technology: #{resin_plate.material_technology}"
    puts "    - Resins: #{resin_plate.plate_resins.count}"
  else
    puts "  Status: #{resin_pricing.three_mf_import_status}"
    puts "  Error: #{resin_pricing.three_mf_import_error}" if resin_pricing.three_mf_import_error
  end
else
  puts "  ✗ Resin fixture not found"
end

puts "\n" + "="*80
puts "TESTING COMPLETE"
puts "="*80
puts "\nTo clean up test data, run:"
puts "  PrintPricing.where('job_name LIKE ?', '3MF%Test%').destroy_all"
puts "\n"
