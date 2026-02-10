require "test_helper"
require "zip"

class Process3mfFileJobTest < ActiveJob::TestCase
  setup do
    @job = Process3mfFileJob.new
  end

  test "returns early when parser is unavailable" do
    print_pricing = print_pricings(:one)

    if @job.send(:parser_available?)
      assert_raises(RuntimeError) do
        @job.perform(print_pricing.id)
      end
    else
      assert_nothing_raised do
        @job.perform(print_pricing.id)
      end
    end
  end

  test "returns when print pricing is missing" do
    assert_nothing_raised do
      @job.perform(-1)
    end
  end

  test "sample fixtures are valid 3mf zip files" do
    [ "sample_fdm.3mf", "sample_resin.3mf" ].each do |fixture_name|
      file_path = file_fixture(fixture_name)

      Zip::File.open(file_path.to_s) do |zip_file|
        assert zip_file.find_entry("3D/3dmodel.model"),
               "#{fixture_name} should contain 3D/3dmodel.model"
        assert zip_file.find_entry("_rels/.rels"),
               "#{fixture_name} should contain _rels/.rels"
      end
    end
  end
end
