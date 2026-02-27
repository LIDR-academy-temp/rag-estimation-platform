require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = User.new(name: "Test", email: "test@example.com", password: "password123")
    assert user.valid?
  end

  test "email must be present" do
    user = users(:antonio)
    user.email = nil
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "email must be unique case insensitive" do
    existing = users(:antonio)
    user = User.new(name: "Otro", email: existing.email.upcase, password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "email must have valid format" do
    user = User.new(name: "Test", email: "invalid-email", password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "name must be present" do
    user = users(:antonio)
    user.name = nil
    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "password minimum 6 characters on create" do
    user = User.new(name: "Test", email: "new@example.com", password: "short")
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  test "email is downcased before save" do
    user = User.create!(name: "Test", email: "UPPER@EXAMPLE.COM", password: "password123")
    assert_equal "upper@example.com", user.reload.email
  end

  test "has many documents" do
    user = users(:antonio)
    assert_respond_to user, :documents
  end

  test "has many estimations" do
    user = users(:antonio)
    assert_respond_to user, :estimations
  end

  test "destroying user destroys documents" do
    user = users(:antonio)
    doc_count = user.documents.count
    assert doc_count > 0
    assert_difference("Document.count", -doc_count) { user.destroy }
  end
end
