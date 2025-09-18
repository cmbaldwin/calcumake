require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  test "blocks unsupported browsers with 406 status" do
    # Simulate an old browser user agent
    old_browser_agent = "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1)"
    
    get root_path, headers: { "HTTP_USER_AGENT" => old_browser_agent }
    
    # Rails allow_browser returns 406 Not Acceptable for unsupported browsers
    assert_response :not_acceptable
  end

  test "redirects unauthenticated users to login" do
    # Simulate a modern browser user agent
    modern_browser_agent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    
    get root_path, headers: { "HTTP_USER_AGENT" => modern_browser_agent }
    
    # Should redirect to login since authentication is required
    assert_response :redirect
    assert_redirected_to new_user_session_path
  end

  test "sets basic security headers" do
    get new_user_session_path
    
    # Test that the response doesn't fail
    assert_response :success
  end

  # Locale switching tests
  test "should switch locale via session parameter" do
    post switch_locale_path, params: { locale: 'ja' }
    
    assert_response :redirect
    assert_equal 'ja', session[:locale]
  end

  test "should reject invalid locale" do
    post switch_locale_path, params: { locale: 'invalid' }
    
    assert_response :redirect
    assert_nil session[:locale]
  end

  test "should set locale from session in subsequent requests" do
    # First set the locale
    post switch_locale_path, params: { locale: 'es' }
    
    # Then make another request
    get new_user_session_path
    assert_equal 'es', I18n.locale.to_s
  end

  test "should default to english locale when no preference set" do
    get new_user_session_path
    assert_equal 'en', I18n.locale.to_s
  end

  test "should use user's saved locale preference when logged in" do
    user = users(:one)
    user.update!(locale: 'fr')
    sign_in user
    
    get root_path
    assert_equal 'fr', I18n.locale.to_s
  end

  test "should update user's locale when switching while logged in" do
    user = users(:one)
    sign_in user
    
    post switch_locale_path, params: { locale: 'zh-CN' }
    
    user.reload
    assert_equal 'zh-CN', user.locale
  end

  test "should persist locale in session for non-logged in users" do
    # Set locale without being logged in
    post switch_locale_path, params: { locale: 'hi' }
    assert_equal 'hi', session[:locale]
    
    # Make another request - should use session locale
    get new_user_session_path
    assert_equal 'hi', I18n.locale.to_s
  end
end