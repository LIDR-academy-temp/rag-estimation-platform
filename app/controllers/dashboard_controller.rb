class DashboardController < ApplicationController
  def index
    @documents_count = current_user.documents.count
    @completed_count = current_user.documents.by_status("completed").count
    @chunks_total = current_user.documents
      .joins(:chunks_breakdown)
      .sum("chunks_breakdowns.project_overview + chunks_breakdowns.scope_block + chunks_breakdowns.line_item + chunks_breakdowns.phase + chunks_breakdowns.team_conditions")
    @chunk_distribution = compute_chunk_distribution
    @recent_documents = current_user.documents.includes(:chunks_breakdown).recent.limit(5)

    begin
      rag = RagServiceClient.new
      @health_status = rag.health
      rag_stats = rag.stats
      @search_metrics = {
        total: rag_stats.dig("search_metrics_last_30d", "total_searches") || 0,
        avg_latency: rag_stats.dig("search_metrics_last_30d", "avg_response_time_ms") || 0
      }
    rescue RagServiceClient::Error => e
      Rails.logger.warn("Dashboard RAG unavailable: #{e.message}")
      @health_status = { "status" => "unavailable" }
      @search_metrics = { total: 0, avg_latency: 0 }
    end
  end

  private

  def compute_chunk_distribution
    sums = current_user.documents
      .joins(:chunks_breakdown)
      .pick(
        "SUM(chunks_breakdowns.project_overview)",
        "SUM(chunks_breakdowns.scope_block)",
        "SUM(chunks_breakdowns.line_item)",
        "SUM(chunks_breakdowns.phase)",
        "SUM(chunks_breakdowns.team_conditions)"
      )

    [
      { type: "project_overview", count: sums[0].to_i, color: "bg-primary" },
      { type: "scope_block", count: sums[1].to_i, color: "bg-info" },
      { type: "line_item", count: sums[2].to_i, color: "bg-success" },
      { type: "phase", count: sums[3].to_i, color: "bg-warning" },
      { type: "team_conditions", count: sums[4].to_i, color: "bg-destructive" }
    ]
  end
end
