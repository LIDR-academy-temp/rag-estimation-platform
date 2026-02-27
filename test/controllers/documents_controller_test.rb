require "test_helper"

class DocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @base_url = Rails.application.config.rag_service_base_url
  end

  test "requires authentication" do
    get documents_path
    assert_redirected_to login_path
  end

  test "index lists user documents" do
    sign_in users(:antonio)
    get documents_path
    assert_response :success
  end

  test "index with search query filters results" do
    sign_in users(:antonio)
    get documents_path, params: { q: "E-commerce" }
    assert_response :success
  end

  test "index paginates results" do
    sign_in users(:antonio)
    get documents_path, params: { page: 1 }
    assert_response :success
  end

  test "show displays document details" do
    sign_in users(:antonio)
    doc = documents(:completed_doc)
    get document_path(doc)
    assert_response :success
  end

  test "show returns not found for other user document" do
    sign_in users(:antonio)
    doc = documents(:other_user_doc)
    get document_path(doc)
    assert_redirected_to dashboard_path
  end

  test "destroy deletes document and calls RAG" do
    stub_request(:delete, %r{#{@base_url}/api/v1/ingest/})
      .to_return(status: 200, body: { message: "deleted" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    sign_in users(:antonio)
    doc = documents(:completed_doc)
    assert_difference("Document.count", -1) do
      delete document_path(doc)
    end
    assert_redirected_to documents_path
  end

  test "destroy handles RAG delete failure gracefully" do
    stub_request(:delete, %r{#{@base_url}/api/v1/ingest/})
      .to_raise(Faraday::ConnectionFailed.new("Connection refused"))

    sign_in users(:antonio)
    doc = documents(:completed_doc)
    assert_difference("Document.count", -1) do
      delete document_path(doc)
    end
    assert_redirected_to documents_path
  end
end
