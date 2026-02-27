class EstimationJob < ApplicationJob
  queue_as :default

  retry_on RagServiceClient::TimeoutError, wait: 10.seconds, attempts: 3
  retry_on RagServiceClient::ServiceUnavailableError, wait: 15.seconds, attempts: 3

  discard_on ActiveRecord::RecordNotFound

  def perform(estimation_id)
    estimation = Estimation.find(estimation_id)
    return unless estimation.status == "processing"

    query = estimation.raw_transcriptions.join("\n\n")
    if query.length < 10
      estimation.update!(status: "failed", error_message: "La transcripcion es demasiado corta para generar una estimacion.")
      broadcast_update(estimation)
      return
    end

    rag = RagServiceClient.new
    response = rag.estimate(
      query: query,
      options: { currency: estimation.currency }
    )
    parsed = RagResponseParser.parse_estimate(response, estimation)

    estimation.update!(parsed[:estimation].merge(status: "structuring", error_message: nil))

    parsed[:blocks].each do |block_attrs|
      estimation.functional_blocks.create!(block_attrs)
    end

    parsed[:references].each do |ref_attrs|
      estimation.references.create!(ref_attrs)
    end

    broadcast_update(estimation)
  rescue RagServiceClient::Error => e
    estimation = Estimation.find_by(id: estimation_id)
    return unless estimation

    estimation.update!(status: "failed", error_message: user_facing_message(e))
    broadcast_update(estimation)
  end

  private

  def broadcast_update(estimation)
    estimation.reload
    Turbo::StreamsChannel.broadcast_replace_to(
      "estimation_#{estimation.id}",
      target: "estimation_#{estimation.id}_content",
      partial: "estimates/estimation_content",
      locals: { estimation: estimation }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "estimation_#{estimation.id}",
      target: "estimation_#{estimation.id}_stepper",
      partial: "estimates/stepper",
      locals: { current_step: estimation.status == "failed" ? 0 : 1 }
    )
  end

  def user_facing_message(error)
    case error
    when RagServiceClient::TimeoutError
      "El servicio de estimacion tardo demasiado en responder. Intenta de nuevo."
    when RagServiceClient::ServiceUnavailableError
      "El servicio de estimacion no esta disponible en este momento. Intenta mas tarde."
    else
      "Error al generar la estimacion: #{error.message}"
    end
  end
end
