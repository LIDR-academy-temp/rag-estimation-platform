require "test_helper"

class RagServiceClientTest < ActiveSupport::TestCase
  setup do
    @base_url = "http://localhost:8000"
    @client = RagServiceClient.new(base_url: @base_url)
  end

  # health
  test "health returns parsed response" do
    stub_request(:get, "#{@base_url}/api/v1/health")
      .to_return(status: 200, body: { status: "healthy", dependencies: {} }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = @client.health
    assert_equal "healthy", result["status"]
  end

  # ingest
  test "ingest sends POST and returns response" do
    payload = { quote: { project: { title: "Test" } }, source: "web", ingested_by: "test@example.com" }
    stub_request(:post, "#{@base_url}/api/v1/ingest")
      .with(body: payload.to_json)
      .to_return(status: 200, body: { document_id: "abc-123", status: "processing" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = @client.ingest(payload)
    assert_equal "abc-123", result["document_id"]
    assert_equal "processing", result["status"]
  end

  test "ingest handles 409 conflict" do
    stub_request(:post, "#{@base_url}/api/v1/ingest")
      .to_return(status: 409, body: { detail: "Document already exists" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    assert_raises(RagServiceClient::Error) { @client.ingest({}) }
  end

  # ingest_status
  test "ingest_status returns status info" do
    doc_id = "abc-123"
    stub_request(:get, "#{@base_url}/api/v1/ingest/#{doc_id}/status")
      .to_return(status: 200, body: { status: "completed", chunks_created: 10, breakdown: { project_overview: 3 } }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = @client.ingest_status(doc_id)
    assert_equal "completed", result["status"]
    assert_equal 10, result["chunks_created"]
  end

  # delete_document
  test "delete_document sends DELETE" do
    doc_id = "abc-123"
    stub_request(:delete, "#{@base_url}/api/v1/ingest/#{doc_id}")
      .to_return(status: 200, body: { message: "deleted" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = @client.delete_document(doc_id)
    assert_equal "deleted", result["message"]
  end

  # search
  test "search sends POST with query and filters" do
    stub_request(:post, "#{@base_url}/api/v1/search")
      .with(body: { query: "authentication", top_k: 10, min_similarity: 0.6 }.to_json)
      .to_return(status: 200, body: { results: [{ chunk_id: "1", similarity_score: 0.9 }], total_results: 1 }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = @client.search(query: "authentication")
    assert_equal 1, result["total_results"]
    assert_equal 1, result["results"].size
  end

  # estimate
  test "estimate sends POST and returns estimation" do
    stub_request(:post, "#{@base_url}/api/v1/estimate")
      .to_return(status: 200, body: { estimation: { estimated_effort: { expected: { hours: 100 } } } }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = @client.estimate(query: "build auth system")
    assert result["estimation"].present?
  end

  # estimate_batch
  test "estimate_batch sends POST with multiple queries" do
    stub_request(:post, "#{@base_url}/api/v1/estimate/batch")
      .to_return(status: 200, body: { estimations: [] }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = @client.estimate_batch(queries: ["query1", "query2"])
    assert result.key?("estimations")
  end

  # stats
  test "stats returns service statistics" do
    stub_request(:get, "#{@base_url}/api/v1/stats")
      .to_return(status: 200, body: { documents_count: 50, search_metrics_last_30d: { total_searches: 120 } }.to_json,
                 headers: { "Content-Type" => "application/json" })

    result = @client.stats
    assert_equal 50, result["documents_count"]
  end

  # Error handling
  test "timeout raises TimeoutError" do
    stub_request(:get, "#{@base_url}/api/v1/health")
      .to_raise(Faraday::TimeoutError.new("timeout"))

    assert_raises(RagServiceClient::TimeoutError) { @client.health }
  end

  test "connection failed raises ServiceUnavailableError" do
    stub_request(:get, "#{@base_url}/api/v1/health")
      .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    assert_raises(RagServiceClient::ServiceUnavailableError) { @client.health }
  end

  test "404 raises NotFoundError" do
    stub_request(:get, "#{@base_url}/api/v1/ingest/missing/status")
      .to_return(status: 404, body: { detail: "Not found" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    assert_raises(RagServiceClient::NotFoundError) { @client.ingest_status("missing") }
  end

  test "503 raises ServiceUnavailableError" do
    stub_request(:get, "#{@base_url}/api/v1/health")
      .to_return(status: 503, body: { detail: "Service unavailable" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    assert_raises(RagServiceClient::ServiceUnavailableError) { @client.health }
  end
end
