# frozen_string_literal: true

module Shared
  # Renders OAuth provider icons as SVG
  #
  # @example Basic usage
  #   <%= render Shared::OAuthIconComponent.new(provider: :google) %>
  #
  # @example With custom class
  #   <%= render Shared::OAuthIconComponent.new(provider: :github, html_options: { class: "me-3" }) %>
  class OAuthIconComponent < ViewComponent::Base
    # @param provider [String, Symbol] OAuth provider name (google, github, microsoft, facebook, yahoojp, line)
    # @param html_options [Hash] Additional HTML attributes for the SVG element
    def initialize(provider:, html_options: {})
      @provider = provider.to_s.downcase
      @html_options = html_options
    end

    # Returns combined CSS classes for the icon
    # @return [String]
    def css_classes
      default_classes = "me-2"
      custom_classes = @html_options[:class]
      [ default_classes, custom_classes ].compact.join(" ")
    end

    # Returns html_options without class since we handle it separately
    # @return [Hash]
    def html_attrs
      base_attrs = { width: "18", height: "18", "aria-hidden": "true" }
      base_attrs.merge(@html_options.except(:class))
    end

    # Returns the SVG content based on provider
    # @return [String] HTML-safe SVG content
    def svg_content
      case normalized_provider
      when "google"
        google_svg
      when "github"
        github_svg
      when "microsoft"
        microsoft_svg
      when "facebook"
        facebook_svg
      when "yahoojp", "yahoojapan"
        yahoo_japan_svg
      when "line"
        line_svg
      else
        ""
      end
    end

    private

    def normalized_provider
      # Remove spaces and punctuation, convert to lowercase
      @provider.downcase.gsub(/[^a-z]/, "")
    end

    def google_svg
      tag.svg(**html_attrs, viewBox: "0 0 18 18", class: css_classes) do
        safe_join([
          tag.path(nil, fill: "#4285F4", d: "M16.51 8H8.98v3h4.3c-.18 1-.74 1.48-1.6 2.04v2.01h2.6a7.8 7.8 0 0 0 2.38-5.88c0-.57-.05-.66-.15-1.18"),
          tag.path(nil, fill: "#34A853", d: "M8.98 17c2.16 0 3.97-.72 5.3-1.94l-2.6-2.04a4.8 4.8 0 0 1-2.7.75 4.8 4.8 0 0 1-4.52-3.36H1.83v2.07A8 8 0 0 0 8.98 17"),
          tag.path(nil, fill: "#FBBC05", d: "M4.46 10.41a4.8 4.8 0 0 1-.25-1.41c0-.49.09-.97.25-1.41V5.52H1.83a8 8 0 0 0 0 7.37l2.63-2.48"),
          tag.path(nil, fill: "#EA4335", d: "M8.98 3.58c1.32 0 2.5.45 3.44 1.35l2.54-2.59A8 8 0 0 0 8.98 1a8 8 0 0 0-7.15 4.48l2.63 2.52c.61-1.85 2.35-3.42 4.52-3.42")
        ])
      end
    end

    def github_svg
      tag.svg(**html_attrs, viewBox: "0 0 16 16", fill: "currentColor", class: css_classes) do
        tag.path(nil, d: "M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.012 8.012 0 0 0 16 8c0-4.42-3.58-8-8-8z")
      end
    end

    def microsoft_svg
      tag.svg(**html_attrs, viewBox: "0 0 16 16", fill: "currentColor", class: css_classes) do
        tag.path(nil, d: "M7.462 0H0v7.19h7.462V0zM16 0H8.538v7.19H16V0zM7.462 8.211H0V16h7.462V8.211zm8.538 0H8.538V16H16V8.211z")
      end
    end

    def facebook_svg
      tag.svg(**html_attrs, viewBox: "0 0 24 24", fill: "#1877F2", class: css_classes) do
        tag.path(nil, d: "M24 12.073c0-6.627-5.373-12-12-12s-12 5.373-12 12c0 5.99 4.388 10.954 10.125 11.854v-8.385H7.078v-3.47h3.047V9.43c0-3.007 1.792-4.669 4.533-4.669 1.312 0 2.686.235 2.686.235v2.953H15.83c-1.491 0-1.956.925-1.956 1.874v2.25h3.328l-.532 3.47h-2.796v8.385C19.612 23.027 24 18.062 24 12.073z")
      end
    end

    def yahoo_japan_svg
      tag.svg(**html_attrs, viewBox: "0 0 512 512", fill: "#FF0033", class: css_classes) do
        tag.path(nil, d: "M403.867 170.4L414.587 153.39H247.96L250.756 171.565C253.708 171.565 261.71 172.419 274.76 174.128C287.811 175.837 296.977 177.235 302.259 178.322C301.793 182.983 295.152 191.022 282.334 202.44C269.517 213.858 256 225.237 241.784 236.577C227.568 247.917 219.528 254.908 217.664 257.549C214.246 252.578 201.817 236.189 180.377 208.382C158.937 180.575 142.934 158.982 132.37 143.603C136.409 142.515 146.935 141.35 163.947 140.107C180.959 138.865 190.709 138.01 193.194 137.544L195.991 121H2.09741L0 138.476C2.79654 139.098 12.7786 140.535 29.9463 142.787C47.1139 145.04 56.7853 146.554 58.9604 147.331C69.2144 155.098 89.6058 177.895 120.135 215.722C150.664 253.548 167.016 275.569 169.191 281.782V341.435C169.191 345.94 167.637 349.474 164.53 352.037C161.423 354.601 157.072 356.659 151.479 358.212C138.118 361.941 125.456 363.261 113.493 362.174L108.599 381.98C117.765 382.291 126.621 382.446 135.166 382.446C143.711 382.446 155.014 382.33 169.074 382.097C183.135 381.864 191.796 381.747 195.059 381.747C257.204 381.747 289.908 381.98 293.171 382.446L295.501 360.077L237.939 356.115C237.162 309.822 237.162 284.656 237.939 280.617C239.959 274.87 250.135 263.801 268.468 247.412C286.801 231.023 305.211 215.8 323.7 201.741C342.188 187.682 353.296 180.187 357.025 179.255C385.767 173.817 401.381 170.866 403.867 170.4ZM512 171.798L421.112 326.289L389.651 317.434L440.222 150.127L512 171.798ZM354.928 380.582L395.477 392L411.091 357.28L369.376 345.629L354.928 380.582Z")
      end
    end

    def line_svg
      tag.svg(**html_attrs, viewBox: "0 0 24 24", fill: "#00B900", class: css_classes) do
        tag.path(nil, d: "M19.365 9.863c.349 0 .63.285.63.631 0 .345-.281.63-.63.63H17.61v1.125h1.755c.349 0 .63.283.63.63 0 .344-.281.629-.63.629h-2.386c-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.627-.63h2.386c.349 0 .63.285.63.63 0 .349-.281.63-.63.63H17.61v1.125h1.755zm-3.855 3.016c0 .27-.174.51-.432.596-.064.021-.133.031-.199.031-.211 0-.391-.09-.51-.25l-2.443-3.317v2.94c0 .344-.279.629-.631.629-.346 0-.626-.285-.626-.629V8.108c0-.27.173-.51.43-.595.06-.023.136-.033.194-.033.195 0 .375.104.495.254l2.462 3.33V8.108c0-.345.282-.63.63-.63.345 0 .63.285.63.63v4.771zm-5.741 0c0 .344-.282.629-.631.629-.345 0-.627-.285-.627-.629V8.108c0-.345.282-.63.627-.63.349 0 .631.285.631.63v4.771zm-2.466.629H4.917c-.345 0-.63-.285-.63-.629V8.108c0-.345.285-.63.63-.63.348 0 .63.285.63.63v4.141h1.756c.348 0 .629.283.629.63 0 .344-.282.629-.629.629M24 10.314C24 4.943 18.615.572 12 .572S0 4.943 0 10.314c0 4.811 4.27 8.842 10.035 9.608.391.082.923.258 1.058.59.12.301.079.766.038 1.08l-.164 1.02c-.045.301-.24 1.186 1.049.645 1.291-.539 6.916-4.078 9.436-6.975C23.176 14.393 24 12.458 24 10.314")
      end
    end
  end
end
