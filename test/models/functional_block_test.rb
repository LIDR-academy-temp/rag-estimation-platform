require "test_helper"

class FunctionalBlockTest < ActiveSupport::TestCase
  test "valid functional block" do
    block = functional_blocks(:auth_block)
    assert block.valid?
  end

  test "name must be present" do
    block = functional_blocks(:auth_block)
    block.name = nil
    assert_not block.valid?
  end

  test "position must be integer >= 0" do
    block = functional_blocks(:auth_block)

    block.position = -1
    assert_not block.valid?

    block.position = 1.5
    assert_not block.valid?

    block.position = 0
    assert block.valid?
  end

  test "position allows nil" do
    block = functional_blocks(:auth_block)
    block.position = nil
    assert block.valid?
  end

  test "total_hours_optimistic sums task hours" do
    block = functional_blocks(:auth_block)
    expected = block.tasks.sum(:hours_optimistic)
    assert_equal expected, block.total_hours_optimistic
  end

  test "total_hours_expected sums task hours" do
    block = functional_blocks(:auth_block)
    expected = block.tasks.sum(:hours_expected)
    assert_equal expected, block.total_hours_expected
  end

  test "total_hours_pessimistic sums task hours" do
    block = functional_blocks(:auth_block)
    expected = block.tasks.sum(:hours_pessimistic)
    assert_equal expected, block.total_hours_pessimistic
  end

  test "total_cost calculates with effective rates" do
    block = functional_blocks(:auth_block)
    expected = block.tasks.sum { |t| t.hours_expected * t.effective_rate }
    assert_in_delta expected, block.total_cost(:expected), 0.01
  end

  test "total_cost with optimistic type" do
    block = functional_blocks(:auth_block)
    expected = block.tasks.sum { |t| t.hours_optimistic * t.effective_rate }
    assert_in_delta expected, block.total_cost(:optimistic), 0.01
  end

  test "has many tasks ordered by position" do
    block = functional_blocks(:auth_block)
    tasks = block.tasks
    tasks.each_cons(2) do |a, b|
      assert a.position <= b.position
    end
  end

  test "destroying block destroys tasks" do
    block = functional_blocks(:auth_block)
    task_count = block.tasks.count
    assert task_count > 0
    assert_difference("Task.count", -task_count) { block.destroy }
  end
end
