# frozen_string_literal: true

class InfoSectionComponent < ViewComponent::Base
  def initialize(title:, items: [], link_text: nil, link_url: nil, link_options: {})
    @title = title
    @items = Array(items)
    @link_text = link_text
    @link_url = link_url
    @link_options = link_options
  end

  def show_link?
    @link_text.present? && @link_url.present?
  end

  def link_classes
    classes = [ @link_options[:class], "text-primary" ].compact
    classes.join(" ")
  end

  def link_html_options
    @link_options.except(:class).merge(class: link_classes)
  end
end
