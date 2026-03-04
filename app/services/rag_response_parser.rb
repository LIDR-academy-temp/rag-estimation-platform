class RagResponseParser
  def self.parse_ingest(response)
    {
      external_document_id: response["document_id"],
      status: response["status"]
    }
  end

  def self.parse_ingest_status(response)
    {
      document: {
        status: response["status"],
        chunks_count: response["chunks_created"] || 0
      },
      breakdown: response["breakdown"] ? {
        project_overview: response.dig("breakdown", "project_overview") || 0,
        scope_block: response.dig("breakdown", "scope_block") || 0,
        line_item: response.dig("breakdown", "line_item") || 0,
        phase: response.dig("breakdown", "phase") || 0,
        team_conditions: response.dig("breakdown", "team_conditions") || 0
      } : nil
    }
  end

  def self.parse_search(response)
    {
      results: (response["results"] || []).map do |r|
        {
          chunk_id: r["chunk_id"],
          chunk_type: r["chunk_type"],
          similarity_score: r["similarity_score"],
          content_preview: r["content_text"],
          project_title: r["project_title"],
          technologies: r["technologies"],
          cost: r["total_cost"],
          currency: r["currency"]
        }
      end,
      total: response["total_results"],
      processing_time_ms: response["query_processing_time_ms"],
      detected_technologies: response["detected_technologies"],
      suggested_chunk_types: response["suggested_chunk_types"]
    }
  end

  def self.parse_estimate(response, estimation)
    detail = response["estimation"]
    raise RagServiceClient::Error, "Unexpected RAG response: missing 'estimation' key" unless detail.is_a?(Hash)

    effort = detail["estimated_effort"] || {}
    confidence = detail["confidence"] || {}

    notes = detail["notes"]
    summary_parts = [detail["summary"], notes].compact
    description = summary_parts.join("\n\n") if summary_parts.any?

    estimation_attrs = {
      description: description,
      confidence_score: confidence["score"],
      confidence_level: confidence["level"],
      technologies: detail["suggested_technologies"],
      total_hours_optimistic: effort.dig("optimistic", "hours") || 0,
      total_hours_expected: effort.dig("expected", "hours") || 0,
      total_hours_pessimistic: effort.dig("pessimistic", "hours") || 0
    }

    expected_hours = effort.dig("expected", "hours").to_f
    optimistic_ratio = expected_hours > 0 ? effort.dig("optimistic", "hours").to_f / expected_hours : 1.0
    pessimistic_ratio = expected_hours > 0 ? effort.dig("pessimistic", "hours").to_f / expected_hours : 1.0

    blocks_attrs = (detail["suggested_breakdown"] || []).map.with_index do |block, i|
      tasks = (block["tasks"] || []).map.with_index do |task, j|
        task_hours = task["hours"] || 0
        {
          name: task["name"],
          hours_optimistic: (task_hours * optimistic_ratio).round(2),
          hours_expected: task_hours,
          hours_pessimistic: (task_hours * pessimistic_ratio).round(2),
          position: j
        }
      end
      { name: block["name"], position: i, tasks_attributes: tasks }
    end

    references_attrs = (response["references"] || []).map do |ref|
      {
        chunk_id: ref["chunk_id"],
        chunk_type: ref["chunk_type"],
        similarity_score: ref["similarity_score"],
        title: ref["project_title"],
        content_preview: ref["content_preview"],
        cost: ref["cost"],
        currency: ref["currency"],
        technologies: ref["technologies"]
      }
    end

    { estimation: estimation_attrs, blocks: blocks_attrs, references: references_attrs }
  rescue NoMethodError, TypeError => e
    raise RagServiceClient::Error, "Failed to parse RAG estimate response: #{e.message}"
  end

  def self.parse_validation(response)
    (response["validated_breakdown"] || []).map do |block|
      {
        name: block["name"],
        tasks: (block["tasks"] || []).map do |task|
          {
            name: task["name"],
            hours: task["hours"],
            original_hours: task["original_hours"],
            adjustment_reason: task["adjustment_reason"],
            references_found: task["references_found"]
          }
        end
      }
    end
  end
end
