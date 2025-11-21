# frozen_string_literal: true

require "test_helper"

class InfoSectionComponentTest < ViewComponent::TestCase
  # Basic Rendering
  test "renders with title only" do
    render_inline(InfoSectionComponent.new(title: "Important Information"))

    assert_selector "div.alert.alert-info"
    assert_selector "p strong", text: "Important Information"
  end

  test "renders with title and items" do
    render_inline(InfoSectionComponent.new(
      title: "Auto-calculated",
      items: [ "Item 1", "Item 2", "Item 3" ]
    ))

    assert_selector "div.alert.alert-info"
    assert_selector "p strong", text: "Auto-calculated"
    assert_selector "ul.mb-2"
    assert_selector "li", count: 3
    assert_selector "li", text: "Item 1"
    assert_selector "li", text: "Item 2"
    assert_selector "li", text: "Item 3"
  end

  test "renders with single item in array" do
    render_inline(InfoSectionComponent.new(
      title: "Note",
      items: [ "Single item" ]
    ))

    assert_selector "ul.mb-2"
    assert_selector "li", count: 1
    assert_selector "li", text: "Single item"
  end

  # Items Handling
  test "does not render ul when items is empty array" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: []
    ))

    refute_selector "ul"
  end

  test "does not render ul when items is nil" do
    render_inline(InfoSectionComponent.new(title: "Title"))

    refute_selector "ul"
  end

  test "converts single string item to array" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: "Single item"
    ))

    assert_selector "ul"
    assert_selector "li", count: 1
    assert_selector "li", text: "Single item"
  end

  # Link Rendering
  test "renders with link when link_text and link_url provided" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Item" ],
      link_text: "Learn more",
      link_url: "/help"
    ))

    assert_selector "small"
    assert_selector "a[href='/help']", text: "Learn more"
    assert_selector "a.text-primary"
  end

  test "does not render link when link_text is nil" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Item" ],
      link_text: nil,
      link_url: "/help"
    ))

    refute_selector "small"
    refute_selector "a"
  end

  test "does not render link when link_url is nil" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Item" ],
      link_text: "Learn more",
      link_url: nil
    ))

    refute_selector "small"
    refute_selector "a"
  end

  test "does not render link when link_text is empty string" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Item" ],
      link_text: "",
      link_url: "/help"
    ))

    refute_selector "small"
    refute_selector "a"
  end

  test "does not render link when link_url is empty string" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Item" ],
      link_text: "Learn more",
      link_url: ""
    ))

    refute_selector "small"
    refute_selector "a"
  end

  # Link Options
  test "applies link options to link" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Item" ],
      link_text: "Settings",
      link_url: "/settings",
      link_options: { data: { confirm: "Are you sure?" }, target: "_blank" }
    ))

    assert_selector "a[href='/settings'][data-confirm='Are you sure?'][target='_blank']"
  end

  test "merges custom class with text-primary" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Item" ],
      link_text: "Link",
      link_url: "/path",
      link_options: { class: "custom-class" }
    ))

    assert_selector "a.custom-class.text-primary"
  end

  test "applies text-primary class when no custom class" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Item" ],
      link_text: "Link",
      link_url: "/path"
    ))

    assert_selector "a.text-primary"
  end

  # HTML Content in Items
  test "renders HTML content in items" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Uses <strong>power consumption</strong> data" ]
    ))

    # Should be escaped by default
    assert_selector "li", text: "Uses <strong>power consumption</strong> data"
  end

  test "renders safe HTML content in items when marked as html_safe" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Uses <strong>power consumption</strong> data".html_safe ]
    ))

    assert_selector "li strong", text: "power consumption"
  end

  # Structure and CSS
  test "has correct CSS classes on alert" do
    render_inline(InfoSectionComponent.new(title: "Title"))

    assert_selector "div.alert.alert-info"
  end

  test "has correct CSS classes on paragraph" do
    render_inline(InfoSectionComponent.new(title: "Title"))

    assert_selector "p.mb-2"
  end

  test "has correct CSS classes on list" do
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: [ "Item" ]
    ))

    assert_selector "ul.mb-2"
  end

  # Helper Methods
  test "show_link? returns true when both link_text and link_url present" do
    component = InfoSectionComponent.new(
      title: "Title",
      link_text: "Link",
      link_url: "/path"
    )

    assert component.show_link?
  end

  test "show_link? returns false when link_text is nil" do
    component = InfoSectionComponent.new(
      title: "Title",
      link_text: nil,
      link_url: "/path"
    )

    refute component.show_link?
  end

  test "show_link? returns false when link_url is nil" do
    component = InfoSectionComponent.new(
      title: "Title",
      link_text: "Link",
      link_url: nil
    )

    refute component.show_link?
  end

  test "show_link? returns false when link_text is empty" do
    component = InfoSectionComponent.new(
      title: "Title",
      link_text: "",
      link_url: "/path"
    )

    refute component.show_link?
  end

  test "link_classes includes text-primary" do
    component = InfoSectionComponent.new(
      title: "Title",
      link_text: "Link",
      link_url: "/path"
    )

    assert_includes component.link_classes, "text-primary"
  end

  test "link_classes includes custom class when provided" do
    component = InfoSectionComponent.new(
      title: "Title",
      link_text: "Link",
      link_url: "/path",
      link_options: { class: "custom" }
    )

    assert_includes component.link_classes, "custom"
    assert_includes component.link_classes, "text-primary"
  end

  test "link_html_options excludes class key" do
    component = InfoSectionComponent.new(
      title: "Title",
      link_text: "Link",
      link_url: "/path",
      link_options: { class: "custom", data: { confirm: "Sure?" } }
    )

    options = component.link_html_options
    assert_equal "custom text-primary", options[:class]
    assert_equal({ confirm: "Sure?" }, options[:data])
  end

  # Edge Cases
  test "handles very long title" do
    long_title = "A" * 200
    render_inline(InfoSectionComponent.new(title: long_title))

    assert_selector "p strong", text: long_title
  end

  test "handles many items" do
    items = (1..20).map { |i| "Item #{i}" }
    render_inline(InfoSectionComponent.new(
      title: "Title",
      items: items
    ))

    assert_selector "li", count: 20
  end

  test "handles empty title" do
    render_inline(InfoSectionComponent.new(title: ""))

    assert_selector "p strong"
  end

  # Real-world Examples
  test "renders electricity info section example" do
    render_inline(InfoSectionComponent.new(
      title: "Auto-calculated from:",
      items: [
        "Power consumption per plate",
        "Total print time",
        "Your energy cost: $0.12/kWh"
      ],
      link_text: "Change in profile settings",
      link_url: "/profile"
    ))

    assert_selector "p strong", text: "Auto-calculated from:"
    assert_selector "li", count: 3
    assert_selector "a[href='/profile']", text: "Change in profile settings"
  end

  test "renders machine upkeep info section example" do
    render_inline(InfoSectionComponent.new(
      title: "Auto-calculated based on:",
      items: [
        "Printer cost and daily usage",
        "Return on investment period",
        "1.5x repair/maintenance factor"
      ],
      link_text: "Add or edit printer",
      link_url: "/printers/new",
      link_options: { data: { confirm: "Unsaved changes will be lost" } }
    ))

    assert_selector "p strong", text: "Auto-calculated based on:"
    assert_selector "li", count: 3
    assert_selector "a[href='/printers/new'][data-confirm]"
  end
end
