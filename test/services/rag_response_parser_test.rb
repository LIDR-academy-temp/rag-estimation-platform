require "test_helper"

class RagResponseParserTest < ActiveSupport::TestCase
  # parse_ingest
  test "parse_ingest extracts document_id and status" do
    response = { "document_id" => "abc-123", "status" => "processing" }
    result = RagResponseParser.parse_ingest(response)

    assert_equal "abc-123", result[:external_document_id]
    assert_equal "processing", result[:status]
  end

  # parse_ingest_status
  test "parse_ingest_status extracts status and chunks" do
    response = {
      "status" => "completed",
      "chunks_created" => 15,
      "breakdown" => {
        "project_overview" => 3,
        "scope_block" => 5,
        "line_item" => 4,
        "phase" => 2,
        "team_conditions" => 1
      }
    }
    result = RagResponseParser.parse_ingest_status(response)

    assert_equal "completed", result[:document][:status]
    assert_equal 15, result[:document][:chunks_count]
    assert_equal 3, result[:breakdown][:project_overview]
    assert_equal 5, result[:breakdown][:scope_block]
  end

  test "parse_ingest_status handles missing breakdown" do
    response = { "status" => "processing", "chunks_created" => 0 }
    result = RagResponseParser.parse_ingest_status(response)

    assert_nil result[:breakdown]
    assert_equal 0, result[:document][:chunks_count]
  end

  # parse_search
  test "parse_search maps results array" do
    response = {
      "results" => [
        {
          "chunk_id" => "c1",
          "chunk_type" => "scope_block",
          "similarity_score" => 0.92,
          "content_text" => "Auth module",
          "project_title" => "Project A",
          "technologies" => ["Ruby"],
          "total_cost" => 50000,
          "currency" => "EUR"
        }
      ],
      "total_results" => 1,
      "query_processing_time_ms" => 45.2,
      "detected_technologies" => ["Ruby"],
      "suggested_chunk_types" => ["scope_block"]
    }
    result = RagResponseParser.parse_search(response)

    assert_equal 1, result[:results].size
    assert_equal "c1", result[:results][0][:chunk_id]
    assert_equal 0.92, result[:results][0][:similarity_score]
    assert_equal "Auth module", result[:results][0][:content_preview]
    assert_equal 1, result[:total]
    assert_in_delta 45.2, result[:processing_time_ms], 0.01
  end

  test "parse_search handles empty results" do
    response = { "results" => [], "total_results" => 0 }
    result = RagResponseParser.parse_search(response)

    assert_empty result[:results]
    assert_equal 0, result[:total]
  end

  test "parse_search handles nil results" do
    response = { "total_results" => 0 }
    result = RagResponseParser.parse_search(response)

    assert_empty result[:results]
  end

  # parse_estimate
  test "parse_estimate extracts estimation attrs blocks and references" do
    estimation = estimations(:draft_estimation)
    response = {
      "estimation" => {
        "estimated_effort" => {
          "optimistic" => { "hours" => 80 },
          "expected" => { "hours" => 120 },
          "pessimistic" => { "hours" => 180 }
        },
        "confidence" => { "score" => 0.82, "level" => "high" },
        "suggested_technologies" => ["Ruby", "Rails"],
        "suggested_breakdown" => [
          {
            "name" => "Auth",
            "tasks" => [
              { "name" => "Login flow", "hours" => 16 },
              { "name" => "Session management", "hours" => 24 }
            ]
          },
          {
            "name" => "Frontend",
            "tasks" => [
              { "name" => "Layout components", "hours" => 32 },
              { "name" => "Form validation", "hours" => 20 },
              { "name" => "Responsive design", "hours" => 28 }
            ]
          }
        ]
      },
      "references" => [
        {
          "chunk_id" => "ref1",
          "chunk_type" => "scope_block",
          "similarity_score" => 0.88,
          "project_title" => "Similar Project",
          "content_preview" => "Preview text",
          "cost" => 40000,
          "currency" => "EUR",
          "technologies" => ["Ruby"]
        }
      ]
    }

    result = RagResponseParser.parse_estimate(response, estimation)

    assert_equal 0.82, result[:estimation][:confidence_score]
    assert_equal "high", result[:estimation][:confidence_level]
    assert_equal 80, result[:estimation][:total_hours_optimistic]
    assert_equal 120, result[:estimation][:total_hours_expected]
    assert_equal 180, result[:estimation][:total_hours_pessimistic]
    assert_nil result[:estimation][:total_cost_optimistic]

    assert_equal 2, result[:blocks].size
    assert_equal "Auth", result[:blocks][0][:name]
    assert_equal 2, result[:blocks][0][:tasks_attributes].size
    assert_equal "Login flow", result[:blocks][0][:tasks_attributes][0][:name]
    assert_equal 16, result[:blocks][0][:tasks_attributes][0][:hours_expected]
    assert_equal "Session management", result[:blocks][0][:tasks_attributes][1][:name]
    assert_equal 24, result[:blocks][0][:tasks_attributes][1][:hours_expected]

    assert_equal "Frontend", result[:blocks][1][:name]
    assert_equal 3, result[:blocks][1][:tasks_attributes].size
    assert_equal "Layout components", result[:blocks][1][:tasks_attributes][0][:name]

    # Verify optimistic/pessimistic ratios are applied (80/120 = 0.667, 180/120 = 1.5)
    assert_in_delta(16 * (80.0 / 120), result[:blocks][0][:tasks_attributes][0][:hours_optimistic], 0.01)
    assert_in_delta(16 * (180.0 / 120), result[:blocks][0][:tasks_attributes][0][:hours_pessimistic], 0.01)

    assert_equal 1, result[:references].size
    assert_equal "ref1", result[:references][0][:chunk_id]
    assert_in_delta 0.88, result[:references][0][:similarity_score], 0.01
  end

  test "parse_estimate raises error without estimation key" do
    estimation = estimations(:draft_estimation)
    response = { "data" => {} }

    assert_raises(RagServiceClient::Error) do
      RagResponseParser.parse_estimate(response, estimation)
    end
  end

  test "parse_estimate handles empty breakdown and references" do
    estimation = estimations(:draft_estimation)
    response = {
      "estimation" => {
        "estimated_effort" => {
          "optimistic" => { "hours" => 10 },
          "expected" => { "hours" => 20 },
          "pessimistic" => { "hours" => 30 }
        },
        "confidence" => {}
      }
    }

    result = RagResponseParser.parse_estimate(response, estimation)
    assert_empty result[:blocks]
    assert_empty result[:references]
  end
end
