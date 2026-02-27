require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "GET login renders login form" do
    get login_path
    assert_response :success
    assert_select "input[name='email']"
  end

  test "POST login with valid credentials redirects to dashboard" do
    user = users(:antonio)
    post login_path, params: { email: user.email, password: "password123" }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_response :success
  end

  test "POST login with invalid credentials re-renders form" do
    post login_path, params: { email: "bad@example.com", password: "wrong" }
    assert_response :unprocessable_entity
  end

  test "POST login with wrong password re-renders form" do
    user = users(:antonio)
    post login_path, params: { email: user.email, password: "wrongpassword" }
    assert_response :unprocessable_entity
  end

  test "DELETE logout clears session and redirects to login" do
    sign_in users(:antonio)
    delete logout_path
    assert_redirected_to login_path
  end
end
