require "test_helper"

class OauthButtonsViewTest < ActionView::TestCase
  test "renders OAuth buttons partial with all provider buttons" do
    rendered = render partial: "devise/shared/oauth_buttons"

    # Test overall structure
    assert_select ".oauth-buttons.mb-4", 1
    assert_select ".oauth-buttons .row.g-2", 1

    # Test that all six provider buttons are rendered
    assert_select ".col-12", 6

    # Test Google OAuth button
    assert_select "a[href='#{user_google_oauth2_omniauth_authorize_path}']", 1 do
      assert_select "span", text: I18n.t("devise.shared.sign_in_with_provider", provider: "Google")
    end

    # Test GitHub OAuth button
    assert_select "a[href='#{user_github_omniauth_authorize_path}']", 1 do
      assert_select "span", text: I18n.t("devise.shared.sign_in_with_provider", provider: "GitHub")
    end

    # Test Microsoft OAuth button
    assert_select "a[href='#{user_microsoft_graph_omniauth_authorize_path}']", 1 do
      assert_select "span", text: I18n.t("devise.shared.sign_in_with_provider", provider: "Microsoft")
    end

    # Test Facebook OAuth button
    assert_select "a[href='#{user_facebook_omniauth_authorize_path}']", 1 do
      assert_select "span", text: I18n.t("devise.shared.sign_in_with_provider", provider: "Facebook")
    end

    # Test Yahoo Japan OAuth button
    assert_select "a[href='#{user_yahoojp_omniauth_authorize_path}']", 1 do
      assert_select "span", text: I18n.t("devise.shared.sign_in_with_provider", provider: "Yahoo! JAPAN")
    end

    # Test LINE OAuth button
    assert_select "a[href='#{user_line_omniauth_authorize_path}']", 1 do
      assert_select "span", text: I18n.t("devise.shared.sign_in_with_provider", provider: "LINE")
    end

    # Test separator text
    assert_select ".text-center.my-3 small.text-muted", 1 do
      assert_select "small", text: I18n.t("devise.shared.or_sign_in_with_email")
    end
  end

  test "OAuth buttons have correct CSS classes" do
    rendered = render partial: "devise/shared/oauth_buttons"

    # Test button classes are applied correctly through helper methods
    assert_select "a.btn.btn-outline-danger", 2  # Google + Yahoo Japan
    assert_select "a.btn.btn-outline-dark", 1    # GitHub
    assert_select "a.btn.btn-outline-primary", 2 # Microsoft + Facebook
    assert_select "a.btn.btn-outline-success", 1 # LINE

    # Test common button classes
    assert_select "a.w-100.d-flex.align-items-center.justify-content-center", 6
  end

  test "OAuth buttons have correct accessibility attributes" do
    rendered = render partial: "devise/shared/oauth_buttons"

    # Test ARIA attributes
    assert_select ".oauth-buttons[role='group'][aria-labelledby='oauth-signin-heading']", 1
    assert_select "#oauth-signin-heading.visually-hidden", 1

    # Test individual button accessibility
    assert_select "a[role='button']", 6
    assert_select "a[aria-label]", 6

    # Test tooltip attributes
    assert_select "a[data-bs-toggle='tooltip']", 6
    assert_select "a[data-bs-placement='top']", 6
    assert_select "a[data-bs-title]", 6
  end

  test "OAuth buttons use POST method" do
    rendered = render partial: "devise/shared/oauth_buttons"

    # All OAuth buttons should use POST method
    assert_select "a[data-method='post']", 6
  end

  test "OAuth buttons include provider icons" do
    rendered = render partial: "devise/shared/oauth_buttons"

    # Test that SVG icons are rendered for each provider
    assert_select "svg", 6

    # Test specific icon attributes
    assert_select "svg[width='18'][height='18']", 6
    assert_select "svg.me-2", 6
    assert_select "svg[aria-hidden='true']", 6
  end

  test "OAuth buttons text is properly internationalized" do
    # Test with different locales
    original_locale = I18n.locale

    begin
      # Test English
      I18n.locale = :en
      rendered = render partial: "devise/shared/oauth_buttons"
      assert_includes rendered, "Sign in with Google"
      assert_includes rendered, "Sign in with GitHub"
      assert_includes rendered, "Sign in with Microsoft"
      assert_includes rendered, "or sign in with email"

      # Test Spanish (if translations exist)
      if I18n.available_locales.include?(:es)
        I18n.locale = :es
        rendered = render partial: "devise/shared/oauth_buttons"
        assert_includes rendered, I18n.t("devise.shared.sign_in_with_provider", provider: "Google")
        assert_includes rendered, I18n.t("devise.shared.or_sign_in_with_email")
      end

      # Test Japanese (if translations exist)
      if I18n.available_locales.include?(:ja)
        I18n.locale = :ja
        rendered = render partial: "devise/shared/oauth_buttons"
        assert_includes rendered, I18n.t("devise.shared.sign_in_with_provider", provider: "Google")
        assert_includes rendered, I18n.t("devise.shared.or_sign_in_with_email")
      end
    ensure
      I18n.locale = original_locale
    end
  end

  test "OAuth buttons partial works without application controller context" do
    # Test that the partial renders successfully in isolation
    assert_nothing_raised do
      render partial: "devise/shared/oauth_buttons"
    end
  end

  test "OAuth buttons render correct provider configuration" do
    rendered = render partial: "devise/shared/oauth_buttons"

    # Verify the provider configuration array is used correctly
    providers = [
      { name: "Google", path_method: :user_google_oauth2_omniauth_authorize_path },
      { name: "GitHub", path_method: :user_github_omniauth_authorize_path },
      { name: "Microsoft", path_method: :user_microsoft_graph_omniauth_authorize_path },
      { name: "Facebook", path_method: :user_facebook_omniauth_authorize_path },
      { name: "Yahoo! JAPAN", path_method: :user_yahoojp_omniauth_authorize_path },
      { name: "LINE", path_method: :user_line_omniauth_authorize_path }
    ]

    providers.each do |provider|
      # Test provider-specific content exists
      assert_includes rendered, provider[:name]

      # Test link to correct OAuth authorization path exists
      path = send(provider[:path_method])
      assert_select "a[href='#{path}']", 1
    end
  end

  test "OAuth separator has proper accessibility markup" do
    rendered = render partial: "devise/shared/oauth_buttons"

    # Test separator accessibility
    assert_select "small[role='separator']", 1
    assert_select "small[aria-label]", 1
  end

  test "OAuth buttons maintain Bootstrap 5 compatibility" do
    rendered = render partial: "devise/shared/oauth_buttons"

    # Test Bootstrap 5 specific classes and structure
    assert_select ".row.g-2", 1  # Bootstrap 5 gap utility
    assert_select ".col-12", 6   # Bootstrap 5 grid system
    assert_select ".d-flex.align-items-center.justify-content-center", 6  # Bootstrap 5 flexbox utilities
    assert_select ".text-muted", 1  # Bootstrap 5 text utility
    assert_select ".visually-hidden", 1  # Bootstrap 5 screen reader utility
  end

  test "OAuth buttons work with all supported authentication providers" do
    rendered = render partial: "devise/shared/oauth_buttons"

    # Verify all configured Devise omniauth providers are represented
    expected_providers = User.omniauth_providers.map(&:to_s)

    # Test that we have buttons for all 6 OAuth providers
    assert_includes expected_providers, "google_oauth2"
    assert_includes expected_providers, "github"
    assert_includes expected_providers, "microsoft_graph"
    assert_includes expected_providers, "facebook"
    assert_includes expected_providers, "yahoojp"
    assert_includes expected_providers, "line"

    # Verify each provider has its button rendered
    assert_select "a[href*='google_oauth2']", 1
    assert_select "a[href*='github']", 1
    assert_select "a[href*='microsoft_graph']", 1
    assert_select "a[href*='facebook']", 1
    assert_select "a[href*='yahoojp']", 1
    assert_select "a[href*='line']", 1
  end

  private

  def user_google_oauth2_omniauth_authorize_path
    "/users/auth/google_oauth2"
  end

  def user_github_omniauth_authorize_path
    "/users/auth/github"
  end

  def user_microsoft_graph_omniauth_authorize_path
    "/users/auth/microsoft_graph"
  end

  def user_facebook_omniauth_authorize_path
    "/users/auth/facebook"
  end

  def user_yahoojp_omniauth_authorize_path
    "/users/auth/yahoojp"
  end

  def user_line_omniauth_authorize_path
    "/users/auth/line"
  end
end
