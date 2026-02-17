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

    current_user.documents.create!(
      title: title,
      raw_json: parsed,
      technologies: technologies,
      status: "pending"
    )

    redirect_to ingest_path, notice: "Presupuesto '#{title}' ingresado correctamente. Procesamiento pendiente."
  rescue TypeError
    redirect_to ingest_path, alert: "El JSON proporcionado no es válido."
  end
end
