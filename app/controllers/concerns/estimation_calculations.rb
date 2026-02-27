module EstimationCalculations
  extend ActiveSupport::Concern

  private

  def recalculate_totals!(estimation)
    blocks = estimation.functional_blocks.includes(:tasks)
    estimation.update_columns(
      total_hours_optimistic: blocks.sum { |b| b.total_hours_optimistic },
      total_hours_expected: blocks.sum { |b| b.total_hours_expected },
      total_hours_pessimistic: blocks.sum { |b| b.total_hours_pessimistic },
      total_cost_optimistic: blocks.sum { |b| b.total_cost(:optimistic) },
      total_cost_expected: blocks.sum { |b| b.total_cost(:expected) },
      total_cost_pessimistic: blocks.sum { |b| b.total_cost(:pessimistic) }
    )
  end
end
