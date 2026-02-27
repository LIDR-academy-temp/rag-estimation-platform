class IngestionStatusJob < ApplicationJob
  queue_as :default

  discard_on RagServiceClient::NotFoundError do |job, error|
    document = Document.find_by(id: job.arguments.first)
    document&.update!(status: "failed")
    Rails.logger.error("RAG document not found: #{error.message}")
  end

  retry_on RagServiceClient::TimeoutError, wait: 10.seconds, attempts: 5
  retry_on RagServiceClient::Error, wait: 15.seconds, attempts: 3 do |job, error|
    document = Document.find_by(id: job.arguments.first)
    document&.update!(status: "failed")
    Rails.logger.error("RAG ingestion status check failed permanently: #{error.message}")
  end

  def perform(document_id)
    document = Document.find(document_id)
    return unless document.status.in?(%w[pending processing])

    response = RagServiceClient.new.ingest_status(document.external_document_id)
    parsed = RagResponseParser.parse_ingest_status(response)

    document.update!(parsed[:document])

    document.broadcast_replace_to(
      "user_#{document.user_id}_documents",
      target: "document_#{document.id}",
      partial: "ingest/document_row",
      locals: { document: document }
    )

    if parsed[:breakdown] && document.status == "completed"
      breakdown = document.chunks_breakdown || document.build_chunks_breakdown
      breakdown.update!(parsed[:breakdown])
      document.update!(ingested_at: Time.current) unless document.ingested_at?
    end

    if document.status == "processing"
      IngestionStatusJob.set(wait: 5.seconds).perform_later(document_id)
    end
  end
end
