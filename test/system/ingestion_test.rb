require "application_system_test_case"

class IngestionTest < ApplicationSystemTestCase
  setup do
    @base_url = Rails.application.config.rag_service_base_url
    stub_rag_services

    @user = users(:antonio)
    visit login_path
    fill_in "email", with: @user.email
    fill_in "password", with: "password123"
    click_button "Iniciar sesión"
  end

  test "ingest JSON document" do
    stub_request(:post, "#{@base_url}/api/v1/ingest")
      .to_return(status: 200, body: { document_id: "new-uuid", status: "processing" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    visit ingest_path

    json_payload = '{"quote":{"project":{"title":"Test System"},"scope_blocks":[]}}'
    fill_in "raw_json", with: json_payload
    click_button "Ingestar presupuesto"

    assert_text "ingresado correctamente"
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
