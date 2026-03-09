require "test_helper"

class EstimatesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @base_url = Rails.application.config.rag_service_base_url
  end

  test "requires authentication for index" do
    get estimate_path
    assert_redirected_to login_path
  end

  test "requires authentication for new" do
    get new_estimate_path
    assert_redirected_to login_path
  end

  test "GET estimate lists estimations" do
    sign_in users(:antonio)
    get estimate_path
    assert_response :success
  end

  test "GET estimates/new renders form" do
    sign_in users(:antonio)
    get new_estimate_path
    assert_response :success
  end

  test "POST estimates creates estimation without RAG" do
    sign_in users(:antonio)
    assert_difference("Estimation.count", 1) do
      post estimates_path, params: {
        estimation: { title: "Nueva Estimación", description: "Desc", global_rate: 150, currency: "EUR" }
      }
    end
    estimation = Estimation.last
    assert_redirected_to estimate_detail_path(estimation)
    assert_equal "draft", estimation.status
  end

  test "POST estimates with transcriptions calls RAG estimate" do
    stub_request(:post, "#{@base_url}/api/v1/estimate")
      .to_return(status: 200, body: {
        estimation: {
          estimated_effort: {
            optimistic: { hours: 80 },
            expected: { hours: 120 },
            pessimistic: { hours: 180 }
          },
          estimated_cost: {
            optimistic: { amount: 9600 },
            expected: { amount: 14400 },
            pessimistic: { amount: 21600 }
          },
          confidence: { score: 0.8, level: "high" },
          suggested_technologies: ["Ruby"],
          suggested_breakdown: [
            { name: "Auth", tasks: [{ name: "Setup Auth", hours: 40 }] }
          ]
        },
        references: []
      }.to_json, headers: { "Content-Type" => "application/json" })

    sign_in users(:antonio)
    assert_difference("Estimation.count", 1) do
      post estimates_path, params: {
        estimation: {
          title: "Con Transcripción",
          global_rate: 150,
          currency: "EUR",
          raw_transcriptions: ["Esta es una reunión sobre un sistema de autenticación completo"]
        }
      }
    end
    estimation = Estimation.last
    assert_redirected_to estimate_detail_path(estimation)
  end

  test "GET estimates/:id shows estimation with associations" do
    sign_in users(:antonio)
    estimation = estimations(:completed_estimation)
    get estimate_detail_path(estimation)
    assert_response :success
  end

  test "show returns not found for other user estimation" do
    sign_in users(:antonio)
    estimation = estimations(:other_user_estimation)
    get estimate_detail_path(estimation)
    assert_redirected_to dashboard_path
  end

  # --- export_json ---

  test "GET export_json downloads JSON for completed estimation" do
    sign_in users(:antonio)
    estimation = estimations(:completed_estimation)
    get export_estimate_json_path(estimation)

    assert_response :success
    assert_equal "application/json", response.content_type
    assert_match "attachment", response.headers["Content-Disposition"]
    assert_match "estimacion-completa-rag-export.json", response.headers["Content-Disposition"]

    json = JSON.parse(response.body)
    assert json.key?("quote")
    assert json.key?("source")
    assert_equal "platform_export", json["source"]
    assert json["quote"]["project"]["title"].present?
    assert json["quote"]["scope_blocks"].is_a?(Array)

    assert json["quote"]["items"].is_a?(Array), "items should be an Array"
    assert json["quote"].key?("client"), "quote should have client"
    assert json["quote"].key?("currency"), "quote should have currency"

    json["quote"]["scope_blocks"].each do |block|
      assert block.key?("title"), "scope_block missing title"
      assert block.key?("short_description"), "scope_block missing short_description"
      refute block.key?("items"), "scope_block should not contain items"
      refute block.key?("subtotal_hours"), "scope_block should not contain subtotal_hours"
    end
  end

  test "GET export_json redirects for non-completed estimation" do
    sign_in users(:antonio)
    estimation = estimations(:draft_estimation)
    get export_estimate_json_path(estimation)

    assert_redirected_to estimate_detail_path(estimation)
    assert_equal "Solo se puede exportar una estimación completada.", flash[:alert]
  end

  test "GET export_json requires authentication" do
    estimation = estimations(:completed_estimation)
    get export_estimate_json_path(estimation)
    assert_redirected_to login_path
  end

  test "GET export_json rejects other user estimation" do
    sign_in users(:antonio)
    estimation = estimations(:other_user_estimation)
    get export_estimate_json_path(estimation)
    assert_redirected_to dashboard_path
  end

  # --- export_pdf ---

  test "GET export_pdf returns PDF for completed estimation" do
    sign_in users(:antonio)
    estimation = estimations(:completed_estimation)
    get export_estimate_pdf_path(estimation)

    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert_match "inline", response.headers["Content-Disposition"]
    assert_match "estimacion-completa-presupuesto.pdf", response.headers["Content-Disposition"]
    assert response.body.start_with?("%PDF")
  end

  test "GET export_pdf redirects for non-completed estimation" do
    sign_in users(:antonio)
    estimation = estimations(:draft_estimation)
    get export_estimate_pdf_path(estimation)

    assert_redirected_to estimate_detail_path(estimation)
    assert_equal "Solo se puede exportar una estimación completada.", flash[:alert]
  end

  test "GET export_pdf requires authentication" do
    estimation = estimations(:completed_estimation)
    get export_estimate_pdf_path(estimation)
    assert_redirected_to login_path
  end

  test "GET export_pdf rejects other user estimation" do
    sign_in users(:antonio)
    estimation = estimations(:other_user_estimation)
    get export_estimate_pdf_path(estimation)
    assert_redirected_to dashboard_path
  end
end
