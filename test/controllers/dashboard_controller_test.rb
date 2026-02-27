require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @base_url = Rails.application.config.rag_service_base_url
  end

  test "requires authentication" do
    get dashboard_path
    assert_redirected_to login_path
  end

  test "renders dashboard with RAG stubs" do
    stub_request(:get, "#{@base_url}/api/v1/health")
      .to_return(status: 200, body: { status: "healthy", dependencies: {} }.to_json,
                 headers: { "Content-Type" => "application/json" })
    stub_request(:get, "#{@base_url}/api/v1/stats")
      .to_return(status: 200, body: { documents_count: 5, search_metrics_last_30d: { total_searches: 10, avg_response_time_ms: 50.0 } }.to_json,
                 headers: { "Content-Type" => "application/json" })

    sign_in users(:antonio)
    get dashboard_path
    assert_response :success
  end

  test "handles RAG unavailable gracefully" do
    stub_request(:get, "#{@base_url}/api/v1/health")
      .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    sign_in users(:antonio)
    get dashboard_path
    assert_response :success
  end
end
