class EstimatesController < ApplicationController
  include RagErrorHandling

  def index
    @pagy, @estimations = pagy(current_user.estimations.search_by_title(params[:q]).recent)
  end

  def new
    @estimation = Estimation.new
    @estimation.functional_blocks.build.tasks.build
  end

  def create
    @estimation = current_user.estimations.build(estimation_params)
    @estimation.status = "draft"

    if @estimation.save
      if @estimation.raw_transcriptions.present?
        generate_rag_estimate(@estimation)
      end
      redirect_to estimate_detail_path(@estimation), notice: "Estimación creada correctamente."
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

  private

  def generate_rag_estimate(estimation)
    query = estimation.raw_transcriptions.join("\n\n")
    return if query.length < 10

    rag = RagServiceClient.new
    response = rag.estimate(
      query: query,
      options: { currency: estimation.currency }
    )
    parsed = RagResponseParser.parse_estimate(response, estimation)

    estimation.update!(parsed[:estimation].merge(status: "completed"))

    parsed[:blocks].each do |block_attrs|
      estimation.functional_blocks.create!(block_attrs)
    end

    parsed[:references].each do |ref_attrs|
      estimation.references.create!(ref_attrs)
    end
  rescue RagServiceClient::Error => e
    Rails.logger.error("RAG estimate failed: #{e.message}")
    # Estimation stays as "draft" — user can still see and edit manually
  end

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
end
