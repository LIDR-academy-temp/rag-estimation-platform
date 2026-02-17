# Phase 6 — RAG Service Integration

**Status: ⬚ Pending**

**Objective:** Build the HTTP client for the Python microservice and integrate all AI features: ingestion, semantic search, and estimation.

**Dependencies:** Phase 5 (controllers to enhance)

**Reference:** `rag-estimation-service/app/api/v1/` (all endpoints), `rag-estimation-service/app/api/schemas/` (all schemas)

---

## 6.1 RAG Service Client

**app/services/rag_service_client.rb:**

Encapsulated Faraday-based HTTP client.

```ruby
class RagServiceClient
  class Error < StandardError; end
  class TimeoutError < Error; end
  class ServiceUnavailableError < Error; end
  class NotFoundError < Error; end

  def initialize(base_url: nil)
    @base_url = base_url || Rails.application.config.rag_service_base_url
  end

  # GET /api/v1/health
  def health
    get("/api/v1/health")
  end

  # POST /api/v1/ingest
  def ingest(quote_json)
    post("/api/v1/ingest", quote_json)
  end

  # GET /api/v1/ingest/{document_id}/status
  def ingest_status(document_id)
    get("/api/v1/ingest/#{document_id}/status")
  end

  # DELETE /api/v1/ingest/{document_id}
  def delete_document(document_id)
    delete("/api/v1/ingest/#{document_id}")
  end

  # POST /api/v1/search
  def search(query:, filters: nil, top_k: 10, min_similarity: 0.6)
    post("/api/v1/search", {
      query: query,
      filters: filters,
      top_k: top_k,
      min_similarity: min_similarity
    }.compact)
  end

  # POST /api/v1/estimate
  def estimate(query:, context: nil, options: nil)
    post("/api/v1/estimate", {
      query: query,
      context: context,
      options: options
    }.compact)
  end

  # POST /api/v1/estimate/batch
  def estimate_batch(queries:, shared_context: nil, options: nil)
    post("/api/v1/estimate/batch", {
      queries: queries,
      shared_context: shared_context,
      options: options
    }.compact)
  end

  # GET /api/v1/stats
  def stats
    get("/api/v1/stats")
  end

  private

  def connection
    @connection ||= Faraday.new(url: @base_url) do |f|
      f.request :json
      f.response :json
      f.options.timeout = 60
      f.options.open_timeout = 10
      f.adapter Faraday.default_adapter
    end
  end

  def get(path)
    handle_response(connection.get(path))
  rescue Faraday::TimeoutError => e
    raise TimeoutError, "RAG service timeout: #{e.message}"
  rescue Faraday::ConnectionFailed => e
    raise ServiceUnavailableError, "RAG service unavailable: #{e.message}"
  end

  def post(path, body)
    handle_response(connection.post(path, body))
  rescue Faraday::TimeoutError => e
    raise TimeoutError, "RAG service timeout: #{e.message}"
  rescue Faraday::ConnectionFailed => e
    raise ServiceUnavailableError, "RAG service unavailable: #{e.message}"
  end

  def delete(path)
    handle_response(connection.delete(path))
  rescue Faraday::TimeoutError => e
    raise TimeoutError, "RAG service timeout: #{e.message}"
  rescue Faraday::ConnectionFailed => e
    raise ServiceUnavailableError, "RAG service unavailable: #{e.message}"
  end

  def handle_response(response)
    case response.status
    when 200..299
      response.body
    when 404
      raise NotFoundError, response.body.dig("detail") || "Not found"
    when 503
      raise ServiceUnavailableError, response.body.dig("detail") || "Service unavailable"
    else
      raise Error, "RAG service error (#{response.status}): #{response.body}"
    end
  end
end
```

---

## 6.2 Response Parser

**app/services/rag_response_parser.rb:**

Transforms RAG JSON responses into model attributes.

```ruby
class RagResponseParser
  # Parse ingest response into Document attributes
  def self.parse_ingest(response)
    {
      external_document_id: response["document_id"],
      status: response["status"]
    }
  end

  # Parse ingest status into Document + ChunksBreakdown attributes
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

  # Parse estimate response into Estimation attributes
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

  # Parse search results
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
end
```

---

## 6.3 Controller Integration

### IngestionsController#create

After saving the document:
```ruby
# Call RAG service
rag = RagServiceClient.new
response = rag.ingest({ quote: JSON.parse(@document.raw_json), source: "web", ingested_by: current_user.email })
parsed = RagResponseParser.parse_ingest(response)

@document.update!(
  external_document_id: parsed[:external_document_id],
  status: "processing"
)

# Enqueue status polling job
IngestionStatusJob.perform_later(@document.id)
```

### SearchController#index

```ruby
if @query.present?
  rag = RagServiceClient.new
  filters = @chunk_types.present? ? { chunk_types: @chunk_types } : nil
  response = rag.search(query: @query, filters: filters)
  parsed = RagResponseParser.parse_search(response)
  @results = parsed[:results]
  @total = parsed[:total]
  @processing_time = parsed[:processing_time_ms]
end
```

### EstimationsController#create

After saving the estimation shell:
```ruby
# Build query from transcriptions
query = @estimation.raw_transcriptions.join("\n\n")

rag = RagServiceClient.new
response = rag.estimate(
  query: query,
  options: { currency: @estimation.currency }
)
parsed = RagResponseParser.parse_estimate(response, @estimation)

# Update estimation with results
@estimation.update!(parsed[:estimation].merge(status: "completed"))

# Create blocks and tasks
parsed[:blocks].each do |block_attrs|
  @estimation.functional_blocks.create!(block_attrs)
end

# Create references
parsed[:references].each do |ref_attrs|
  @estimation.references.create!(ref_attrs)
end
```

### DashboardController#index

```ruby
# Live health and stats from RAG service
begin
  rag = RagServiceClient.new
  @health_status = rag.health
  @rag_stats = rag.stats
rescue RagServiceClient::Error => e
  @health_status = { "status" => "unavailable", "error" => e.message }
  @rag_stats = nil
end
```

### DocumentsController#destroy

```ruby
# Delete from RAG service if external_document_id exists
if @document.external_document_id.present?
  begin
    RagServiceClient.new.delete_document(@document.external_document_id)
  rescue RagServiceClient::Error => e
    Rails.logger.warn("Failed to delete from RAG service: #{e.message}")
  end
end
@document.destroy
```

---

## 6.4 IngestionStatusJob

**app/jobs/ingestion_status_job.rb:**

Background job (Solid Queue) that polls the RAG service for ingestion status.

```ruby
class IngestionStatusJob < ApplicationJob
  queue_as :default
  retry_on RagServiceClient::TimeoutError, wait: 10.seconds, attempts: 5

  def perform(document_id)
    document = Document.find(document_id)
    return unless document.status.in?(%w[pending processing])

    rag = RagServiceClient.new
    response = rag.ingest_status(document.external_document_id)
    parsed = RagResponseParser.parse_ingest_status(response)

    document.update!(parsed[:document])

    if parsed[:breakdown] && document.status == "completed"
      document.create_chunks_breakdown!(parsed[:breakdown])
      document.update!(ingested_at: Time.current)
    end

    # Re-enqueue if still processing
    if document.status == "processing"
      IngestionStatusJob.set(wait: 5.seconds).perform_later(document_id)
    end
  end
end
```

---

## 6.5 Error Handling Concern

**app/controllers/concerns/rag_error_handling.rb:**

```ruby
module RagErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from RagServiceClient::ServiceUnavailableError, with: :rag_unavailable
    rescue_from RagServiceClient::TimeoutError, with: :rag_timeout
    rescue_from RagServiceClient::Error, with: :rag_error
  end

  private

  def rag_unavailable(exception)
    flash.now[:alert] = "El servicio RAG no esta disponible. Intentalo mas tarde."
    Rails.logger.error("RAG service unavailable: #{exception.message}")
    render_fallback
  end

  def rag_timeout(exception)
    flash.now[:alert] = "El servicio RAG tardo demasiado en responder."
    Rails.logger.error("RAG service timeout: #{exception.message}")
    render_fallback
  end

  def rag_error(exception)
    flash.now[:alert] = "Error al comunicarse con el servicio RAG."
    Rails.logger.error("RAG service error: #{exception.message}")
    render_fallback
  end

  def render_fallback
    # Render the current action's view with error state
    render action_name, status: :service_unavailable
  end
end
```

---

## 6.6 Configuration Initializer

**config/initializers/rag_service.rb:**

```ruby
Rails.application.config.rag_service_base_url = ENV.fetch(
  "RAG_SERVICE_BASE_URL",
  "http://localhost:8000"
)
```

---

## Files to Create/Modify

| Action | File |
|--------|------|
| Create | `app/services/rag_service_client.rb` |
| Create | `app/services/rag_response_parser.rb` |
| Create | `app/jobs/ingestion_status_job.rb` |
| Create | `app/controllers/concerns/rag_error_handling.rb` |
| Create | `config/initializers/rag_service.rb` |
| Modify | `app/controllers/ingestions_controller.rb` |
| Modify | `app/controllers/search_controller.rb` |
| Modify | `app/controllers/estimations_controller.rb` |
| Modify | `app/controllers/dashboard_controller.rb` |
| Modify | `app/controllers/documents_controller.rb` |

---

## RAG Service API Contract Quick Reference

| Method | Endpoint | Request Body | Response |
|--------|----------|-------------|----------|
| GET | `/api/v1/health` | — | `{ status, version, environment, dependencies }` |
| POST | `/api/v1/ingest` | `{ quote: {...}, source, ingested_by }` | `{ status, document_id, message }` |
| GET | `/api/v1/ingest/{id}/status` | — | `{ document_id, status, project_title, chunks_created, breakdown }` |
| DELETE | `/api/v1/ingest/{id}` | — | `{ document_id, status, chunks_deleted }` |
| POST | `/api/v1/search` | `{ query, filters?, top_k?, min_similarity? }` | `{ results[], total_results, query_processing_time_ms }` |
| POST | `/api/v1/estimate` | `{ query, context?, options? }` | `{ estimation, references[], metadata }` |
| POST | `/api/v1/estimate/batch` | `{ queries[], shared_context?, options? }` | `{ estimations[], aggregated, metadata }` |
| GET | `/api/v1/stats` | — | `{ documents_by_status, chunks_by_type, search_metrics_last_30d }` |

**Valid chunk types:** `project_overview`, `scope_block`, `line_item`, `phase`, `team_conditions`

---

## Verification

1. `RagServiceClient.new.health` returns health data (with RAG service running)
2. Ingesting a JSON creates a document and external_document_id is stored
3. IngestionStatusJob polls and updates document status to "completed" with chunks
4. Search with a query returns results from the RAG service
5. Estimation creation calls the RAG service and stores 3-point estimates
6. Dashboard shows live health status from the RAG service
7. Document deletion calls the RAG service delete endpoint
8. Error handling shows user-friendly messages when RAG service is down
9. Timeout handling works (simulate with slow/unavailable service)
