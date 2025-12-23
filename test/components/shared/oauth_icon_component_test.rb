# frozen_string_literal: true

require "test_helper"

module Shared
  class OAuthIconComponentTest < ViewComponent::TestCase
    test "renders Google icon" do
      render_inline(Shared::Shared::OAuthIconComponent.new(provider: :google))

      assert_selector "svg[viewBox='0 0 18 18']"
      assert_selector "path[fill='#4285F4']" # Google blue
    end

    test "renders GitHub icon" do
      render_inline(Shared::Shared::OAuthIconComponent.new(provider: :github))

      assert_selector "svg[viewBox='0 0 16 16']"
      assert_selector "svg[fill='currentColor']"
    end

    test "renders Microsoft icon" do
      render_inline(Shared::OAuthIconComponent.new(provider: :microsoft))

      assert_selector "svg[viewBox='0 0 16 16']"
      assert_selector "svg[fill='currentColor']"
    end

    test "renders Facebook icon" do
      render_inline(Shared::OAuthIconComponent.new(provider: :facebook))

      assert_selector "svg[viewBox='0 0 24 24']"
      assert_selector "svg[fill='#1877F2']" # Facebook blue
    end

    test "renders Yahoo Japan icon" do
      render_inline(Shared::OAuthIconComponent.new(provider: :yahoojp))

      assert_selector "svg[viewBox='0 0 24 24']"
      assert_selector "svg[fill='#FF0033']" # Yahoo red
    end

    test "renders LINE icon" do
      render_inline(Shared::OAuthIconComponent.new(provider: :line))

      assert_selector "svg[viewBox='0 0 24 24']"
      assert_selector "svg[fill='#00B900']" # LINE green
    end

    test "handles provider name variations" do
      render_inline(Shared::OAuthIconComponent.new(provider: "yahoo japan"))

      assert_selector "svg[fill='#FF0033']"
    end

    test "returns empty string for unknown provider" do
      render_inline(Shared::OAuthIconComponent.new(provider: :unknown))

      assert_text ""
    end

    test "applies default CSS classes" do
      render_inline(Shared::OAuthIconComponent.new(provider: :google))

      assert_selector "svg.me-2"
    end

    test "merges custom CSS classes" do
      render_inline(Shared::OAuthIconComponent.new(provider: :google, html_options: { class: "custom-class" }))

      assert_selector "svg.me-2.custom-class"
    end

    test "includes aria-hidden attribute" do
      render_inline(Shared::OAuthIconComponent.new(provider: :google))

      assert_selector "svg[aria-hidden='true']"
    end

    test "sets default width and height" do
      render_inline(Shared::OAuthIconComponent.new(provider: :google))

      assert_selector "svg[width='18'][height='18']"
    end
  end
end
