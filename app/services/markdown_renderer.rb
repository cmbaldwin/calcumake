# frozen_string_literal: true

require "kramdown"

# Service object for rendering content into AI-optimized markdown format
# with frontmatter metadata for better AI agent comprehension
class MarkdownRenderer
  attr_reader :i18n_scope, :locale, :metadata

  def initialize(i18n_scope, metadata: {}, locale: I18n.locale)
    @i18n_scope = i18n_scope
    @locale = locale
    @metadata = default_metadata.merge(metadata)
  end

  # Render full markdown document with frontmatter and content
  def render
    [
      render_frontmatter,
      "",
      render_content
    ].join("\n")
  end

  # Render just the YAML frontmatter
  def render_frontmatter
    frontmatter = {
      "title" => metadata[:title] || I18n.t("#{i18n_scope}.title", default: "CalcuMake"),
      "url" => metadata[:url],
      "canonical_url" => metadata[:canonical_url] || metadata[:url],
      "language" => locale.to_s,
      "alternate_languages" => alternate_language_urls,
      "last_updated" => metadata[:last_updated] || Date.today.to_s,
      "type" => metadata[:type] || "page",
      "site_name" => "CalcuMake",
      "description" => metadata[:description] || I18n.t("#{i18n_scope}.description", default: ""),
      "keywords" => metadata[:keywords] || []
    }.compact

    [
      "---",
      frontmatter.to_yaml.lines[1..].join, # Skip the initial "---" from to_yaml
      "---"
    ].join("\n")
  end

  # Render the main content as markdown
  def render_content
    content = []

    # Add language navigation if multi-language
    content << render_language_navigation if alternate_language_urls.any?
    content << ""

    # Add main title
    title = metadata[:title] || I18n.t("#{i18n_scope}.title", default: "")
    content << "# #{title}" if title.present?
    content << ""

    # Add main content sections
    content << render_main_content

    # Add footer
    content << ""
    content << render_footer

    content.join("\n")
  end

  private

  def default_metadata
    {
      type: "page",
      keywords: []
    }
  end

  def alternate_language_urls
    return @alternate_language_urls if defined?(@alternate_language_urls)

    @alternate_language_urls = {}
    if metadata[:base_path]
      I18n.available_locales.each do |loc|
        next if loc == locale

        url_path = if metadata[:include_locale_in_path]
          "/#{loc}#{metadata[:base_path]}.md"
        else
          "#{metadata[:base_path]}.md?locale=#{loc}"
        end

        @alternate_language_urls[loc.to_s] = url_path
      end
    end

    @alternate_language_urls
  end

  def render_language_navigation
    return "" if alternate_language_urls.empty?

    language_names = {
      "en" => "English",
      "ja" => "日本語",
      "zh-CN" => "中文",
      "hi" => "हिंदी",
      "es" => "Español",
      "fr" => "Français",
      "ar" => "العربية"
    }

    links = alternate_language_urls.map do |lang, url|
      "[#{language_names[lang] || lang}](#{url})"
    end

    # Add current language
    current_lang_name = language_names[locale.to_s] || locale.to_s
    all_links = ["**#{current_lang_name}**"] + links

    "**Available in:** #{all_links.join(' | ')}"
  end

  def render_main_content
    # This method should be overridden or customized per content type
    # For now, we'll extract content from i18n and convert HTML to markdown
    content = []

    # Try to get sections from i18n
    sections = I18n.t("#{i18n_scope}.sections", default: {})

    if sections.is_a?(Hash)
      sections.each do |key, section_content|
        content << render_section(key, section_content)
        content << ""
      end
    else
      # Fallback: render body if available
      body = I18n.t("#{i18n_scope}.body", default: "")
      content << html_to_markdown(body) if body.present?
    end

    content.join("\n")
  end

  def render_section(key, section_content)
    section = []

    if section_content.is_a?(Hash)
      # Section with title and content
      section << "## #{section_content[:title]}" if section_content[:title]
      section << ""
      section << html_to_markdown(section_content[:content] || section_content[:body] || "")
    elsif section_content.is_a?(String)
      # Just content
      section << html_to_markdown(section_content)
    end

    section.join("\n")
  end

  def render_footer
    [
      "---",
      "",
      "_Last updated: #{metadata[:last_updated] || Date.today.strftime('%Y-%m-%d')}_",
      "",
      "© 2025 株式会社モアブ (MOAB Co., Ltd.)"
    ].join("\n")
  end

  def html_to_markdown(html)
    return "" if html.blank?

    # Basic HTML to markdown conversion
    # Remove HTML tags but preserve structure
    text = html.dup

    # Convert headers
    text.gsub!(/<h1[^>]*>(.*?)<\/h1>/im, "# \\1\n")
    text.gsub!(/<h2[^>]*>(.*?)<\/h2>/im, "## \\1\n")
    text.gsub!(/<h3[^>]*>(.*?)<\/h3>/im, "### \\1\n")
    text.gsub!(/<h4[^>]*>(.*?)<\/h4>/im, "#### \\1\n")

    # Convert lists
    text.gsub!(/<li[^>]*>(.*?)<\/li>/im, "- \\1")
    text.gsub!(/<\/?[uo]l[^>]*>/i, "\n")

    # Convert links
    text.gsub!(/<a[^>]*href=["'](.*?)["'][^>]*>(.*?)<\/a>/im, "[\\2](\\1)")

    # Convert emphasis
    text.gsub!(/<strong[^>]*>(.*?)<\/strong>/im, "**\\1**")
    text.gsub!(/<em[^>]*>(.*?)<\/em>/im, "*\\1*")
    text.gsub!(/<b[^>]*>(.*?)<\/b>/im, "**\\1**")
    text.gsub!(/<i[^>]*>(.*?)<\/i>/im, "*\\1*")

    # Convert paragraphs
    text.gsub!(/<p[^>]*>(.*?)<\/p>/im, "\\1\n\n")

    # Convert line breaks
    text.gsub!(/<br\s*\/?>/i, "\n")

    # Remove remaining HTML tags
    text.gsub!(/<[^>]+>/, "")

    # Clean up entities
    text.gsub!("&nbsp;", " ")
    text.gsub!("&amp;", "&")
    text.gsub!("&lt;", "<")
    text.gsub!("&gt;", ">")
    text.gsub!("&quot;", '"')

    # Clean up extra whitespace
    text.gsub!(/\n\n\n+/, "\n\n")
    text.strip
  end
end
