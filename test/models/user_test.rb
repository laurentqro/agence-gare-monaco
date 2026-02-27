require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "valid user" do
    user = User.new(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    assert user.valid?
  end

  test "requires email_address" do
    user = User.new(password: "securepassword123")
    assert_not user.valid?
    assert_includes user.errors[:email_address], "can't be blank"
  end

  test "email_address must be unique" do
    User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    duplicate = User.new(email_address: "adrien@agencegaremonaco.com", password: "otherpassword")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email_address], "has already been taken"
  end

  test "email_address uniqueness is case insensitive" do
    User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    duplicate = User.new(email_address: "Adrien@AgenceGareMonaco.com", password: "otherpassword")
    assert_not duplicate.valid?
  end

  test "normalizes email_address to lowercase and stripped" do
    user = User.new(email_address: "  Adrien@AgenceGareMonaco.com  ", password: "securepassword123")
    user.validate
    assert_equal "adrien@agencegaremonaco.com", user.email_address
  end

  test "authenticates with correct password" do
    user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    assert user.authenticate("securepassword123")
  end

  test "does not authenticate with wrong password" do
    user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    assert_not user.authenticate("wrongpassword")
  end

  test "has many sessions" do
    assert_reflect_on_association User, :sessions
  end

  private

  def assert_reflect_on_association(klass, association_name)
    assert klass.reflect_on_association(association_name), "Expected #{klass} to have association :#{association_name}"
  end
end
