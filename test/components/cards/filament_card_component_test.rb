# frozen_string_literal: true

require "test_helper"

class Cards::FilamentCardComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @filament = filaments(:one)
    @user = users(:one)
  end

  test "renders filament name in header" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector "h5.text-primary", text: @filament.name
  end

  test "renders material type badge" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector ".badge.bg-success", text: @filament.material_type
  end

  test "renders brand when present" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector ".fw-bold", text: @filament.brand
    assert_text I18n.t('filaments.fields.brand')
  end

  test "does not render brand section when brand is blank" do
    @filament.brand = nil

    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    refute_text I18n.t('filaments.fields.brand')
  end

  test "renders diameter" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector ".fw-bold", text: "#{@filament.diameter}mm"
    assert_text I18n.t('filaments.fields.diameter')
  end

  test "renders color when present" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector ".fw-bold", text: @filament.color
    assert_text I18n.t('filaments.fields.color')
  end

  test "does not render color section when color is blank" do
    @filament.color = nil

    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    refute_text I18n.t('filaments.fields.color')
  end

  test "renders cost per gram when spool data available" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_text I18n.t('filaments.fields.cost_per_gram')
    assert_text "/g"
  end

  test "does not render cost per gram when spool price is blank" do
    @filament.spool_price = nil

    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    refute_text I18n.t('filaments.fields.cost_per_gram')
  end

  test "does not render cost per gram when spool weight is blank" do
    @filament.spool_weight = nil

    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    refute_text I18n.t('filaments.fields.cost_per_gram')
  end

  test "renders temperature range" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector ".fw-bold", text: @filament.temperature_range
    assert_text I18n.t('filaments.fields.temperature_range')
  end

  test "renders moisture sensitive badge when true" do
    @filament.moisture_sensitive = true

    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector ".badge.bg-warning", text: I18n.t('filaments.properties.moisture_sensitive')
  end

  test "does not render moisture sensitive badge when false" do
    @filament.moisture_sensitive = false

    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    refute_selector ".badge.bg-warning"
  end

  test "renders actions dropdown" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector ".dropdown-toggle", text: I18n.t('actions.actions')
  end

  test "renders view action link" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector "a.dropdown-item[href='#{filament_path(@filament)}']", text: I18n.t('actions.view')
  end

  test "renders edit action link" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector "a.dropdown-item[href='#{edit_filament_path(@filament)}']", text: I18n.t('actions.edit')
  end

  test "renders duplicate action link" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector "a.dropdown-item[href='#{duplicate_filament_path(@filament)}']", text: I18n.t('actions.duplicate')
  end

  test "renders delete action link" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector "a.dropdown-item.text-danger[href='#{filament_path(@filament)}']", text: I18n.t('actions.delete')
  end

  test "applies custom html_options class" do
    render_inline(Cards::FilamentCardComponent.new(
      filament: @filament,
      current_user: @user,
      html_options: { class: "custom-class" }
    ))

    assert_selector ".card.h-100.custom-class"
  end

  test "renders responsive column wrapper" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector ".col-lg-4.col-md-6"
  end

  test "card has full height" do
    render_inline(Cards::FilamentCardComponent.new(filament: @filament, current_user: @user))

    assert_selector ".card.h-100"
  end
end
