# frozen_string_literal: true

# Concern for controllers that need to render markdown versions of content
# Provides format detection, response handling, headers, and caching
module MarkdownRenderable
  extend ActiveSupport::Concern

  included do
    before_action :set_markdown_headers, if: :markdown_request?
  end

  private

  # Check if the current request is for markdown format
  def markdown_request?
    request.format.symbol == :md || request.format.symbol == :markdown
  end

  # Set appropriate headers for markdown responses
  def set_markdown_headers
    response.headers["Content-Type"] = "text/markdown; charset=utf-8"
    response.headers["X-Content-Type-Options"] = "nosniff"

    # Allow AI crawlers to access content
    response.headers["X-Robots-Tag"] = "all"

    # Cache control for markdown content (24 hours)
    expires_in 24.hours, public: true
  end

  # Render markdown content with caching
  def render_markdown(i18n_scope, metadata: {}, cache_key: nil)
    cache_key ||= "markdown/#{I18n.locale}/#{controller_name}/#{action_name}"

    markdown_content = Rails.cache.fetch(cache_key, expires_in: 24.hours) do
      renderer = MarkdownRenderer.new(i18n_scope, metadata: metadata, locale: I18n.locale)
      renderer.render
    end

    render plain: markdown_content, content_type: "text/markdown"
  end

  # Respond to both HTML and markdown formats
  def respond_with_markdown(i18n_scope, metadata: {}, cache_key: nil, &html_block)
    respond_to do |format|
      format.html { html_block.call if html_block }
      format.md do
        render_markdown(i18n_scope, metadata: metadata, cache_key: cache_key)
      end
    end
  end

  # Track AI crawler requests (optional, for analytics)
  def track_markdown_request
    return unless markdown_request?

    user_agent = request.user_agent.to_s
    is_ai_crawler = ai_crawler?(user_agent)

    # Log or track the request
    Rails.logger.info "[Markdown] #{controller_name}##{action_name} - " \
                      "Locale: #{I18n.locale}, " \
                      "AI Crawler: #{is_ai_crawler}, " \
                      "User Agent: #{user_agent[0..50]}"
  end

  # Detect if the request is from an AI crawler
  def ai_crawler?(user_agent)
    ai_bots = %w[
      GPTBot
      ChatGPT-User
      Claude-Web
      CCBot
      PetalBot
      Bytespider
      anthropic-ai
      PerplexityBot
      Google-Extended
      Applebot-Extended
    ]

    ai_bots.any? { |bot| user_agent.include?(bot) }
  end
end
