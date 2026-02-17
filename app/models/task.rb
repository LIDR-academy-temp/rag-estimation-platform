class Task < ApplicationRecord
  belongs_to :functional_block

  validates :name, presence: true

  def cost(estimate_type = :expected)
    send("hours_#{estimate_type}") * effective_rate
  end

  def effective_rate
    rate || functional_block.estimation.global_rate
  end
end
