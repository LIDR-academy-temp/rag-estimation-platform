require "test_helper"

class ReferenceTest < ActiveSupport::TestCase
  test "valid reference" do
    ref = references(:high_similarity_ref)
    assert ref.valid?
  end

  test "similarity_score must be between 0 and 1" do
    ref = references(:high_similarity_ref)

    ref.similarity_score = -0.1
    assert_not ref.valid?

    ref.similarity_score = 1.1
    assert_not ref.valid?

    ref.similarity_score = 0.5
    assert ref.valid?
  end

  test "similarity_score allows nil" do
    ref = references(:high_similarity_ref)
    ref.similarity_score = nil
    assert ref.valid?
  end

  test "by_similarity orders descending" do
    refs = Reference.by_similarity
    refs.each_cons(2) do |a, b|
      assert a.similarity_score >= b.similarity_score
    end
  end

  test "belongs to estimation" do
    ref = references(:high_similarity_ref)
    assert_equal estimations(:completed_estimation), ref.estimation
  end
end
