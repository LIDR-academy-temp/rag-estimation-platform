class SearchesController < ApplicationController
  def index
    @query = params[:q]
    @chunk_types = params[:chunk_types] || []
    @results = []
  end
end
