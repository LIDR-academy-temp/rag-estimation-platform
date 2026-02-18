class IngestController < ApplicationController
  def index
    @documents = current_user.documents.includes(:chunks_breakdown).recent.limit(20)
  end

  def create
    raw = params[:raw_json]
    if raw.blank?
      redirect_to ingest_path, alert: "Debes pegar o subir un JSON válido." and return
    end

    begin
      parsed = JSON.parse(raw)
    rescue JSON::ParserError
      redirect_to ingest_path, alert: "El JSON proporcionado no es válido." and return
    end

    title = parsed.dig("quote", "project", "title") || "Sin título"

    technologies = []
    scope_blocks = parsed.dig("quote", "scope_blocks") || []
    scope_blocks.each do |block|
      techs = block["technologies"] || block["tech_stack"] || []
      technologies.concat(techs)
    end
    technologies = technologies.uniq

    @document = current_user.documents.create!(
      title: title,
      raw_json: raw,
      technologies: technologies,
      status: "pending"
    )

    begin
      rag = RagServiceClient.new
      response = rag.ingest({
        quote: parsed,
        source: "web",
        ingested_by: current_user.email
      })
      ingest_result = RagResponseParser.parse_ingest(response)

      @document.update!(
        external_document_id: ingest_result[:external_document_id],
        status: "processing"
      )
      IngestionStatusJob.perform_later(@document.id)

      redirect_to ingest_path, notice: "Presupuesto '#{title}' ingresado correctamente. Procesamiento en curso."
    rescue RagServiceClient::Error => e
      Rails.logger.error("RAG ingest failed: #{e.message}")
      @document.update!(status: "failed")
      redirect_to ingest_path, alert: "Presupuesto guardado localmente pero el servicio RAG no está disponible."
    end
  rescue TypeError
    redirect_to ingest_path, alert: "El JSON proporcionado no es válido."
  end
end
