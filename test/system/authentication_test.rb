require "application_system_test_case"

class AuthenticationTest < ApplicationSystemTestCase
  setup do
    @base_url = Rails.application.config.rag_service_base_url
    stub_rag_services
  end

  test "register new user" do
    visit register_path
    fill_in "user[name]", with: "Nuevo Usuario"
    fill_in "user[email]", with: "nuevo@example.com"
    fill_in "user[password]", with: "password123"
    click_button "Crear cuenta"

    assert_current_path dashboard_path
  end

  test "login with valid credentials" do
    user = users(:antonio)
    visit login_path
    fill_in "email", with: user.email
    fill_in "password", with: "password123"
    click_button "Iniciar sesión"

    assert_current_path dashboard_path
  end

  test "logout redirects to login" do
    login_as users(:antonio)
    find("[data-action='sidebar#toggle']", visible: :all)
    click_button "Cerrar sesión"

    assert_current_path login_path
  end

  test "auth guard redirects to login" do
    visit dashboard_path
    assert_current_path login_path
  end

  private

  def login_as(user)
    visit login_path
    fill_in "email", with: user.email
    fill_in "password", with: "password123"
    click_button "Iniciar sesión"
  end

  def stub_rag_services
    stub_request(:get, "#{@base_url}/api/v1/health")
      .to_return(status: 200, body: { status: "healthy", dependencies: {} }.to_json,
                 headers: { "Content-Type" => "application/json" })
    stub_request(:get, "#{@base_url}/api/v1/stats")
      .to_return(status: 200, body: { documents_count: 0, search_metrics_last_30d: { total_searches: 0, avg_response_time_ms: 0 } }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end
end
