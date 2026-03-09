require "test_helper"

class IngestControllerTest < ActionDispatch::IntegrationTest
  setup do
    @base_url = Rails.application.config.rag_service_base_url
  end

  test "requires authentication" do
    get ingest_path
    assert_redirected_to login_path
  end

  test "GET ingest lists documents" do
    sign_in users(:antonio)
    get ingest_path
    assert_response :success
  end

  test "POST ingest with valid JSON creates document and calls RAG" do
    stub_request(:post, "#{@base_url}/api/v1/ingest")
      .to_return(status: 200, body: { document_id: "new-uuid", status: "processing" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    sign_in users(:antonio)
    raw_json = { quote: { project: { title: "Test Project" }, scope_blocks: [{ technologies: ["Ruby"] }] } }.to_json

    assert_difference("Document.count", 1) do
      post ingest_path, params: { raw_json: raw_json }
    end
    assert_redirected_to ingest_path
    assert_match "ingresado correctamente", flash[:notice]
  end

  test "POST ingest with blank JSON redirects with alert" do
    sign_in users(:antonio)
    post ingest_path, params: { raw_json: "" }
    assert_redirected_to ingest_path
    assert flash[:alert].present?
  end

  test "POST ingest with invalid JSON redirects with alert" do
    sign_in users(:antonio)
    post ingest_path, params: { raw_json: "not json{}" }
    assert_redirected_to ingest_path
    assert flash[:alert].present?
  end

  test "POST ingest handles RAG failure gracefully" do
    stub_request(:post, "#{@base_url}/api/v1/ingest")
      .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    sign_in users(:antonio)
    raw_json = { quote: { project: { title: "Test" } } }.to_json

    assert_difference("Document.count", 1) do
      post ingest_path, params: { raw_json: raw_json }
    end
    assert_redirected_to ingest_path
    assert_match /servicio RAG/, flash[:alert]
  end
end
