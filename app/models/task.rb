class Task < ApplicationRecord
  belongs_to :functional_block

  ESTIMATE_TYPES = %i[optimistic expected pessimistic].freeze

  validates :name, presence: true
  validates :hours_optimistic, :hours_expected, :hours_pessimistic,
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :rate, numericality: { greater_than: 0 }, allow_nil: true

  def cost(estimate_type = :expected)
    raise ArgumentError, "Invalid estimate type: #{estimate_type}" unless ESTIMATE_TYPES.include?(estimate_type.to_sym)

    send(:"hours_#{estimate_type}").to_f * effective_rate.to_f
  end

  def effective_rate
    rate || functional_block.estimation.global_rate
  end
end
