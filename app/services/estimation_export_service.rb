class EstimationExportService
  def initialize(estimation)
    @estimation = estimation
  end

  def call
    {
      quote: {
        client: build_client,
        project: build_project,
        dates: build_dates,
        currency: @estimation.currency,
        discount: { type: nil, amount: nil },
        objectives: [],
        scope_blocks: build_scope_blocks,
        roadmap_phases: [],
        items: build_items,
        team_members: [],
        conditions: { payment_terms: nil, included_services: nil, additional_services: [] },
        notes: nil,
        terms: nil
      },
      source: "platform_export",
      ingested_by: @estimation.user.email
    }
  end

  private

  def build_client
    {
      name: @estimation.user.name,
      email: @estimation.user.email,
      company: nil
    }
  end

  def build_project
    {
      title: @estimation.title,
      subtitle: @estimation.description,
      proposal_date: @estimation.created_at.strftime("%Y-%m-%d")
    }
  end

  def build_dates
    {
      issue_date: @estimation.created_at.strftime("%Y-%m-%d"),
      valid_until: nil
    }
  end

  def build_scope_blocks
    loaded_blocks.map do |block|
      {
        title: block.name,
        short_description: generate_short_description(block),
        long_description: nil,
        features: block.tasks.map(&:name),
        technologies: technologies,
        detailed_features: block.tasks.map { |task| { title: task.name, description: nil } }
      }
    end
  end

  def build_items
    loaded_blocks.flat_map do |block|
      block.tasks.map do |task|
        {
          type: "task",
          name: task.name,
          description: nil,
          quantity: task.hours_expected.to_f,
          unit: "hora",
          unit_price: task.effective_rate.to_f,
          discount_percent: 0,
          phase: block.name
        }
      end
    end
  end

  def loaded_blocks
    @loaded_blocks ||= @estimation.functional_blocks.includes(:tasks).to_a
  end

  def generate_short_description(block)
    task_names = block.tasks.map(&:name)
    if task_names.any?
      "#{block.name}: #{task_names.join(', ')}"
    else
      block.name
    end
  end

  def technologies
    @technologies ||= Array(@estimation.technologies)
  end
end
