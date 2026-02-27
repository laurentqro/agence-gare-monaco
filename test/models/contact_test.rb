require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "valid contact" do
    contact = Contact.new(
      first_name: "Jean",
      last_name: "Dupont",
      email: "jean@example.com",
      phone: "+33 6 12 34 56 78"
    )
    assert contact.valid?
  end

  test "requires email" do
    contact = Contact.new(first_name: "Jean", last_name: "Dupont")
    assert_not contact.valid?
    assert_includes contact.errors[:email], "can't be blank"
  end

  test "email is unique" do
    Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    duplicate = Contact.new(first_name: "Pierre", last_name: "Martin", email: "jean@example.com")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:email], "has already been taken"
  end

  test "requires first_name" do
    contact = Contact.new(last_name: "Dupont", email: "jean@example.com")
    assert_not contact.valid?
    assert_includes contact.errors[:first_name], "can't be blank"
  end

  test "requires last_name" do
    contact = Contact.new(first_name: "Jean", email: "jean@example.com")
    assert_not contact.valid?
    assert_includes contact.errors[:last_name], "can't be blank"
  end
end
