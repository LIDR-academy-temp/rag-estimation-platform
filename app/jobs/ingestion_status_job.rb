class IngestionStatusJob < ApplicationJob
  queue_as :default
  retry_on RagServiceClient::TimeoutError, wait: 10.seconds, attempts: 5

  def perform(document_id)
    document = Document.find(document_id)
    return unless document.status.in?(%w[pending processing])

    response = RagServiceClient.new.ingest_status(document.external_document_id)
    parsed = RagResponseParser.parse_ingest_status(response)

    document.update!(parsed[:document])

    if parsed[:breakdown] && document.status == "completed"
      document.create_chunks_breakdown!(parsed[:breakdown])
      document.update!(ingested_at: Time.current)
    end

    if document.status == "processing"
      IngestionStatusJob.set(wait: 5.seconds).perform_later(document_id)
    end
  end
end
