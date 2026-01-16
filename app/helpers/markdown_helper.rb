# frozen_string_literal: true

# Helper methods for generating and working with markdown content
module MarkdownHelper
  # Generate alternate format links for HTML head
  # These links help AI crawlers discover markdown versions
  def markdown_alternate_links(base_path, include_locales: true)
    links = []

    if include_locales
      I18n.available_locales.each do |locale|
        href = if locale == I18n.default_locale
          "#{base_path}.md"
        else
          "/#{locale}#{base_path}.md"
        end

        links << tag.link(
          rel: "alternate",
          type: "text/markdown",
          hreflang: locale,
          href: href
        )
      end
    else
      links << tag.link(
        rel: "alternate",
        type: "text/markdown",
        href: "#{base_path}.md"
      )
    end

    safe_join(links, "\n")
  end

  # Generate a link to the markdown version of the current page
  def link_to_markdown(text = "View as Markdown", path: nil, **options)
    path ||= request.path + ".md"
    link_to text, path, **options.merge(type: "text/markdown")
  end

  # Check if markdown format is being requested
  def markdown_format?
    request.format.symbol == :md || request.format.symbol == :markdown
  end

  # Generate frontmatter metadata hash
  def markdown_frontmatter(title:, url:, **options)
    {
      title: title,
      url: url,
      canonical_url: options[:canonical_url] || url,
      language: I18n.locale.to_s,
      last_updated: options[:last_updated] || Date.today.to_s,
      type: options[:type] || "page",
      site_name: "CalcuMake",
      description: options[:description] || "",
      keywords: options[:keywords] || []
    }.compact
  end

  # Format markdown frontmatter as YAML
  def format_frontmatter(metadata)
    [
      "---",
      metadata.to_yaml.lines[1..].join, # Skip the initial "---" from to_yaml
      "---"
    ].join("\n")
  end

  # Convert a list to markdown format
  def markdown_list(items, ordered: false)
    return "" if items.blank?

    marker = ordered ? "1. " : "- "
    items.map.with_index do |item, index|
      prefix = ordered ? "#{index + 1}. " : marker
      "#{prefix}#{item}"
    end.join("\n")
  end

  # Create a markdown link
  def markdown_link(text, url, title: nil)
    link = "[#{text}](#{url}"
    link += %( "#{title}") if title
    link + ")"
  end

  # Create a markdown heading
  def markdown_heading(text, level: 2)
    "#" * level + " #{text}"
  end

  # Get language name for locale
  def language_name_for_locale(locale)
    {
      en: "English",
      ja: "日本語",
      "zh-CN": "中文",
      hi: "हिंदी",
      es: "Español",
      fr: "Français",
      ar: "العربية"
    }[locale.to_sym] || locale.to_s
  end

  # Generate language navigation links for markdown
  def markdown_language_navigation(base_path, current_locale: I18n.locale)
    links = I18n.available_locales.map do |locale|
      lang_name = language_name_for_locale(locale)
      url = locale == I18n.default_locale ? "#{base_path}.md" : "/#{locale}#{base_path}.md"

      if locale == current_locale
        "**#{lang_name}**"
      else
        "[#{lang_name}](#{url})"
      end
    end

    "**Available in:** #{links.join(' | ')}"
  end
end
