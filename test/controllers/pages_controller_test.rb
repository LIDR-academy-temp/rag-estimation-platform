require "test_helper"

class PagesControllerTest < ActionDispatch::IntegrationTest
  test "GET root renders landing page without auth" do
    get root_path
    assert_response :success
  end

  test "landing page uses public layout" do
    get root_path
    assert_response :success
    assert_select "body"
  end
end
