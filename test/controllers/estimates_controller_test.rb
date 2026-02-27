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
            { name: "Auth", days: 5, unit_price: 130 }
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
end
