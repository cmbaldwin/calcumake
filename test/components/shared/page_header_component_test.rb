# frozen_string_literal: true

require "test_helper"

class Shared::PageHeaderComponentTest < ViewComponent::TestCase
  test "renders with required title only" do
    render_inline(Shared::PageHeaderComponent.new(title: "Clients"))

    assert_selector ".text-center.mb-5"
    assert_selector "h3.display-5.fw-bold.text-primary", text: "Clients"
  end

  test "renders with title and subtitle" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Clients",
      subtitle: "Manage your client relationships"
    ))

    assert_selector "h3.display-5", text: "Clients"
    assert_selector "p.lead.text-muted", text: "Manage your client relationships"
  end

  test "renders with action button when action_text and action_url provided" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Clients",
      action_text: "Add New Client",
      action_url: "/clients/new"
    ))

    assert_selector "a.btn.btn-primary.btn-lg[href='/clients/new']", text: "Add New Client"
  end

  test "does not render action button when action_text missing" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Clients",
      action_url: "/clients/new"
    ))

    refute_selector "a.btn"
  end

  test "does not render action button when action_url missing" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Clients",
      action_text: "Add New"
    ))

    refute_selector "a.btn"
  end

  test "supports different action button variants" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Clients",
      action_text: "Add New",
      action_url: "/clients/new",
      action_variant: "secondary"
    ))

    assert_selector "a.btn.btn-secondary", text: "Add New"
  end

  test "supports different action button sizes" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Clients",
      action_text: "Add New",
      action_url: "/clients/new",
      action_size: "sm"
    ))

    assert_selector "a.btn.btn-sm", text: "Add New"
  end

  test "supports different title sizes" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Clients",
      title_size: "display-4"
    ))

    assert_selector "h3.display-4.fw-bold.text-primary", text: "Clients"
  end

  test "does not render subtitle paragraph when subtitle is nil" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Clients",
      subtitle: nil
    ))

    refute_selector "p.lead"
  end

  test "does not render subtitle paragraph when subtitle is blank" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Clients",
      subtitle: ""
    ))

    refute_selector "p.lead"
  end

  test "applies custom html_options class" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Clients",
      html_options: { class: "custom-header" }
    ))

    assert_selector ".text-center.mb-5.custom-header"
  end

  test "renders complete example with all options" do
    render_inline(Shared::PageHeaderComponent.new(
      title: "Manage Clients",
      subtitle: "Build and maintain your client relationships",
      action_text: "Add New Client",
      action_url: "/clients/new",
      action_variant: "primary",
      action_size: "lg"
    ))

    assert_selector "h3.display-5.fw-bold.text-primary", text: "Manage Clients"
    assert_selector "p.lead.text-muted", text: "Build and maintain your client relationships"
    assert_selector "a.btn.btn-primary.btn-lg[href='/clients/new']", text: "Add New Client"
  end
end
