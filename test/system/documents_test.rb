require "application_system_test_case"

class DocumentsTest < ApplicationSystemTestCase
  setup do
    @base_url = Rails.application.config.rag_service_base_url
    stub_rag_services

    @user = users(:antonio)
    visit login_path
    fill_in "email", with: @user.email
    fill_in "password", with: "password123"
    click_button "Iniciar sesión"
  end

  test "view documents list" do
    visit documents_path
    assert_text "Proyecto E-commerce"
  end

  test "click document to view details" do
    visit documents_path
    first("a[href='#{document_path(documents(:completed_doc))}']").click
    assert_text "Proyecto E-commerce"
  end

  test "search documents" do
    visit documents_path
    fill_in "q", with: "E-commerce"
    find("input[name='q']").native.send_keys(:return)
    assert_text "Proyecto E-commerce"
  end

  test "delete document" do
    stub_request(:delete, %r{#{@base_url}/api/v1/ingest/})
      .to_return(status: 200, body: { message: "deleted" }.to_json,
                 headers: { "Content-Type" => "application/json" })

    visit documents_path
    accept_confirm do
      first("button[data-turbo-confirm]").click
    end
    assert_text "eliminado correctamente"
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
