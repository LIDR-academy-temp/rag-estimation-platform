class EstimationExportService
  def initialize(estimation)
    @estimation = estimation
  end

  def call
    {
      quote: {
        project: build_project,
        scope_blocks: build_scope_blocks,
        totals: build_totals,
        team_conditions: build_team_conditions
      },
      source: "platform_export",
      ingested_by: @estimation.user.email
    }
  end

  private

  def build_project
    {
      title: @estimation.title,
      subtitle: @estimation.description,
      currency: @estimation.currency,
      technologies: technologies,
      confidence: @estimation.confidence_score
    }
  end

  def build_scope_blocks
    @estimation.functional_blocks.includes(:tasks).map do |block|
      {
        name: block.name,
        technologies: technologies,
        items: block.tasks.map { |task| build_item(task) },
        subtotal_hours: {
          optimistic: block.total_hours_optimistic.to_f,
          expected: block.total_hours_expected.to_f,
          pessimistic: block.total_hours_pessimistic.to_f
        },
        subtotal_cost: {
          optimistic: block.total_cost(:optimistic).to_f,
          expected: block.total_cost(:expected).to_f,
          pessimistic: block.total_cost(:pessimistic).to_f
        }
      }
    end
  end

  def build_item(task)
    {
      name: task.name,
      hours: {
        optimistic: task.hours_optimistic.to_f,
        expected: task.hours_expected.to_f,
        pessimistic: task.hours_pessimistic.to_f
      },
      unit_price: task.effective_rate.to_f,
      total: {
        optimistic: task.cost(:optimistic).to_f,
        expected: task.cost(:expected).to_f,
        pessimistic: task.cost(:pessimistic).to_f
      }
    }
  end

  def build_totals
    {
      hours: {
        optimistic: @estimation.total_hours_optimistic.to_f,
        expected: @estimation.total_hours_expected.to_f,
        pessimistic: @estimation.total_hours_pessimistic.to_f
      },
      cost: {
        optimistic: @estimation.total_cost_optimistic.to_f,
        expected: @estimation.total_cost_expected.to_f,
        pessimistic: @estimation.total_cost_pessimistic.to_f
      }
    }
  end

  def build_team_conditions
    {
      base_rate: @estimation.global_rate.to_f,
      currency: @estimation.currency
    }
  end

  def technologies
    @technologies ||= Array(@estimation.technologies)
  end
end
