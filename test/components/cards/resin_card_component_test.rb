# frozen_string_literal: true

require "test_helper"

class Cards::ResinCardComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @resin = resins(:one)
    @user = users(:one)
  end

  test "renders resin name in header" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector "h5.text-primary", text: @resin.name
  end

  test "renders resin type badge" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector ".badge.bg-info", text: @resin.resin_type
  end

  test "renders brand when present" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector ".fw-bold", text: @resin.brand
    assert_text I18n.t("resins.fields.brand")
  end

  test "does not render brand section when brand is blank" do
    @resin.brand = nil

    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    refute_text I18n.t("resins.fields.brand")
  end

  test "renders color when present" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector ".fw-bold", text: @resin.color
    assert_text I18n.t("resins.fields.color")
  end

  test "does not render color section when color is blank" do
    @resin.color = nil

    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    refute_text I18n.t("resins.fields.color")
  end

  test "renders cost per ml when bottle data available" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_text I18n.t("resins.fields.cost_per_ml")
    assert_text "/mL"
  end

  test "does not render cost per ml when bottle price is blank" do
    @resin.bottle_price = nil

    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    refute_text I18n.t("resins.fields.cost_per_ml")
  end

  test "does not render cost per ml when bottle volume is blank" do
    @resin.bottle_volume_ml = nil

    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    refute_text I18n.t("resins.fields.cost_per_ml")
  end

  test "renders layer height range" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector ".fw-bold", text: @resin.layer_height_range
    assert_text I18n.t("resins.fields.layer_height_range")
  end

  test "renders needs wash badge when true" do
    @resin.needs_wash = true

    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector ".badge.bg-warning", text: I18n.t("resins.properties.needs_wash")
  end

  test "does not render needs wash badge when false" do
    @resin.needs_wash = false

    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    refute_selector ".badge.bg-warning"
  end

  test "renders actions dropdown" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector ".dropdown-toggle", text: I18n.t("actions.actions")
  end

  test "renders view action link" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector "a.dropdown-item[href='#{resin_path(@resin)}']", text: I18n.t("actions.view")
  end

  test "renders edit action link" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector "a.dropdown-item[href='#{edit_resin_path(@resin)}']", text: I18n.t("actions.edit")
  end

  test "renders duplicate action link" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector "a.dropdown-item[href='#{duplicate_resin_path(@resin)}']", text: I18n.t("actions.duplicate")
  end

  test "renders delete action link" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector "a.dropdown-item.text-danger[href='#{resin_path(@resin)}']", text: I18n.t("actions.delete")
  end

  test "applies custom html_options class" do
    render_inline(Cards::ResinCardComponent.new(
      resin: @resin,
      current_user: @user,
      html_options: { class: "custom-class" }
    ))

    assert_selector ".card.h-100.custom-class"
  end

  test "renders responsive column wrapper" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector ".col-lg-4.col-md-6"
  end

  test "card has full height" do
    render_inline(Cards::ResinCardComponent.new(resin: @resin, current_user: @user))

    assert_selector ".card.h-100"
  end
end
