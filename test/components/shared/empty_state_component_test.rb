# frozen_string_literal: true

require "test_helper"

class Shared::EmptyStateComponentTest < ViewComponent::TestCase
  test "renders with required title only" do
    render_inline(Shared::EmptyStateComponent.new(title: "No items found"))

    assert_selector ".text-center.py-5"
    assert_selector ".card.border-0.bg-light"
    assert_selector "h3.text-muted", text: "No items found"
  end

  test "renders with title and description" do
    render_inline(Shared::EmptyStateComponent.new(
      title: "No items",
      description: "Get started by creating your first item."
    ))

    assert_selector "h3.text-muted", text: "No items"
    assert_selector "p.text-muted", text: "Get started by creating your first item."
  end

  test "renders with action button when action_text and action_url provided" do
    render_inline(Shared::EmptyStateComponent.new(
      title: "Empty",
      action_text: "Add First Item",
      action_url: "/items/new"
    ))

    assert_selector "a.btn.btn-primary[href='/items/new']", text: "Add First Item"
  end

  test "does not render action button when action_text missing" do
    render_inline(Shared::EmptyStateComponent.new(
      title: "Empty",
      action_url: "/items/new"
    ))

    refute_selector "a.btn"
  end

  test "does not render action button when action_url missing" do
    render_inline(Shared::EmptyStateComponent.new(
      title: "Empty",
      action_text: "Add Item"
    ))

    refute_selector "a.btn"
  end

  test "supports different action button variants" do
    render_inline(Shared::EmptyStateComponent.new(
      title: "Empty",
      action_text: "Clear Search",
      action_url: "/items",
      action_variant: "secondary"
    ))

    assert_selector "a.btn.btn-secondary", text: "Clear Search"
  end

  test "renders icon when provided" do
    render_inline(Shared::EmptyStateComponent.new(
      title: "Empty",
      icon: "inbox"
    ))

    assert_selector "i.bi-inbox"
  end

  test "does not render icon when not provided" do
    render_inline(Shared::EmptyStateComponent.new(title: "Empty"))

    refute_selector "i.bi"
  end

  test "does not render description paragraph when description is nil" do
    render_inline(Shared::EmptyStateComponent.new(
      title: "Empty",
      description: nil
    ))

    refute_selector "p.text-muted"
  end

  test "does not render description paragraph when description is blank" do
    render_inline(Shared::EmptyStateComponent.new(
      title: "Empty",
      description: ""
    ))

    refute_selector "p.text-muted"
  end

  test "applies custom html_options class" do
    render_inline(Shared::EmptyStateComponent.new(
      title: "Empty",
      html_options: { class: "custom-class" }
    ))

    assert_selector ".text-center.py-5.custom-class"
  end

  test "renders complete example with all options" do
    render_inline(Shared::EmptyStateComponent.new(
      title: "No clients yet",
      description: "Start building your client list today.",
      action_text: "Add First Client",
      action_url: "/clients/new",
      action_variant: "primary",
      icon: "people"
    ))

    assert_selector "i.bi-people"
    assert_selector "h3.text-muted", text: "No clients yet"
    assert_selector "p.text-muted", text: "Start building your client list today."
    assert_selector "a.btn.btn-primary[href='/clients/new']", text: "Add First Client"
  end
end
