require "test_helper"

class DocumentTest < ActiveSupport::TestCase
  test "valid document" do
    doc = documents(:completed_doc)
    assert doc.valid?
  end

  test "title must be present" do
    doc = documents(:completed_doc)
    doc.title = nil
    assert_not doc.valid?
    assert_includes doc.errors[:title], "can't be blank"
  end

  test "status must be valid" do
    doc = documents(:completed_doc)

    %w[pending processing completed failed].each do |status|
      doc.status = status
      assert doc.valid?, "#{status} should be valid"
    end

    doc.status = "invalid"
    assert_not doc.valid?
  end

  test "by_status scope filters correctly" do
    completed = Document.by_status("completed")
    assert completed.all? { |d| d.status == "completed" }
  end

  test "by_status scope returns all when nil" do
    assert_equal Document.count, Document.by_status(nil).count
  end

  test "recent scope orders by created_at desc" do
    docs = Document.recent
    docs.each_cons(2) do |a, b|
      assert a.created_at >= b.created_at
    end
  end

  test "search_by_title finds matching documents" do
    results = Document.search_by_title("E-commerce")
    assert results.any?
    assert results.all? { |d| d.title.downcase.include?("e-commerce") }
  end

  test "search_by_title returns all when nil" do
    assert_equal Document.count, Document.search_by_title(nil).count
  end

  test "belongs to user" do
    doc = documents(:completed_doc)
    assert_equal users(:antonio), doc.user
  end

  test "has one chunks breakdown" do
    doc = documents(:completed_doc)
    assert_not_nil doc.chunks_breakdown
  end
end
