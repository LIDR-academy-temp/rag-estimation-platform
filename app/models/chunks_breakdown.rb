class ChunksBreakdown < ApplicationRecord
  belongs_to :document

  def total
    project_overview + scope_block + line_item + phase + team_conditions
  end
end
