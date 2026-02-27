class EstimationsController < ApplicationController
  include EstimationCalculations

  def index
    scope = current_user.estimations.recent
    scope = scope.search_by_title(params[:q]) if params[:q].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    @pagy, @estimations = pagy(scope)
  end

  def edit
    @estimation = current_user.estimations
      .includes(functional_blocks: :tasks)
      .find(params[:id])
  end

  def update
    @estimation = current_user.estimations
      .includes(functional_blocks: :tasks)
      .find(params[:id])

    if @estimation.update(estimation_params)
      recalculate_totals!(@estimation)
      redirect_to estimate_detail_path(@estimation), notice: "Estimación actualizada correctamente."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    estimation = current_user.estimations.find(params[:id])
    estimation.destroy
    redirect_to estimations_path, notice: "Estimación '#{estimation.title}' eliminada correctamente."
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
