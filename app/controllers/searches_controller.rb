class SearchesController < ApplicationController
  include RagErrorHandling

  def index
    @query = params[:q]
    @chunk_types = Array(params[:chunk_types]).reject(&:blank?)
    @results = []
    @total = 0
    @processing_time = nil

    if @query.present?
      rag = RagServiceClient.new
      filters = @chunk_types.present? ? { chunk_types: @chunk_types } : nil
      response = rag.search(query: @query, filters: filters)
      parsed = RagResponseParser.parse_search(response)
      @results = parsed[:results]
      @total = parsed[:total]
      @processing_time = parsed[:processing_time_ms]
    end
  end
end
