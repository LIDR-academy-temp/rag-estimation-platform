class RagServiceClient
  class Error < StandardError; end
  class TimeoutError < Error; end
  class ServiceUnavailableError < Error; end
  class NotFoundError < Error; end

  def initialize(base_url: nil)
    @base_url = base_url || Rails.application.config.rag_service_base_url
  end

  def health
    get("/api/v1/health")
  end

  def ingest(quote_payload)
    post("/api/v1/ingest", quote_payload)
  end

  def ingest_status(document_id)
    get("/api/v1/ingest/#{document_id}/status")
  end

  def delete_document(document_id)
    delete("/api/v1/ingest/#{document_id}")
  end

  def search(query:, filters: nil, top_k: 10, min_similarity: 0.6)
    post("/api/v1/search", {
      query: query,
      filters: filters,
      top_k: top_k,
      min_similarity: min_similarity
    }.compact)
  end

  def estimate(query:, context: nil, options: nil)
    merged_options = (options || {}).merge(skip_validation: true)
    post("/api/v1/estimate", {
      query: query,
      context: context,
      options: merged_options
    }.compact)
  end

  def validate_breakdown(breakdown:, estimated_effort:, currency: "EUR")
    post("/api/v1/estimate/validate", {
      breakdown: breakdown,
      estimated_effort: estimated_effort,
      currency: currency
    })
  end

  def estimate_batch(queries:, shared_context: nil, options: nil)
    post("/api/v1/estimate/batch", {
      queries: queries,
      shared_context: shared_context,
      options: options
    }.compact)
  end

  def stats
    get("/api/v1/stats")
  end

  private

  def connection
    @connection ||= Faraday.new(url: @base_url) do |f|
      f.request :json
      f.response :json
      f.response :logger, Rails.logger, bodies: true if Rails.env.development?
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
      raise NotFoundError, response.body&.dig("detail") || "Not found"
    when 503
      raise ServiceUnavailableError, response.body&.dig("detail") || "Service unavailable"
    else
      detail = response.body.is_a?(Hash) ? response.body["detail"] : nil
      raise Error, detail || "RAG service error (#{response.status})"
    end
  end
end
