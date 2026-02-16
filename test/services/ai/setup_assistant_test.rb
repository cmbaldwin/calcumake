require "test_helper"

class Ai::SetupAssistantTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @user.printers.where(name: "Prusa i3 MK4").destroy_all
    @user.filaments.where(name: "Chat PLA").destroy_all
  end

  test "creates printer from preset action" do
    service = Ai::SetupAssistant.new(user: @user, context: "app")
    plan = {
      response: "Creating it now.",
      actions: [
        {
          type: "create_printer",
          attributes: { "preset_model" => "Prusa i3 MK4" }
        }
      ]
    }

    assert_difference "@user.printers.count", 1 do
      service.stub(:plan_from_llm, plan) do
        result = service.call(message: "add prusa mk4", conversation: [])
        assert result[:ok]
        assert_equal "success", result.dig(:actions, 0, :status)
      end
    end
  end

  test "creates filament from starter preset action" do
    service = Ai::SetupAssistant.new(user: @user, context: "app")
    plan = {
      response: "Adding PLA.",
      actions: [
        {
          type: "create_filament",
          attributes: { "starter_preset" => "PLA", "name" => "Chat PLA" }
        }
      ]
    }

    assert_difference "@user.filaments.count", 1 do
      service.stub(:plan_from_llm, plan) do
        result = service.call(message: "add pla", conversation: [])
        assert result[:ok]
        assert_equal "success", result.dig(:actions, 0, :status)
      end
    end
  end

  test "returns error action for invalid resin type" do
    service = Ai::SetupAssistant.new(user: @user, context: "app")
    plan = {
      response: "Trying to add resin.",
      actions: [
        {
          type: "create_resin",
          attributes: { "name" => "Bad Resin", "resin_type" => "UnknownType" }
        }
      ]
    }

    assert_no_difference "@user.resins.count" do
      service.stub(:plan_from_llm, plan) do
        result = service.call(message: "add resin", conversation: [])
        assert result[:ok]
        assert_equal "error", result.dig(:actions, 0, :status)
      end
    end
  end

  test "marks onboarding ready when printer exists on printer step" do
    service = Ai::SetupAssistant.new(user: @user, context: "onboarding", onboarding_step: "printer")
    plan = {
      response: "Done.",
      actions: [
        {
          type: "create_printer",
          attributes: { "preset_model" => "Prusa i3 MK4" }
        }
      ]
    }

    service.stub(:plan_from_llm, plan) do
      result = service.call(message: "add prusa", conversation: [])
      assert_equal true, result[:onboarding_ready]
    end
  end
end
