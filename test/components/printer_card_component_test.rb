# frozen_string_literal: true

require "test_helper"

class PrinterCardComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @printer = printers(:one)
    @user = users(:one)
  end

  test "renders printer card" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".card.h-100"
    assert_selector ".card-header"
    assert_selector ".card-body"
    assert_selector ".card-footer"
  end

  test "renders printer name in header" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".card-header h5.text-primary", text: @printer.name
  end

  test "renders manufacturer badge" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".badge.bg-success", text: @printer.manufacturer
  end

  test "uses BadgeComponent for manufacturer" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".badge"
  end

  test "renders power consumption" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_text I18n.t('printers.card.power_consumption')
    assert_text "#{@printer.power_consumption}W"
  end

  test "renders cost with currency symbol" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_text I18n.t('printers.card.cost')
    # Should have currency and cost
    assert_selector ".fw-bold", text: /#{@printer.cost}/
  end

  test "renders daily usage hours" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_text I18n.t('printers.card.daily_usage')
    assert_text I18n.t('printers.card.hours')
  end

  test "renders payoff goal years" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_text I18n.t('printers.card.payoff_goal')
    assert_text I18n.t('printers.card.years')
  end

  test "renders payoff status alert" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    # Should have either paid off or months to payoff alert
    assert_selector ".alert"
  end

  test "uses AlertComponent for paid off status" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    # AlertComponent renders .alert
    assert_selector ".alert"
  end

  test "renders actions dropdown" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector "button.dropdown-toggle", text: I18n.t('actions.actions')
    assert_selector ".dropdown-menu"
  end

  test "renders view action in dropdown" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".dropdown-item[href='#{printer_path(@printer)}']", text: I18n.t('actions.view')
  end

  test "renders edit action in dropdown" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".dropdown-item[href='#{edit_printer_path(@printer)}']", text: I18n.t('actions.edit')
  end

  test "renders delete action in dropdown" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".dropdown-item.text-danger[href='#{printer_path(@printer)}']", text: I18n.t('actions.delete')
  end

  test "delete action has turbo method delete" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector "a[data-turbo-method='delete']", text: I18n.t('actions.delete')
  end

  test "actions have turbo_frame _top" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector "a[data-turbo-frame='_top']", minimum: 2
  end

  test "accepts custom html_options classes" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user, html_options: { class: "custom-class" }))

    assert_selector ".col-lg-4.col-md-6.custom-class"
  end

  test "renders responsive column classes" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".col-lg-4.col-md-6"
  end

  test "renders info sections with borders" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".border-bottom", minimum: 3
  end

  test "dropdown button has Bootstrap attributes" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector "button[data-bs-toggle='dropdown']"
    assert_selector "button[aria-expanded='false']"
  end

  test "alert has text-center styling" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".alert.text-center"
  end

  test "footer actions are centered" do
    render_inline(PrinterCardComponent.new(printer: @printer, current_user: @user))

    assert_selector ".card-footer .justify-content-center"
  end
end
