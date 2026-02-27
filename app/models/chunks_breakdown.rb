class ChunksBreakdown < ApplicationRecord
  belongs_to :document

  def total
    (project_overview || 0) + (scope_block || 0) + (line_item || 0) + (phase || 0) + (team_conditions || 0)
  end
end
