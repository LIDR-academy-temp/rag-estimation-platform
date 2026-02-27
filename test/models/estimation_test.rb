require "test_helper"

class EstimationTest < ActiveSupport::TestCase
  test "valid estimation" do
    estimation = estimations(:completed_estimation)
    assert estimation.valid?
  end

  test "title must be present" do
    estimation = estimations(:draft_estimation)
    estimation.title = nil
    assert_not estimation.valid?
  end

  test "status must be valid" do
    estimation = estimations(:draft_estimation)

    %w[draft processing completed failed].each do |status|
      estimation.status = status
      assert estimation.valid?, "#{status} should be valid"
    end

    estimation.status = "invalid"
    assert_not estimation.valid?
  end

  test "global_rate must be positive" do
    estimation = estimations(:draft_estimation)
    estimation.global_rate = -1
    assert_not estimation.valid?

    estimation.global_rate = 0
    assert_not estimation.valid?

    estimation.global_rate = 100
    assert estimation.valid?
  end

  test "global_rate allows nil" do
    estimation = estimations(:draft_estimation)
    estimation.global_rate = nil
    assert estimation.valid?
  end

  test "currency must be valid" do
    estimation = estimations(:draft_estimation)
    %w[EUR USD GBP].each do |currency|
      estimation.currency = currency
      assert estimation.valid?
    end

    estimation.currency = "JPY"
    assert_not estimation.valid?
  end

  test "currency allows nil" do
    estimation = estimations(:draft_estimation)
    estimation.currency = nil
    assert estimation.valid?
  end

  test "confidence_score must be between 0 and 1" do
    estimation = estimations(:draft_estimation)

    estimation.confidence_score = -0.1
    assert_not estimation.valid?

    estimation.confidence_score = 1.1
    assert_not estimation.valid?

    estimation.confidence_score = 0.5
    assert estimation.valid?

    estimation.confidence_score = 0
    assert estimation.valid?

    estimation.confidence_score = 1
    assert estimation.valid?
  end

  test "has many functional_blocks ordered by position" do
    estimation = estimations(:completed_estimation)
    blocks = estimation.functional_blocks
    assert blocks.any?
    blocks.each_cons(2) do |a, b|
      assert a.position <= b.position
    end
  end

  test "has many tasks through functional_blocks" do
    estimation = estimations(:completed_estimation)
    assert estimation.tasks.any?
  end

  test "has many references" do
    estimation = estimations(:completed_estimation)
    assert estimation.references.any?
  end

  test "accepts nested attributes for functional_blocks" do
    estimation = estimations(:draft_estimation)
    estimation.update!(functional_blocks_attributes: [
      { name: "Nuevo Bloque", position: 0 }
    ])
    assert estimation.functional_blocks.find_by(name: "Nuevo Bloque")
  end

  test "recent scope orders by created_at desc" do
    estimations = Estimation.recent
    estimations.each_cons(2) do |a, b|
      assert a.created_at >= b.created_at
    end
  end

  test "search_by_title finds matching estimations" do
    results = Estimation.search_by_title("Completa")
    assert results.any?
  end
end
