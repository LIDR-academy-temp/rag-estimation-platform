require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @base_url = Rails.application.config.rag_service_base_url
  end

  test "requires authentication" do
    get search_path
    assert_redirected_to login_path
  end

  test "GET search without query renders search form" do
    sign_in users(:antonio)
    get search_path
    assert_response :success
  end

  test "GET search with query calls RAG and renders results" do
    stub_request(:post, "#{@base_url}/api/v1/search")
      .to_return(status: 200, body: {
        results: [
          {
            chunk_id: "c1",
            chunk_type: "scope_block",
            similarity_score: 0.9,
            content_text: "Auth module desc",
            project_title: "Project X",
            technologies: ["Ruby"],
            total_cost: 50000,
            currency: "EUR"
          }
        ],
        total_results: 1,
        query_processing_time_ms: 35.0
      }.to_json, headers: { "Content-Type" => "application/json" })

    sign_in users(:antonio)
    get search_path, params: { q: "authentication" }
    assert_response :success
  end

  test "GET search with filters passes chunk_types" do
    stub_request(:post, "#{@base_url}/api/v1/search")
      .to_return(status: 200, body: {
        results: [], total_results: 0
      }.to_json, headers: { "Content-Type" => "application/json" })

    sign_in users(:antonio)
    get search_path, params: { q: "test", chunk_types: ["scope_block"] }
    assert_response :success
  end

  test "GET search handles RAG unavailable" do
    stub_request(:post, "#{@base_url}/api/v1/search")
      .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    sign_in users(:antonio)
    get search_path, params: { q: "test" }
    assert_response :service_unavailable
  end
end
