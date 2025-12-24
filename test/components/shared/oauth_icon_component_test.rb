# frozen_string_literal: true

require "test_helper"

module Shared
  class OAuthIconComponentTest < ViewComponent::TestCase
    test "renders Google icon" do
      render_inline(Shared::OAuthIconComponent.new(provider: "Google"))

      assert_match(/viewBox="0 0 18 18"/, rendered_content)
      assert_match(/fill="#4285F4"/, rendered_content) # Google blue
      assert_match(/fill="#34A853"/, rendered_content) # Google green
      assert_match(/fill="#FBBC05"/, rendered_content) # Google yellow
      assert_match(/fill="#EA4335"/, rendered_content) # Google red
    end

    test "renders GitHub icon" do
      render_inline(Shared::OAuthIconComponent.new(provider: "GitHub"))

      assert_match(/viewBox="0 0 16 16"/, rendered_content)
      assert_match(/<path/, rendered_content)
    end

    test "renders Microsoft icon" do
      render_inline(Shared::OAuthIconComponent.new(provider: "Microsoft"))

      assert_match(/viewBox="0 0 16 16"/, rendered_content)
      assert_match(/<path/, rendered_content)
    end

    test "renders Facebook icon" do
      render_inline(Shared::OAuthIconComponent.new(provider: "Facebook"))

      assert_match(/viewBox="0 0 24 24"/, rendered_content)
      assert_match(/fill="#1877F2"/, rendered_content) # Facebook blue
    end

    test "renders Yahoo! JAPAN icon" do
      render_inline(Shared::OAuthIconComponent.new(provider: "Yahoo! JAPAN"))

      assert_match(/viewBox="0 0 512 512"/, rendered_content)
      assert_match(/fill="#FF0033"/, rendered_content) # Yahoo Japan red
    end

    test "renders LINE icon" do
      render_inline(Shared::OAuthIconComponent.new(provider: "LINE"))

      assert_match(/viewBox="0 0 24 24"/, rendered_content)
      assert_match(/fill="#00B900"/, rendered_content) # LINE green
    end

    test "normalizes provider names with spaces and punctuation" do
      # Yahoo! JAPAN with exclamation and space
      render_inline(Shared::OAuthIconComponent.new(provider: "Yahoo! JAPAN"))
      assert_match(/fill="#FF0033"/, rendered_content)

      # yahoojp (lowercase, no spaces)
      render_inline(Shared::OAuthIconComponent.new(provider: "yahoojp"))
      assert_match(/fill="#FF0033"/, rendered_content)
    end

    test "handles unknown provider gracefully" do
      render_inline(Shared::OAuthIconComponent.new(provider: "UnknownProvider"))

      # Should render empty string for unknown providers
      assert_equal "", rendered_content.strip
    end

    test "applies custom HTML options" do
      render_inline(Shared::OAuthIconComponent.new(
        provider: "Google",
        html_options: { class: "custom-class", id: "custom-id" }
      ))

      assert_match(/id="custom-id"/, rendered_content)
      assert_match(/class="me-2 custom-class"/, rendered_content)
    end

    test "includes default me-2 class" do
      render_inline(Shared::OAuthIconComponent.new(provider: "Google"))

      assert_match(/class="me-2"/, rendered_content)
    end

    test "sets aria-hidden attribute" do
      render_inline(Shared::OAuthIconComponent.new(provider: "Google"))

      assert_match(/aria-hidden="true"/, rendered_content)
    end

    test "sets default width and height" do
      render_inline(Shared::OAuthIconComponent.new(provider: "Google"))

      assert_match(/width="18"/, rendered_content)
      assert_match(/height="18"/, rendered_content)
    end

    test "allows custom width and height" do
      render_inline(Shared::OAuthIconComponent.new(
        provider: "Google",
        html_options: { width: "24", height: "24" }
      ))

      assert_match(/width="24"/, rendered_content)
      assert_match(/height="24"/, rendered_content)
    end

    test "handles all provider display names from OAuthHelper" do
      # Test all actual display names that come from OAuthHelper.provider_name
      providers = [
        "Google",
        "GitHub",
        "Microsoft",
        "Facebook",
        "Yahoo! JAPAN",
        "LINE"
      ]

      providers.each do |provider_name|
        render_inline(Shared::OAuthIconComponent.new(provider: provider_name))

        assert_match /<svg/, rendered_content, "Expected SVG for provider: #{provider_name}"
      end
    end
  end
end
