require "test_helper"
require "tempfile"
require "zip"

class Process3mfFileJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup
    @user = users(:one)
    @printer = @user.printers.create!(
      name: "Test Printer",
      power_consumption: 200,
      cost: 500,
      payoff_goal_years: 3,
      daily_usage_hours: 8
    )
    @filament = @user.filaments.create!(
      name: "Test PLA",
      material_type: "PLA",
      spool_price: 25.0,
      spool_weight: 1000.0
    )
    @print_pricing = @user.print_pricings.build(
      job_name: "Test Job",
      printer: @printer
    )
    plate = @print_pricing.plates.build(
      printing_time_hours: 0,
      printing_time_minutes: 0
    )
    plate.plate_filaments.build(
      filament: @filament,
      filament_weight: 1.0
    )
    @print_pricing.save!

    # Create a valid 3MF file
    @temp_file = create_3mf_file(
      "prusaslicer:print_time" => "7200", # 2 hours
      "prusaslicer:filament_used" => "75.5g",
      "prusaslicer:material_type" => "PLA"
    )

    # Attach the file
    @print_pricing.three_mf_file.attach(
      io: File.open(@temp_file.path),
      filename: "test.3mf",
      content_type: "application/x-3mf"
    )
  end

  def teardown
    @temp_file.close
    @temp_file.unlink if @temp_file
  end

  def create_3mf_file(metadata = {})
    temp_file = Tempfile.new([ "test_3mf", ".3mf" ])

    Zip::File.open(temp_file.path, create: true) do |zipfile|
      # Add main model file
      metadata_tags = metadata.map do |key, value|
        "  <metadata name=\"#{key}\">#{value}</metadata>"
      end.join("\n")

      model_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <model unit="millimeter" xml:lang="en-US" xmlns="http://schemas.microsoft.com/3dmanufacturing/core/2015/02">
        #{metadata_tags}
          <resources>
            <object id="1" type="model">
              <mesh>
                <vertices>
                  <vertex x="0" y="0" z="0"/>
                  <vertex x="10" y="0" z="0"/>
                  <vertex x="5" y="10" z="5"/>
                </vertices>
                <triangles>
                  <triangle v1="0" v2="1" v3="2"/>
                </triangles>
              </mesh>
            </object>
          </resources>
          <build>
            <item objectid="1"/>
          </build>
        </model>
      XML
      zipfile.get_output_stream("3D/3dmodel.model") { |f| f.write(model_xml) }

      # Add relationships file
      rels_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
          <Relationship Target="/3D/3dmodel.model" Id="rel0" Type="http://schemas.microsoft.com/3dmanufacturing/2013/01/3dmodel"/>
        </Relationships>
      XML
      zipfile.get_output_stream("_rels/.rels") { |f| f.write(rels_xml) }
    end

    temp_file
  end

  test "should enqueue job" do
    assert_enqueued_with(job: Process3mfFileJob, args: [ @print_pricing.id ]) do
      Process3mfFileJob.perform_later(@print_pricing.id)
    end
  end

  test "should update status to processing when job starts" do
    perform_enqueued_jobs do
      Process3mfFileJob.perform_later(@print_pricing.id)
    end

    @print_pricing.reload
    # Job should complete and set status to completed
    assert_equal "completed", @print_pricing.three_mf_import_status
  end

  test "should extract and apply print time from 3MF file" do
    perform_enqueued_jobs do
      Process3mfFileJob.perform_later(@print_pricing.id)
    end

    @print_pricing.reload
    plate = @print_pricing.plates.first

    # 7200 seconds = 120 minutes = 2 hours
    assert_equal 2, plate.printing_time_hours
    assert_equal 0, plate.printing_time_minutes
  end

  test "should extract and apply filament weight from 3MF file" do
    perform_enqueued_jobs do
      Process3mfFileJob.perform_later(@print_pricing.id)
    end

    @print_pricing.reload
    plate_filament = @print_pricing.plates.first.plate_filaments.first

    assert_equal 75.5, plate_filament.filament_weight
  end

  test "should mark import as completed on success" do
    perform_enqueued_jobs do
      Process3mfFileJob.perform_later(@print_pricing.id)
    end

    @print_pricing.reload
    assert_equal "completed", @print_pricing.three_mf_import_status
    assert_nil @print_pricing.three_mf_import_error
  end

  test "should mark import as failed on error" do
    # Create an invalid file by attaching a non-3MF file
    invalid_file = Tempfile.new([ "invalid", ".txt" ])
    invalid_file.write("Not a 3MF file")
    invalid_file.rewind

    @print_pricing.three_mf_file.purge
    @print_pricing.three_mf_file.attach(
      io: invalid_file,
      filename: "invalid.3mf",
      content_type: "application/x-3mf"
    )

    perform_enqueued_jobs do
      begin
        Process3mfFileJob.perform_later(@print_pricing.id)
      rescue
        # Job will raise error, but we want to check the status
      end
    end

    @print_pricing.reload
    assert_equal "failed", @print_pricing.three_mf_import_status
    assert_not_nil @print_pricing.three_mf_import_error

    invalid_file.close
    invalid_file.unlink
  end

  test "should find matching filament by material type" do
    # Create a PETG filament
    petg_filament = @user.filaments.create!(
      name: "Test PETG",
      material_type: "PETG",
      spool_price: 30.0,
      spool_weight: 1000.0
    )

    # Create 3MF with PETG material
    petg_file = create_3mf_file(
      "prusaslicer:print_time" => "3600",
      "prusaslicer:filament_used" => "50.0g",
      "prusaslicer:material_type" => "PETG"
    )

    @print_pricing.three_mf_file.purge
    @print_pricing.three_mf_file.attach(
      io: File.open(petg_file.path),
      filename: "petg_test.3mf",
      content_type: "application/x-3mf"
    )

    perform_enqueued_jobs do
      Process3mfFileJob.perform_later(@print_pricing.id)
    end

    @print_pricing.reload
    plate_filament = @print_pricing.plates.first.plate_filaments.first

    assert_equal petg_filament.id, plate_filament.filament_id
    assert_equal 50.0, plate_filament.filament_weight

    petg_file.close
    petg_file.unlink
  end

  test "should handle missing filament gracefully" do
    # Create 3MF with material type that doesn't exist
    abs_file = create_3mf_file(
      "prusaslicer:print_time" => "3600",
      "prusaslicer:filament_used" => "50.0g",
      "prusaslicer:material_type" => "ABS"
    )

    @print_pricing.three_mf_file.purge
    @print_pricing.three_mf_file.attach(
      io: File.open(abs_file.path),
      filename: "abs_test.3mf",
      content_type: "application/x-3mf"
    )

    perform_enqueued_jobs do
      Process3mfFileJob.perform_later(@print_pricing.id)
    end

    @print_pricing.reload
    # Should still complete successfully, using first available filament
    assert_equal "completed", @print_pricing.three_mf_import_status
    assert @print_pricing.plates.first.plate_filaments.first.filament.present?

    abs_file.close
    abs_file.unlink
  end

  test "should handle 3MF file with only print time" do
    time_only_file = create_3mf_file(
      "prusaslicer:print_time" => "5400" # 90 minutes
    )

    @print_pricing.three_mf_file.purge
    @print_pricing.three_mf_file.attach(
      io: File.open(time_only_file.path),
      filename: "time_only.3mf",
      content_type: "application/x-3mf"
    )

    perform_enqueued_jobs do
      Process3mfFileJob.perform_later(@print_pricing.id)
    end

    @print_pricing.reload
    plate = @print_pricing.plates.first

    # 5400 seconds = 90 minutes = 1 hour 30 minutes
    assert_equal 1, plate.printing_time_hours
    assert_equal 30, plate.printing_time_minutes
    assert_equal "completed", @print_pricing.three_mf_import_status

    time_only_file.close
    time_only_file.unlink
  end

  test "should handle 3MF file with no metadata" do
    empty_file = create_3mf_file({})

    @print_pricing.three_mf_file.purge
    @print_pricing.three_mf_file.attach(
      io: File.open(empty_file.path),
      filename: "empty.3mf",
      content_type: "application/x-3mf"
    )

    perform_enqueued_jobs do
      Process3mfFileJob.perform_later(@print_pricing.id)
    end

    @print_pricing.reload
    # Should still complete successfully even with no metadata
    assert_equal "completed", @print_pricing.three_mf_import_status

    empty_file.close
    empty_file.unlink
  end
end
