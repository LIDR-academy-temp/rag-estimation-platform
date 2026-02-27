module RagErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from RagServiceClient::ServiceUnavailableError, with: :rag_unavailable
    rescue_from RagServiceClient::TimeoutError, with: :rag_timeout
    rescue_from RagServiceClient::Error, with: :rag_error
  end

  private

  def rag_unavailable(exception)
    @rag_error_message = "El servicio RAG no está disponible. Inténtalo más tarde."
    flash.now[:alert] = @rag_error_message
    Rails.logger.error("RAG unavailable: #{exception.message}")
    render_fallback
  end

  def rag_timeout(exception)
    @rag_error_message = "El servicio RAG tardó demasiado en responder."
    flash.now[:alert] = @rag_error_message
    Rails.logger.error("RAG timeout: #{exception.message}")
    render_fallback
  end

  def rag_error(exception)
    @rag_error_message = "Error al comunicarse con el servicio RAG."
    flash.now[:alert] = @rag_error_message
    Rails.logger.error("RAG error: #{exception.message}")
    render_fallback
  end

  def render_fallback
    if request.get?
      render action_name, status: :service_unavailable
    else
      redirect_back fallback_location: root_path, alert: @rag_error_message
    end
  end
end
