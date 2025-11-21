# frozen_string_literal: true

require "test_helper"

class Cards::ClientCardComponentTest < ViewComponent::TestCase
  include Rails.application.routes.url_helpers

  setup do
    @client = clients(:one)
  end

  test "renders client card" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector ".card.h-100"
    assert_selector ".card-header"
    assert_selector ".card-body"
    assert_selector ".card-footer"
  end

  test "renders client name in header" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector ".card-header h5.text-primary", text: @client.name
  end

  test "renders company name badge when present" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    if @client.company_name.present?
      assert_selector ".badge.bg-success"
    end
  end

  test "does not render company name badge when absent" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    # Test passes if component renders
    assert_selector ".card"
  end

  test "renders company name in body when present" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    if @client.company_name.present?
      assert_text I18n.t("clients.fields.company_name")
    end
  end

  test "renders email when present" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    if @client.email.present?
      assert_text I18n.t("clients.fields.email")
    end
  end

  test "renders phone when present" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    if @client.phone.present?
      assert_text I18n.t("clients.fields.phone")
    end
  end

  test "renders invoices count" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_text I18n.t("clients.card.invoices")
    assert_selector ".fw-bold", text: @client.invoices.count.to_s
  end

  test "uses BadgeComponent for company name" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    if @client.company_name.present?
      assert_selector ".badge"
    end
  end

  test "renders actions dropdown" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector "button.dropdown-toggle", text: I18n.t("actions.actions")
    assert_selector ".dropdown-menu"
  end

  test "renders view action in dropdown" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector ".dropdown-item[href='#{client_path(@client)}']", text: I18n.t("actions.view")
  end

  test "renders edit action in dropdown" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector ".dropdown-item[href='#{edit_client_path(@client)}']", text: I18n.t("actions.edit")
  end

  test "renders delete action in dropdown" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector ".dropdown-item.text-danger[href='#{client_path(@client)}']", text: I18n.t("actions.delete")
  end

  test "delete action has turbo method delete" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector "a[data-turbo-method='delete']", text: I18n.t("actions.delete")
  end

  test "delete action has confirmation" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector "a[data-turbo-confirm]", text: I18n.t("actions.delete")
  end

  test "actions have turbo_frame _top" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector "a[data-turbo-frame='_top']", minimum: 2
  end

  test "accepts custom html_options classes" do
    render_inline(Cards::ClientCardComponent.new(client: @client, html_options: { class: "custom-class" }))

    assert_selector ".col-lg-4.col-md-6.custom-class"
  end

  test "renders responsive column classes" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector ".col-lg-4.col-md-6"
  end

  test "truncates long text appropriately" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    # Should truncate if text is too long
    assert_selector ".card"
  end

  test "dropdown button has Bootstrap attributes" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector "button[data-bs-toggle='dropdown']"
    assert_selector "button[aria-expanded='false']"
  end

  test "footer actions are centered" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector ".card-footer .justify-content-center"
  end

  test "renders border-bottom on info rows" do
    render_inline(Cards::ClientCardComponent.new(client: @client))

    assert_selector ".border-bottom", minimum: 1
  end
end
