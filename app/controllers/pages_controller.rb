# frozen_string_literal: true

# Controller for public informational pages
class PagesController < ApplicationController
  include MarkdownRenderable

  def about
    respond_with_markdown(
      "pages.about",
      metadata: {
        title: t("pages.about.title"),
        url: about_url,
        base_path: "/about",
        include_locale_in_path: false,
        type: "about_page",
        description: t("pages.about.description", default: "Learn about CalcuMake - Free 3D printing cost calculator and project management tool"),
        keywords: %w[calcumake about 3d-printing cost-calculator project-management free-software]
      }
    )
  end

  def markdown_index
    respond_to do |format|
      format.md do
        render plain: markdown_directory_content, content_type: "text/markdown"
      end
      format.html do
        redirect_to about_path
      end
    end
  end

  private

  def markdown_directory_content
    <<~MARKDOWN
      ---
      title: CalcuMake Markdown Content Directory
      url: #{markdown_index_url}
      language: #{I18n.locale}
      type: directory
      site_name: CalcuMake
      description: Directory of AI-optimized markdown content for CalcuMake
      ---

      # CalcuMake Markdown Content Directory

      This directory provides AI-optimized markdown versions of CalcuMake's public content.

      ## Available Content

      ### About CalcuMake

      - [About CalcuMake](#{about_url(format: :md)}) - Learn about our 3D printing cost calculator

      ### Support & Help

      - [Support & FAQ](#{support_url(format: :md)}) - Get help and answers to common questions

      ### Legal Information

      - [Privacy Policy](#{privacy_policy_url(format: :md)}) - Our privacy and data protection policy
      - [User Agreement](#{user_agreement_url(format: :md)}) - Terms of service and user agreement

      ## About This Format

      These markdown files are optimized for AI assistants and language models to:
      - Better understand our content
      - Provide accurate information to users asking about CalcuMake
      - Cite and reference our documentation correctly

      ## Multi-Language Support

      Content is available in 7 languages: English, Japanese, Chinese, Hindi, Spanish, French, and Arabic.

      ## Contact

      For questions or feedback: [cody@moab.jp](mailto:cody@moab.jp)

      ---

      _© 2025 株式会社モアブ (MOAB Co., Ltd.)_
    MARKDOWN
  end
end
