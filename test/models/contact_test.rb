require "test_helper"

class ContactTest < ActiveSupport::TestCase
  test "valid contact with full details" do
    contact = Contact.new(
      first_name: "Jean",
      last_name: "Dupont",
      email: "jean@example.com",
      phone: "+33 6 12 34 56 78"
    )
    assert contact.valid?
  end

  test "valid with only a name" do
    contact = Contact.new(first_name: "Jean", last_name: "Dupont")
    assert contact.valid?
  end

  test "valid with only a company (no personal name)" do
    contact = Contact.new(company: "Consulat de Belgique")
    assert contact.valid?
  end

  test "valid with only a phone" do
    contact = Contact.new(phone: "0607939300")
    assert contact.valid?
  end

  test "valid with only an email" do
    contact = Contact.new(email: "jean@example.com")
    assert contact.valid?
  end

  test "invalid when no identifying field is present" do
    contact = Contact.new(address: "12 rue de la Gare", city: "Monaco")
    assert_not contact.valid?
    assert_includes contact.errors[:base], "must have a name, company, email, or phone"
  end

  test "duplicate emails are allowed" do
    Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    duplicate = Contact.new(first_name: "Pierre", last_name: "Martin", email: "jean@example.com")
    assert duplicate.valid?
  end

  test "stores extended legacy fields" do
    contact = Contact.create!(
      first_name: "Anna",
      last_name: "Berg",
      company: "Acme SCI",
      address: "12 rue de la Gare",
      city: "Monaco",
      postcode: "98000",
      country: "Monaco",
      notes: "Recherche 2 pièces location",
      legacy_id: 10
    )
    contact.reload
    assert_equal "Acme SCI", contact.company
    assert_equal "98000", contact.postcode
    assert_equal "Recherche 2 pièces location", contact.notes
    assert_equal 10, contact.legacy_id
  end
end
