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
    effort = detail["estimated_effort"]
    cost = detail["estimated_cost"]
    confidence = detail["confidence"]

    estimation_attrs = {
      confidence_score: confidence["score"],
      confidence_level: confidence["level"],
      technologies: detail["suggested_technologies"],
      total_hours_optimistic: effort["optimistic"]["hours"],
      total_hours_expected: effort["expected"]["hours"],
      total_hours_pessimistic: effort["pessimistic"]["hours"],
      total_cost_optimistic: cost["optimistic"]["amount"],
      total_cost_expected: cost["expected"]["amount"],
      total_cost_pessimistic: cost["pessimistic"]["amount"]
    }

    blocks_attrs = detail["suggested_breakdown"].map.with_index do |item, i|
      {
        name: item["name"],
        position: i,
        tasks_attributes: [{
          name: item["name"],
          hours_expected: item["days"] * 8,
          rate: item["unit_price"],
          position: 0
        }]
      }
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
  end
end
