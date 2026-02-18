module RagErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from RagServiceClient::ServiceUnavailableError, with: :rag_unavailable
    rescue_from RagServiceClient::TimeoutError, with: :rag_timeout
    rescue_from RagServiceClient::Error, with: :rag_error
  end

  private

  def rag_unavailable(exception)
    flash.now[:alert] = "El servicio RAG no está disponible. Inténtalo más tarde."
    Rails.logger.error("RAG unavailable: #{exception.message}")
    render_fallback
  end

  def rag_timeout(exception)
    flash.now[:alert] = "El servicio RAG tardó demasiado en responder."
    Rails.logger.error("RAG timeout: #{exception.message}")
    render_fallback
  end

  def rag_error(exception)
    flash.now[:alert] = "Error al comunicarse con el servicio RAG."
    Rails.logger.error("RAG error: #{exception.message}")
    render_fallback
  end

  def render_fallback
    if request.get?
      render action_name, status: :service_unavailable
    else
      redirect_back fallback_location: root_path, alert: flash.now[:alert]
    end
  end
end
