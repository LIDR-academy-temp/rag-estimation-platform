class DocumentsController < ApplicationController
  def index
    scope = current_user.documents.includes(:chunks_breakdown).recent
    scope = scope.search_by_title(params[:q]) if params[:q].present?
    @pagy, @documents = pagy(scope)
  end

  def show
    @document = current_user.documents.find(params[:id])
    @estimation = current_user.estimations.includes(
      functional_blocks: :tasks
    ).includes(:references).find_by(title: @document.title)
  end

  def destroy
    document = current_user.documents.find(params[:id])
    document.destroy
    redirect_to documents_path, notice: "Documento '#{document.title}' eliminado correctamente."
  end
end
