require "application_system_test_case"

class SearchTest < ApplicationSystemTestCase
  setup do
    @base_url = Rails.application.config.rag_service_base_url
    stub_rag_services

    @user = users(:antonio)
    visit login_path
    fill_in "email", with: @user.email
    fill_in "password", with: "password123"
    click_button "Iniciar sesión"
  end

  test "search with query shows results" do
    stub_request(:post, "#{@base_url}/api/v1/search")
      .to_return(status: 200, body: {
        results: [
          {
            chunk_id: "c1",
            chunk_type: "scope_block",
            similarity_score: 0.9,
            content_text: "Authentication module with OAuth2",
            project_title: "E-commerce Platform",
            technologies: ["Ruby", "Rails"],
            total_cost: 50000,
            currency: "EUR"
          }
        ],
        total_results: 1,
        query_processing_time_ms: 35.0
      }.to_json, headers: { "Content-Type" => "application/json" })

    visit search_path
    fill_in "q", with: "authentication"
    click_button "Buscar"

    assert_text "1 resultado"
    assert_text "Authentication module with OAuth2"
  end

  private

  def stub_rag_services
    stub_request(:get, "#{@base_url}/api/v1/health")
      .to_return(status: 200, body: { status: "healthy", dependencies: {} }.to_json,
                 headers: { "Content-Type" => "application/json" })
    stub_request(:get, "#{@base_url}/api/v1/stats")
      .to_return(status: 200, body: { documents_count: 0, search_metrics_last_30d: { total_searches: 0, avg_response_time_ms: 0 } }.to_json,
                 headers: { "Content-Type" => "application/json" })
  end
end
