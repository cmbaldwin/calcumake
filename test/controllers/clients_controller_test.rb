require "test_helper"

class ClientsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get clients_index_url
    assert_response :success
  end

  test "should get show" do
    get clients_show_url
    assert_response :success
  end

  test "should get new" do
    get clients_new_url
    assert_response :success
  end

  test "should get edit" do
    get clients_edit_url
    assert_response :success
  end
end
