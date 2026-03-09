require "application_system_test_case"

class EstimationWizardTest < ApplicationSystemTestCase
  setup do
    @base_url = Rails.application.config.rag_service_base_url
    stub_rag_services

    @user = users(:antonio)
    visit login_path
    fill_in "email", with: @user.email
    fill_in "password", with: "password123"
    click_button "Iniciar sesión"
  end

  test "create estimation with transcription" do
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
            { name: "Auth Module", tasks: [{ name: "Setup Auth", hours: 40 }] }
          ]
        },
        references: []
      }.to_json, headers: { "Content-Type" => "application/json" })

    visit new_estimate_path

    fill_in "estimation[title]", with: "Test Estimation"

    # Add transcription via textarea
    textarea = find("[data-transcription-target='input']")
    textarea.fill_in with: "Necesitamos un sistema de autenticación completo con OAuth"
    click_button "Añadir"

    click_button "Generar estimación"

    assert_text "Estimación creada correctamente"
  end

  test "view estimation detail" do
    estimation = estimations(:completed_estimation)
    visit estimate_detail_path(estimation)

    assert_text estimation.title
    assert_text "Autenticación"
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
