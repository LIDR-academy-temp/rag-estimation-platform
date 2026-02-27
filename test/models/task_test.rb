require "test_helper"

class TaskTest < ActiveSupport::TestCase
  test "valid task" do
    task = tasks(:login_task)
    assert task.valid?
  end

  test "name must be present" do
    task = tasks(:login_task)
    task.name = nil
    assert_not task.valid?
  end

  test "hours must be >= 0" do
    task = tasks(:login_task)

    task.hours_optimistic = -1
    assert_not task.valid?

    task.hours_optimistic = 0
    assert task.valid?
  end

  test "hours allows nil" do
    task = tasks(:login_task)
    task.hours_optimistic = nil
    assert task.valid?
  end

  test "rate must be > 0" do
    task = tasks(:login_task)

    task.rate = 0
    assert_not task.valid?

    task.rate = -1
    assert_not task.valid?

    task.rate = 50
    assert task.valid?
  end

  test "rate allows nil" do
    task = tasks(:login_task)
    task.rate = nil
    assert task.valid?
  end

  test "cost calculates hours times effective rate" do
    task = tasks(:login_task)
    expected = task.hours_expected * task.rate
    assert_in_delta expected, task.cost(:expected), 0.01
  end

  test "cost with optimistic" do
    task = tasks(:login_task)
    expected = task.hours_optimistic * task.rate
    assert_in_delta expected, task.cost(:optimistic), 0.01
  end

  test "cost with pessimistic" do
    task = tasks(:login_task)
    expected = task.hours_pessimistic * task.rate
    assert_in_delta expected, task.cost(:pessimistic), 0.01
  end

  test "cost raises ArgumentError for invalid type" do
    task = tasks(:login_task)
    assert_raises(ArgumentError) { task.cost(:invalid) }
  end

  test "effective_rate returns task rate when present" do
    task = tasks(:login_task)
    assert_equal task.rate, task.effective_rate
  end

  test "effective_rate falls back to estimation global_rate" do
    task = tasks(:oauth_task)
    assert_nil task.rate
    assert_equal task.functional_block.estimation.global_rate, task.effective_rate
  end
end
