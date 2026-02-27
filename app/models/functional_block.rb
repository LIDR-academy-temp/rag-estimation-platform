class FunctionalBlock < ApplicationRecord
  belongs_to :estimation
  has_many :tasks, -> { order(:position) }, dependent: :destroy

  validates :name, presence: true
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  accepts_nested_attributes_for :tasks, allow_destroy: true

  def total_hours_optimistic = tasks.sum(:hours_optimistic)
  def total_hours_expected = tasks.sum(:hours_expected)
  def total_hours_pessimistic = tasks.sum(:hours_pessimistic)

  def total_cost(estimate_type = :expected)
    tasks.sum { |t| t.send("hours_#{estimate_type}") * t.effective_rate }
  end
end
