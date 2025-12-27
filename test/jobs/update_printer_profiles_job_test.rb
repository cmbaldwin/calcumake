require "test_helper"

class UpdatePrinterProfilesJobTest < ActiveJob::TestCase
  def setup
    @job = UpdatePrinterProfilesJob.new
  end

  test "skips execution when API key is not set" do
    # Clear API key if set
    original_key = ENV["OPENROUTER_TRANSLATION_KEY"]
    ENV["OPENROUTER_TRANSLATION_KEY"] = nil

    initial_count = PrinterProfile.count
    @job.perform

    assert_equal initial_count, PrinterProfile.count
  ensure
    ENV["OPENROUTER_TRANSLATION_KEY"] = original_key
  end

  test "normalize_technology returns fdm for FDM variants" do
    assert_equal "fdm", @job.send(:normalize_technology, "fdm")
    assert_equal "fdm", @job.send(:normalize_technology, "FDM")
    assert_equal "fdm", @job.send(:normalize_technology, "fff")
    assert_equal "fdm", @job.send(:normalize_technology, nil)
  end

  test "normalize_technology returns resin for resin variants" do
    assert_equal "resin", @job.send(:normalize_technology, "resin")
    assert_equal "resin", @job.send(:normalize_technology, "sla")
    assert_equal "resin", @job.send(:normalize_technology, "dlp")
    assert_equal "resin", @job.send(:normalize_technology, "msla")
    assert_equal "resin", @job.send(:normalize_technology, "lcd")
  end

  test "normalize_category returns valid category" do
    assert_equal "Budget FDM", @job.send(:normalize_category, "Budget FDM")
  end

  test "normalize_category handles case mismatch" do
    assert_equal "Budget FDM", @job.send(:normalize_category, "budget fdm")
  end

  test "normalize_category returns nil for blank" do
    assert_nil @job.send(:normalize_category, nil)
    assert_nil @job.send(:normalize_category, "")
  end

  test "parse_response extracts JSON from response" do
    response = {
      "choices" => [
        {
          "message" => {
            "content" => '[{"manufacturer":"Test","model":"Printer","technology":"fdm"}]'
          }
        }
      ]
    }

    result = @job.send(:parse_response, response)
    assert_equal 1, result.length
    assert_equal "Test", result[0][:manufacturer]
  end

  test "parse_response handles markdown-wrapped JSON" do
    response = {
      "choices" => [
        {
          "message" => {
            "content" => "```json\n[{\"manufacturer\":\"Test\",\"model\":\"Printer\"}]\n```"
          }
        }
      ]
    }

    result = @job.send(:parse_response, response)
    assert_equal 1, result.length
    assert_equal "Test", result[0][:manufacturer]
  end

  test "parse_response returns empty array for invalid JSON" do
    response = {
      "choices" => [
        {
          "message" => {
            "content" => "This is not valid JSON"
          }
        }
      ]
    }

    result = @job.send(:parse_response, response)
    assert_equal [], result
  end

  test "parse_response returns empty array for nil content" do
    response = { "choices" => [ { "message" => { "content" => nil } } ] }
    result = @job.send(:parse_response, response)
    assert_equal [], result
  end

  test "build_prompt includes existing manufacturers" do
    manufacturers = [ "Bambu Lab", "Prusa" ]
    models = [ "Bambu Lab P1S Combo", "Prusa i3 MK4" ]

    prompt = @job.send(:build_prompt, manufacturers, models)

    assert_includes prompt, "Bambu Lab"
    assert_includes prompt, "Prusa"
    assert_includes prompt, "EXISTING PRINTERS"
    assert_includes prompt, "2024-2025"
  end
end
