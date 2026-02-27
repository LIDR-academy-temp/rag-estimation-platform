require "test_helper"

class ChunksBreakdownTest < ActiveSupport::TestCase
  test "total sums all five fields" do
    breakdown = chunks_breakdowns(:completed_breakdown)
    expected = breakdown.project_overview + breakdown.scope_block +
               breakdown.line_item + breakdown.phase + breakdown.team_conditions
    assert_equal expected, breakdown.total
    assert_equal 15, breakdown.total
  end

  test "total handles nil fields" do
    breakdown = ChunksBreakdown.new(document: documents(:pending_doc))
    assert_equal 0, breakdown.total
  end

  test "belongs to document" do
    breakdown = chunks_breakdowns(:completed_breakdown)
    assert_equal documents(:completed_doc), breakdown.document
  end
end
