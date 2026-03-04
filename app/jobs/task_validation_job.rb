class TaskValidationJob < ApplicationJob
  include EstimationCalculations

  queue_as :default
  retry_on RagServiceClient::TimeoutError, wait: 5.seconds, attempts: 2
  retry_on RagServiceClient::ServiceUnavailableError, wait: 10.seconds, attempts: 2
  discard_on ActiveRecord::RecordNotFound

  def perform(estimation_id)
    estimation = Estimation.find(estimation_id)
    return unless estimation.status == "validating"

    rag = RagServiceClient.new
    breakdown = build_breakdown_payload(estimation)
    effort = build_effort_payload(estimation)

    validation = rag.validate_breakdown(
      breakdown: breakdown,
      estimated_effort: effort,
      currency: estimation.currency
    )

    apply_validation(estimation, validation)
    recalculate_totals!(estimation)
    estimation.update!(status: "completed")
    broadcast_completed(estimation)
  rescue RagServiceClient::Error => e
    Rails.logger.warn("Task validation failed: #{e.message}")
    estimation.update!(status: "completed")
    broadcast_completed(estimation)
  end

  private

  def build_breakdown_payload(estimation)
    estimation.functional_blocks.includes(:tasks).order(:position).map do |block|
      {
        name: block.name,
        tasks: block.tasks.order(:position).map do |t|
          { name: t.name, hours: [t.hours_expected.to_i, 1].max }
        end
      }
    end
  end

  def build_effort_payload(estimation)
    {
      optimistic: { hours: estimation.total_hours_optimistic.to_i },
      expected: { hours: estimation.total_hours_expected.to_i },
      pessimistic: { hours: estimation.total_hours_pessimistic.to_i }
    }
  end

  def apply_validation(estimation, validation)
    validated_blocks = RagResponseParser.parse_validation(validation)
    effort = validation["estimated_effort"] || {}

    opt_ratio = estimation.total_hours_expected.to_f > 0 ?
      estimation.total_hours_optimistic.to_f / estimation.total_hours_expected.to_f : 0.7
    pes_ratio = estimation.total_hours_expected.to_f > 0 ?
      estimation.total_hours_pessimistic.to_f / estimation.total_hours_expected.to_f : 1.5

    validated_blocks.each do |vblock|
      block = estimation.functional_blocks.find_by(name: vblock[:name])
      next unless block
      vblock[:tasks].each do |vtask|
        task = block.tasks.find_by(name: vtask[:name])
        next unless task
        hours = vtask[:hours].to_i
        next if hours <= 0
        task.update!(
          hours_expected: hours,
          hours_optimistic: (hours * opt_ratio).round(2),
          hours_pessimistic: (hours * pes_ratio).round(2)
        )
      end
    end

    if effort.dig("expected", "hours")
      estimation.update!(
        total_hours_optimistic: effort.dig("optimistic", "hours"),
        total_hours_expected: effort.dig("expected", "hours"),
        total_hours_pessimistic: effort.dig("pessimistic", "hours")
      )
    end
  end

  def broadcast_completed(estimation)
    estimation.reload
    Turbo::StreamsChannel.broadcast_replace_to(
      "estimation_#{estimation.id}",
      target: "estimation_#{estimation.id}_content",
      partial: "estimates/estimation_content",
      locals: { estimation: estimation }
    )
    Turbo::StreamsChannel.broadcast_replace_to(
      "estimation_#{estimation.id}",
      target: "estimation_#{estimation.id}_stepper",
      partial: "estimates/stepper",
      locals: { current_step: 2 }
    )
  end
end
