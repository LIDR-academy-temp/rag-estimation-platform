class EstimatesController < ApplicationController
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

  def estimation_params
    params.require(:estimation).permit(
      :title, :description, :global_rate, :currency,
      functional_blocks_attributes: [
        :id, :name, :position, :_destroy,
        tasks_attributes: [:id, :name, :hours_optimistic, :hours_expected, :hours_pessimistic, :rate, :position, :_destroy]
      ]
    )
  end
end
