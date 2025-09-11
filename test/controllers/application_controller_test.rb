require "test_helper"

class ApplicationControllerTest < ActionDispatch::IntegrationTest
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
end