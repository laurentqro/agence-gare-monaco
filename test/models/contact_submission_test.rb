require "test_helper"

class ContactSubmissionTest < ActiveSupport::TestCase
  test "valid contact submission" do
    submission = ContactSubmission.new(
      form_type: "contact",
      name: "Jean Dupont",
      email: "jean@example.com",
      subject: "Enquiry",
      message: "I am interested in your services."
    )
    assert submission.valid?
  end

  test "valid property enquiry submission" do
    property = Property.create!(
      reference: "MC-001",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    submission = ContactSubmission.new(
      form_type: "enquiry",
      name: "Jean Dupont",
      email: "jean@example.com",
      phone: "+33 6 12 34 56 78",
      country: "France",
      message: "I am interested in this property.",
      property: property
    )
    assert submission.valid?
  end

  test "requires form_type" do
    submission = ContactSubmission.new(name: "Jean", email: "jean@example.com", message: "Hello")
    assert_not submission.valid?
    assert_includes submission.errors[:form_type], "can't be blank"
  end

  test "form_type must be contact or enquiry" do
    submission = ContactSubmission.new(form_type: "spam", name: "Jean", email: "jean@example.com", message: "Hello")
    assert_not submission.valid?
    assert_includes submission.errors[:form_type], "is not included in the list"
  end

  test "requires name" do
    submission = ContactSubmission.new(form_type: "contact", email: "jean@example.com", message: "Hello")
    assert_not submission.valid?
    assert_includes submission.errors[:name], "can't be blank"
  end

  test "requires email" do
    submission = ContactSubmission.new(form_type: "contact", name: "Jean", message: "Hello")
    assert_not submission.valid?
    assert_includes submission.errors[:email], "can't be blank"
  end

  test "requires message" do
    submission = ContactSubmission.new(form_type: "contact", name: "Jean", email: "jean@example.com")
    assert_not submission.valid?
    assert_includes submission.errors[:message], "can't be blank"
  end

  test "defaults read to false" do
    submission = ContactSubmission.create!(
      form_type: "contact",
      name: "Jean",
      email: "jean@example.com",
      message: "Hello"
    )
    assert_equal false, submission.read
  end

  test "belongs to property optionally" do
    assoc = ContactSubmission.reflect_on_association(:property)
    assert_equal :belongs_to, assoc.macro
    assert_not assoc.options[:optional].nil?
  end

  test "scope unread returns only unread submissions" do
    ContactSubmission.create!(form_type: "contact", name: "Jean", email: "a@b.com", message: "Hi", read: false)
    ContactSubmission.create!(form_type: "contact", name: "Pierre", email: "c@d.com", message: "Hi", read: true)
    assert_equal 1, ContactSubmission.unread.count
  end
end
