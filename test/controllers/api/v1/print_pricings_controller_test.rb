# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class PrintPricingsControllerTest < ActionDispatch::IntegrationTest
      setup do
        @user = users(:one)
        @other_user = users(:two)
        @token = @user.api_tokens.create!(name: "Test Token")
        @plain_token = @token.plain_token
        @print_pricing = print_pricings(:one)
        @other_user_print_pricing = print_pricings(:two)
        @printer = printers(:one)
        @client = clients(:one)
        @filament = filaments(:one)
      end

      # Authentication tests
      test "index requires authentication" do
        get api_v1_print_pricings_url
        assert_response :unauthorized
      end

      test "show requires authentication" do
        get api_v1_print_pricing_url(@print_pricing)
        assert_response :unauthorized
      end

      test "create requires authentication" do
        post api_v1_print_pricings_url, params: { print_pricing: { job_name: "New" } }
        assert_response :unauthorized
      end

      test "update requires authentication" do
        patch api_v1_print_pricing_url(@print_pricing), params: { print_pricing: { job_name: "Updated" } }
        assert_response :unauthorized
      end

      test "destroy requires authentication" do
        delete api_v1_print_pricing_url(@print_pricing)
        assert_response :unauthorized
      end

      test "duplicate requires authentication" do
        post duplicate_api_v1_print_pricing_url(@print_pricing)
        assert_response :unauthorized
      end

      test "increment_times_printed requires authentication" do
        patch increment_times_printed_api_v1_print_pricing_url(@print_pricing)
        assert_response :unauthorized
      end

      test "decrement_times_printed requires authentication" do
        patch decrement_times_printed_api_v1_print_pricing_url(@print_pricing)
        assert_response :unauthorized
      end

      # Index tests
      test "index returns user print pricings" do
        get api_v1_print_pricings_url, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json.key?("data")
        assert json["data"].is_a?(Array)
        assert json["data"].any? { |p| p["id"] == @print_pricing.id.to_s }
      end

      test "index does not return other users print pricings" do
        get api_v1_print_pricings_url, headers: auth_headers

        json = JSON.parse(response.body)
        pricing_ids = json["data"].map { |p| p["id"] }

        refute_includes pricing_ids, @other_user_print_pricing.id.to_s
      end

      test "index filters by search query" do
        get api_v1_print_pricings_url, params: { q: @print_pricing.job_name }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert json["data"].any? { |p| p["id"] == @print_pricing.id.to_s }
      end

      test "index includes relationships meta" do
        get api_v1_print_pricings_url, headers: auth_headers

        json = JSON.parse(response.body)

        json["data"].each do |pricing|
          assert pricing["relationships"].key?("printer")
          assert pricing["relationships"].key?("client")
          assert pricing["relationships"]["plates"]["meta"].key?("count")
          assert pricing["relationships"]["invoices"]["meta"].key?("count")
        end
      end

      # Show tests
      test "show returns print pricing details" do
        get api_v1_print_pricing_url(@print_pricing), headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal @print_pricing.id.to_s, json["data"]["id"]
        assert_equal "print_pricing", json["data"]["type"]
        assert_equal @print_pricing.job_name, json["data"]["attributes"]["job_name"]
        assert_equal @print_pricing.units, json["data"]["attributes"]["units"]
        assert json["data"]["attributes"].key?("total_material_cost")
        assert json["data"]["attributes"].key?("total_electricity_cost")
        assert json["data"]["attributes"].key?("final_price")
        assert json["data"]["attributes"].key?("per_unit_price")
        assert json["data"]["attributes"].key?("currency")
      end

      test "show includes plates when requested" do
        get api_v1_print_pricing_url(@print_pricing), headers: auth_headers

        json = JSON.parse(response.body)

        # Show should include full plate data
        assert json["data"]["relationships"]["plates"].key?("data")
      end

      test "show returns 404 for non-existent print pricing" do
        get api_v1_print_pricing_url(id: 999999), headers: auth_headers

        assert_response :not_found
      end

      test "show returns 404 for other users print pricing" do
        get api_v1_print_pricing_url(@other_user_print_pricing), headers: auth_headers

        assert_response :not_found
      end

      # Create tests
      test "create creates a new print pricing with plates" do
        assert_difference("PrintPricing.count") do
          post api_v1_print_pricings_url, params: {
            print_pricing: {
              job_name: "New Print Job",
              printer_id: @printer.id,
              client_id: @client.id,
              units: 5,
              vat_percentage: 10,
              failure_rate_percentage: 5,
              plates_attributes: [
                {
                  printing_time_hours: 2,
                  printing_time_minutes: 30,
                  material_technology: "fdm",
                  plate_filaments_attributes: [
                    { filament_id: @filament.id, filament_weight: 50.0 }
                  ]
                }
              ]
            }
          }, headers: auth_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert_equal "New Print Job", json["data"]["attributes"]["job_name"]
        assert_equal 5, json["data"]["attributes"]["units"]
        assert_equal 10.0, json["data"]["attributes"]["vat_percentage"]
      end

      test "create returns JSON:API format response" do
        post api_v1_print_pricings_url, params: {
          print_pricing: {
            job_name: "Test",
            printer_id: @printer.id,
            plates_attributes: [ {
              printing_time_hours: 1,
              printing_time_minutes: 0,
              material_technology: "fdm",
              plate_filaments_attributes: [
                { filament_id: @filament.id, filament_weight: 25.0 }
              ]
            } ]
          }
        }, headers: auth_headers

        assert_response :created
        json = JSON.parse(response.body)
        assert json["data"].key?("id")
        assert json["data"].key?("type")
        assert json["data"].key?("attributes")
        assert json["data"].key?("relationships")
      end

      test "create with invalid data returns validation errors" do
        assert_no_difference("PrintPricing.count") do
          post api_v1_print_pricings_url, params: {
            print_pricing: { job_name: "" }
          }, headers: auth_headers
        end

        assert_response :unprocessable_entity
        json = JSON.parse(response.body)

        assert json.key?("errors")
        assert json["errors"].first["code"] == "validation_error"
      end

      test "create associates print pricing with current user" do
        post api_v1_print_pricings_url, params: {
          print_pricing: {
            job_name: "My Job",
            printer_id: @printer.id,
            plates_attributes: [ {
              printing_time_hours: 1,
              printing_time_minutes: 0,
              material_technology: "fdm",
              plate_filaments_attributes: [
                { filament_id: @filament.id, filament_weight: 25.0 }
              ]
            } ]
          }
        }, headers: auth_headers

        assert_response :created
        print_pricing = PrintPricing.last
        assert_equal @user.id, print_pricing.user_id
      end

      # Update tests
      test "update modifies print pricing" do
        patch api_v1_print_pricing_url(@print_pricing), params: {
          print_pricing: {
            job_name: "Updated Job Name",
            units: 10
          }
        }, headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal "Updated Job Name", json["data"]["attributes"]["job_name"]
        assert_equal 10, json["data"]["attributes"]["units"]
        @print_pricing.reload
        assert_equal "Updated Job Name", @print_pricing.job_name
      end

      test "update returns 404 for other users print pricing" do
        patch api_v1_print_pricing_url(@other_user_print_pricing), params: {
          print_pricing: { job_name: "Hacked" }
        }, headers: auth_headers

        assert_response :not_found
      end

      test "update with invalid data returns validation errors" do
        patch api_v1_print_pricing_url(@print_pricing), params: {
          print_pricing: { job_name: "" }
        }, headers: auth_headers

        assert_response :unprocessable_entity
      end

      # Destroy tests
      test "destroy deletes print pricing" do
        # Create a new print pricing with plate and filament
        print_pricing = @user.print_pricings.build(
          job_name: "Temp Job",
          printer: @printer
        )
        plate = print_pricing.plates.build(printing_time_hours: 1, printing_time_minutes: 0, material_technology: "fdm")
        plate.plate_filaments.build(filament: @filament, filament_weight: 25.0)
        print_pricing.save!

        assert_difference("PrintPricing.count", -1) do
          delete api_v1_print_pricing_url(print_pricing), headers: auth_headers
        end

        assert_response :no_content
      end

      test "destroy returns 404 for other users print pricing" do
        assert_no_difference("PrintPricing.count") do
          delete api_v1_print_pricing_url(@other_user_print_pricing), headers: auth_headers
        end

        assert_response :not_found
      end

      # Duplicate tests
      test "duplicate creates a copy of print pricing" do
        assert_difference("PrintPricing.count") do
          post duplicate_api_v1_print_pricing_url(@print_pricing), headers: auth_headers
        end

        assert_response :created
        json = JSON.parse(response.body)

        assert_match(/\(Copy\)/, json["data"]["attributes"]["job_name"])
        assert_equal 0, json["data"]["attributes"]["times_printed"]
      end

      test "duplicate returns 404 for other users print pricing" do
        assert_no_difference("PrintPricing.count") do
          post duplicate_api_v1_print_pricing_url(@other_user_print_pricing), headers: auth_headers
        end

        assert_response :not_found
      end

      test "duplicate copies plates" do
        # Ensure the print pricing has plates with filaments
        plate = @print_pricing.plates.find_or_initialize_by(printing_time_hours: 1, printing_time_minutes: 0, material_technology: "fdm")
        unless plate.persisted?
          plate.plate_filaments.build(filament: @filament, filament_weight: 25.0)
          plate.save!
        end

        post duplicate_api_v1_print_pricing_url(@print_pricing), headers: auth_headers

        assert_response :created
        json = JSON.parse(response.body)
        original_plate_count = @print_pricing.plates.count
        new_plate_count = json["data"]["relationships"]["plates"]["data"].count

        assert_equal original_plate_count, new_plate_count
      end

      # Times printed tests
      test "increment_times_printed increases count" do
        original_count = @print_pricing.times_printed || 0

        patch increment_times_printed_api_v1_print_pricing_url(@print_pricing), headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal original_count + 1, json["data"]["times_printed"]
        @print_pricing.reload
        assert_equal original_count + 1, @print_pricing.times_printed
      end

      test "decrement_times_printed decreases count" do
        @print_pricing.update!(times_printed: 5)

        patch decrement_times_printed_api_v1_print_pricing_url(@print_pricing), headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal 4, json["data"]["times_printed"]
      end

      test "decrement_times_printed does not go below zero" do
        @print_pricing.update!(times_printed: 0)

        patch decrement_times_printed_api_v1_print_pricing_url(@print_pricing), headers: auth_headers

        assert_response :success
        json = JSON.parse(response.body)

        assert_equal 0, json["data"]["times_printed"]
      end

      test "increment_times_printed returns 404 for other users print pricing" do
        patch increment_times_printed_api_v1_print_pricing_url(@other_user_print_pricing), headers: auth_headers

        assert_response :not_found
      end

      test "decrement_times_printed returns 404 for other users print pricing" do
        patch decrement_times_printed_api_v1_print_pricing_url(@other_user_print_pricing), headers: auth_headers

        assert_response :not_found
      end

      # Response format tests
      test "responses include correct content type" do
        get api_v1_print_pricings_url, headers: auth_headers

        assert_match %r{application/json}, response.content_type
      end

      test "index returns properly formatted attributes" do
        get api_v1_print_pricings_url, headers: auth_headers

        json = JSON.parse(response.body)

        json["data"].each do |pricing|
          assert pricing["attributes"].key?("job_name")
          assert pricing["attributes"].key?("units")
          assert pricing["attributes"].key?("times_printed")
          assert pricing["attributes"].key?("total_printing_time_minutes")
          assert pricing["attributes"].key?("total_material_cost")
          assert pricing["attributes"].key?("final_price")
          assert pricing["attributes"].key?("per_unit_price")
          assert pricing["attributes"].key?("currency")
          assert pricing["attributes"].key?("created_at")
          assert pricing["attributes"].key?("updated_at")
        end
      end

      # Cost calculation tests
      test "show returns calculated costs" do
        get api_v1_print_pricing_url(@print_pricing), headers: auth_headers

        json = JSON.parse(response.body)
        attrs = json["data"]["attributes"]

        assert attrs.key?("total_material_cost")
        assert attrs.key?("total_electricity_cost")
        assert attrs.key?("total_labor_cost")
        assert attrs.key?("total_machine_upkeep_cost")
        assert attrs.key?("subtotal")
        assert attrs.key?("final_price")
      end

      # Nested attributes tests
      test "create with nested plate filaments" do
        filament = filaments(:one)

        post api_v1_print_pricings_url, params: {
          print_pricing: {
            job_name: "Nested Test",
            printer_id: @printer.id,
            plates_attributes: [
              {
                printing_time_hours: 2,
                printing_time_minutes: 0,
                material_technology: "fdm",
                plate_filaments_attributes: [
                  {
                    filament_id: filament.id,
                    filament_weight: 50.0,
                    markup_percentage: 10
                  }
                ]
              }
            ]
          }
        }, headers: auth_headers

        assert_response :created

        pricing = PrintPricing.last
        assert_equal 1, pricing.plates.count
        assert_equal 1, pricing.plates.first.plate_filaments.count
      end

      test "update with nested plate updates" do
        plate = @print_pricing.plates.first
        unless plate
          plate = @print_pricing.plates.build(
            printing_time_hours: 1,
            printing_time_minutes: 0,
            material_technology: "fdm"
          )
          plate.plate_filaments.build(filament: @filament, filament_weight: 25.0)
          plate.save!
        end

        patch api_v1_print_pricing_url(@print_pricing), params: {
          print_pricing: {
            plates_attributes: [
              {
                id: plate.id,
                printing_time_hours: 5
              }
            ]
          }
        }, headers: auth_headers

        assert_response :success
        plate.reload
        assert_equal 5, plate.printing_time_hours
      end

      private

      def auth_headers
        { "Authorization" => "Bearer #{@plain_token}" }
      end
    end
  end
end
