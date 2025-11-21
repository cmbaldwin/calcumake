# frozen_string_literal: true

require "test_helper"

class Cards::PlateCardComponentTest < ViewComponent::TestCase
  # Basic Rendering
  test "renders with default index" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    assert_selector "div.card[data-plate-index='0']"
    assert_selector ".plate-number"
    assert_text "1" # plate_number is index + 1
  end

  test "renders with custom index" do
    render_inline(Cards::PlateCardComponent.new(index: 2))

    assert_selector "div.card[data-plate-index='2']"
    assert_selector ".plate-index", text: "3"
  end

  # Card Structure
  test "renders card header with plate number and remove button" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    assert_selector ".card-header i.bi-square"
    assert_selector ".card-header button.btn-danger[data-action='click->advanced-calculator#removePlate']"
    assert_selector ".card-header button i.bi-trash"
  end

  test "renders card body with form fields" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    assert_selector ".card-body"
    assert_selector ".card-body .row.g-3"
  end

  # Print Settings Fields
  test "renders all 8 print setting fields" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    # Check all field names are present
    assert_selector "input[name='plates[0][print_time]']"
    assert_selector "input[name='plates[0][power_consumption]']"
    assert_selector "input[name='plates[0][machine_cost]']"
    assert_selector "input[name='plates[0][payoff_years]']"
    assert_selector "input[name='plates[0][prep_time]']"
    assert_selector "input[name='plates[0][post_time]']"
    assert_selector "input[name='plates[0][prep_rate]']"
    assert_selector "input[name='plates[0][post_rate]']"
  end

  test "renders fields with correct default values" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    assert_selector "input[name='plates[0][print_time]'][value='2.5']"
    assert_selector "input[name='plates[0][power_consumption]'][value='200']"
    assert_selector "input[name='plates[0][machine_cost]'][value='500']"
    assert_selector "input[name='plates[0][payoff_years]'][value='3']"
    assert_selector "input[name='plates[0][prep_time]'][value='0.25']"
    assert_selector "input[name='plates[0][post_time]'][value='0.25']"
    assert_selector "input[name='plates[0][prep_rate]'][value='20']"
    assert_selector "input[name='plates[0][post_rate]'][value='20']"
  end

  test "renders fields with custom default values" do
    render_inline(Cards::PlateCardComponent.new(
      index: 0,
      defaults: { print_time: 5.0, machine_cost: 1000 }
    ))

    assert_selector "input[name='plates[0][print_time]'][value='5.0']"
    assert_selector "input[name='plates[0][machine_cost]'][value='1000']"
    # Other fields should still use defaults
    assert_selector "input[name='plates[0][power_consumption]'][value='200']"
  end

  test "renders fields with correct input attributes" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    # Print time field
    assert_selector "input[name='plates[0][print_time]'][type='number'][min='0.1'][step='0.1']"
    
    # Power consumption field
    assert_selector "input[name='plates[0][power_consumption]'][type='number'][min='1'][step='1']"
    
    # Prep time field
    assert_selector "input[name='plates[0][prep_time]'][type='number'][min='0'][step='0.05']"
  end

  test "renders fields with Stimulus data-action" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    # All fields should have the calculate action
    assert_selector "input[name='plates[0][print_time]'][data-action='input->advanced-calculator#calculate']"
    assert_selector "input[name='plates[0][machine_cost]'][data-action='input->advanced-calculator#calculate']"
  end

  # Field Layout
  test "renders first row fields with col-md-4" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    # First 4 fields should be col-md-4
    assert_selector ".col-md-4", count: 4
  end

  test "renders second row fields with col-md-6" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    # Last 4 fields should be col-md-6
    assert_selector ".col-md-6", count: 4
  end

  # Filaments Section
  test "renders filaments section" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    assert_selector ".filaments-section"
    assert_selector ".filaments-section label.fw-bold"
    assert_selector ".filaments-section i.bi-palette"
  end

  test "renders add filament button" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    assert_selector "button.btn-outline-success[data-action='click->advanced-calculator#addFilament']"
    assert_selector "button.btn-outline-success i.bi-plus"
  end

  test "renders filaments container" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    assert_selector "[data-filaments-container].filaments-container"
  end

  test "renders filament template element" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    # Template tag exists in HTML but not visible to Capybara
    assert_includes rendered_content, '<template data-filament-template>'
  end

  test "filament template contains correct fields" do
    render_inline(Cards::PlateCardComponent.new(index: 1))

    # Check template contains filament fields with correct plate index
    html = rendered_content
    assert_includes html, "plates[1][filaments][0][filament_weight]"
    assert_includes html, "plates[1][filaments][0][filament_price]"
  end

  test "filament template has correct default values" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    html = rendered_content
    assert_includes html, 'value="45"' # filament_weight
    assert_includes html, 'value="25"' # filament_price
  end

  test "filament template with custom defaults" do
    render_inline(Cards::PlateCardComponent.new(
      index: 0,
      defaults: { filament_weight: 100, filament_price: 30 }
    ))

    html = rendered_content
    assert_includes html, 'value="100"'
    assert_includes html, 'value="30"'
  end

  test "filament template has remove button" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    html = rendered_content
    assert_includes html, "click->advanced-calculator#removeFilament"
    assert_includes html, "bi-trash"
  end

  test "renders filaments help text" do
    render_inline(Cards::PlateCardComponent.new(index: 0))

    assert_selector ".filaments-section small.text-muted"
    assert_selector ".filaments-section i.bi-info-circle"
  end

  # Index Handling
  test "plate index affects field names" do
    render_inline(Cards::PlateCardComponent.new(index: 3))

    assert_selector "input[name='plates[3][print_time]']"
    assert_selector "input[name='plates[3][machine_cost]']"
  end

  test "plate index affects filament template names" do
    render_inline(Cards::PlateCardComponent.new(index: 5))

    html = rendered_content
    assert_includes html, "plates[5][filaments][0][filament_weight]"
  end

  # Helper Methods
  test "plate_number returns index plus one" do
    component = Cards::PlateCardComponent.new(index: 0)
    assert_equal 1, component.plate_number

    component = Cards::PlateCardComponent.new(index: 4)
    assert_equal 5, component.plate_number
  end

  test "default_values returns complete hash" do
    component = Cards::PlateCardComponent.new(index: 0)
    defaults = component.default_values

    assert_equal 2.5, defaults[:print_time]
    assert_equal 200, defaults[:power_consumption]
    assert_equal 500, defaults[:machine_cost]
    assert_equal 3, defaults[:payoff_years]
    assert_equal 0.25, defaults[:prep_time]
    assert_equal 0.25, defaults[:post_time]
    assert_equal 20, defaults[:prep_rate]
    assert_equal 20, defaults[:post_rate]
    assert_equal 45, defaults[:filament_weight]
    assert_equal 25, defaults[:filament_price]
  end

  test "field_config returns configuration for all fields" do
    component = Cards::PlateCardComponent.new(index: 0)
    config = component.field_config

    assert_equal 8, config.keys.length
    assert config.key?(:print_time)
    assert config.key?(:power_consumption)
    assert config.key?(:machine_cost)
    assert config.key?(:payoff_years)
    assert config.key?(:prep_time)
    assert config.key?(:post_time)
    assert config.key?(:prep_rate)
    assert config.key?(:post_rate)
  end

  test "field_config includes correct attributes" do
    component = Cards::PlateCardComponent.new(index: 0)
    config = component.field_config

    print_time_config = config[:print_time]
    assert_equal 'advanced_calculator.plate_fields.print_time', print_time_config[:label]
    assert_equal '(hrs)', print_time_config[:unit]
    assert_equal 0.1, print_time_config[:min]
    assert_equal 0.1, print_time_config[:step]
  end
end
