class EstimatesController < ApplicationController
  include RagErrorHandling
  include EstimationCalculations

  def index
    @pagy, @estimations = pagy(current_user.estimations.search_by_title(params[:q]).recent)
  end

  def new
    @estimation = Estimation.new
    @estimation.functional_blocks.build.tasks.build
  end

  def create
    @estimation = current_user.estimations.build(estimation_params)

    if @estimation.raw_transcriptions.present?
      @estimation.status = "processing"
    else
      @estimation.status = "draft"
    end

    if @estimation.save
      EstimationJob.perform_later(@estimation.id) if @estimation.status == "processing"
      redirect_to estimate_detail_path(@estimation), notice: "Estimacion creada. El analisis esta en proceso."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @estimation = current_user.estimations
      .includes(functional_blocks: :tasks)
      .includes(:references)
      .find(params[:id])
  end

  def retry_estimation
    @estimation = current_user.estimations.find(params[:id])

    unless @estimation.status.in?(%w[failed draft])
      redirect_to estimate_detail_path(@estimation), alert: "Solo se puede reintentar una estimacion fallida."
      return
    end

    @estimation.functional_blocks.destroy_all
    @estimation.references.destroy_all
    @estimation.update!(status: "processing", error_message: nil)

    EstimationJob.perform_later(@estimation.id)
    redirect_to estimate_detail_path(@estimation), notice: "Reintentando analisis..."
  end

  def update_structure
    @estimation = current_user.estimations
      .includes(functional_blocks: :tasks)
      .find(params[:id])

    if @estimation.update(structure_params)
      # Set hours to 0 for newly created tasks (those without hours)
      @estimation.tasks.where(hours_expected: nil).update_all(
        hours_optimistic: 0, hours_expected: 0, hours_pessimistic: 0
      )
      @estimation.update!(status: "completed")
      recalculate_totals!(@estimation)
      redirect_to estimate_detail_path(@estimation), notice: "Estructura confirmada. Revisa las horas estimadas."
    else
      redirect_to estimate_detail_path(@estimation), alert: "Error al guardar la estructura."
    end
  end

  def export_json
    @estimation = current_user.estimations
      .includes(:user, functional_blocks: :tasks)
      .find(params[:id])

    unless @estimation.status == "completed"
      redirect_to estimate_detail_path(@estimation),
        alert: "Solo se puede exportar una estimación completada."
      return
    end

    export_data = EstimationExportService.new(@estimation).call
    filename = "#{@estimation.title.parameterize}-rag-export.json"

    send_data(
      JSON.pretty_generate(export_data),
      filename: filename,
      type: "application/json",
      disposition: "attachment"
    )
  end

  def export_pdf
    @estimation = current_user.estimations
      .includes(:user, :references, functional_blocks: :tasks)
      .find(params[:id])

    unless @estimation.status == "completed"
      redirect_to estimate_detail_path(@estimation),
        alert: "Solo se puede exportar una estimación completada."
      return
    end

    pdf_data = EstimationPdfService.new(@estimation).call
    filename = "#{@estimation.title.parameterize}-presupuesto.pdf"

    send_data(pdf_data, filename: filename, type: "application/pdf", disposition: "inline")
  end

  def update_estimation
    @estimation = current_user.estimations
      .includes(functional_blocks: :tasks)
      .find(params[:id])

    if @estimation.update(estimation_edit_params)
      recalculate_totals!(@estimation)
      redirect_to estimate_detail_path(@estimation), notice: "Estimacion guardada correctamente."
    else
      redirect_to estimate_detail_path(@estimation), alert: "Error al guardar la estimacion."
    end
  end

  private

  def estimation_params
    params.require(:estimation).permit(
      :title, :description, :global_rate, :currency,
      raw_transcriptions: [],
      functional_blocks_attributes: [
        :id, :name, :position, :_destroy,
        tasks_attributes: [:id, :name, :hours_optimistic, :hours_expected, :hours_pessimistic, :rate, :position, :_destroy]
      ]
    )
  end

  def structure_params
    params.require(:estimation).permit(
      functional_blocks_attributes: [
        :id, :name, :position, :_destroy,
        tasks_attributes: [:id, :name, :position, :_destroy]
      ]
    )
  end

  def estimation_edit_params
    params.require(:estimation).permit(
      :global_rate, :currency,
      functional_blocks_attributes: [
        :id,
        tasks_attributes: [:id, :hours_optimistic, :hours_expected, :hours_pessimistic, :rate]
      ]
    )
  end
end
