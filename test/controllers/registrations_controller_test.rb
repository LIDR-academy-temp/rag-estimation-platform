require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "GET register renders registration form" do
    get register_path
    assert_response :success
    assert_select "input[name='user[email]']"
  end

  test "POST register with valid params creates user and redirects" do
    assert_difference("User.count", 1) do
      post register_path, params: {
        user: { name: "Nuevo", email: "nuevo@example.com", password: "password123" }
      }
    end
    assert_redirected_to dashboard_path
  end

  test "POST register with invalid params re-renders form" do
    assert_no_difference("User.count") do
      post register_path, params: {
        user: { name: "", email: "bad", password: "short" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST register with duplicate email re-renders form" do
    user = users(:antonio)
    assert_no_difference("User.count") do
      post register_path, params: {
        user: { name: "Dup", email: user.email, password: "password123" }
      }
    end
    assert_response :unprocessable_entity
  end
end
