require "test_helper"

class PrinterProfilesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @bambu = printer_profiles(:bambu_p1s)
    @elegoo = printer_profiles(:elegoo_mars)
    @prusa = printer_profiles(:prusa_mk4)
  end

  test "should get index without authentication" do
    get printer_profiles_url
    assert_response :success
  end

  test "should get index as JSON without authentication" do
    get printer_profiles_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert json.length >= 3 # At least our fixtures
  end

  test "JSON response includes expected fields" do
    get printer_profiles_url, as: :json

    json = JSON.parse(response.body)
    profile = json.find { |p| p["manufacturer"] == "Bambu Lab" }

    assert_not_nil profile
    assert_equal "Bambu Lab", profile["manufacturer"]
    assert_equal "P1S Combo", profile["model"]
    assert_equal "Bambu Lab P1S Combo", profile["display_name"]
    assert_equal "Mid-Range FDM", profile["category"]
    assert_equal "fdm", profile["technology"]
    assert_equal 100, profile["power_consumption_avg_watts"]
    assert_equal 549.0, profile["cost_usd"]
  end

  test "should filter by technology" do
    get printer_profiles_url, params: { technology: "resin" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    technologies = json.map { |p| p["technology"] }.uniq

    assert_equal [ "resin" ], technologies
  end

  test "should search by query" do
    get printer_profiles_url, params: { q: "Bambu" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    manufacturers = json.map { |p| p["manufacturer"] }

    assert manufacturers.include?("Bambu Lab")
    assert_not manufacturers.include?("Elegoo")
  end

  test "should search case insensitively" do
    get printer_profiles_url, params: { q: "bambu" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.any? { |p| p["manufacturer"] == "Bambu Lab" }
  end

  test "should combine technology filter and search" do
    get printer_profiles_url, params: { technology: "fdm", q: "Prusa" }, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    assert json.all? { |p| p["technology"] == "fdm" }
    assert json.any? { |p| p["manufacturer"] == "Prusa" }
  end

  test "profiles are ordered by manufacturer and model" do
    get printer_profiles_url, as: :json
    assert_response :success

    json = JSON.parse(response.body)
    manufacturers = json.map { |p| p["manufacturer"] }

    assert_equal manufacturers, manufacturers.sort
  end
end
