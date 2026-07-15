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

  test "defaults to the plain contact category" do
    contact = Contact.create!(first_name: "Jean", last_name: "Dupont")
    assert_equal "contact", contact.category
  end

  test "accepts each known category" do
    Contact::CATEGORIES.each do |category|
      contact = Contact.new(last_name: "Dupont", category: category)
      assert contact.valid?, "expected category #{category.inspect} to be valid"
    end
  end

  test "rejects an unknown category" do
    contact = Contact.new(last_name: "Dupont", category: "banana")
    assert_not contact.valid?
    assert contact.errors[:category].any?
  end

  test "raw_category surfaces an out-of-taxonomy value that the enum reads as nil" do
    contact = Contact.create!(last_name: "Étrange")
    contact.update_columns(category: "vip")
    contact.reload
    assert_nil contact.category
    assert_equal "vip", contact.raw_category
    assert_equal "peer", Contact.create!(last_name: "Smith", category: "peer").raw_category
  end

  test "exposes a predicate and a scope per category" do
    peer = Contact.create!(last_name: "Smith", category: "peer")
    assert peer.peer?
    assert_not peer.contact?
    assert_equal [ peer ], Contact.peer.to_a
    assert_equal [], Contact.owner.to_a
  end

  test "legacy_id is unique only within the peer / non-peer split" do
    Contact.create!(company: "Client SCI", legacy_id: 2)
    peer = Contact.new(company: "Peer Agency", legacy_id: 2, category: "peer")
    assert peer.valid?, peer.errors.full_messages.to_sentence
    assert peer.save
  end

  test "legacy_id collides across non-peer categories" do
    # Owners, tenants, and prospects share the ordinary-contacts legacy ID
    # space; only confrères have their own.
    Contact.create!(company: "Client SCI", legacy_id: 2)
    owner = Contact.new(company: "Owner SCI", legacy_id: 2, category: "owner")
    assert_not owner.valid?
    assert owner.errors[:legacy_id].any?
  end

  test "recategorizing across the peer boundary is invalid when legacy_ids collide" do
    # Legacy contact and peer imports use overlapping ID sequences, so this
    # must surface as a validation error, not a database-level 500.
    Contact.create!(company: "Client SCI", legacy_id: 5)
    peer = Contact.create!(company: "Peer Agency", legacy_id: 5, category: "peer")

    peer.category = "owner"
    assert_not peer.valid?
    assert peer.errors[:legacy_id].any?
  end

  test "recategorizing within the non-peer partition keeps its legacy_id valid" do
    contact = Contact.create!(company: "Client SCI", legacy_id: 6)
    contact.category = "owner"
    assert contact.valid?, contact.errors.full_messages.to_sentence
  end

  test "contacts without a legacy_id never collide" do
    Contact.create!(last_name: "Dupont")
    manual = Contact.new(last_name: "Martin")
    assert manual.valid?
  end

  test "search matches first name, last name, company, or email (case-insensitive)" do
    berg = Contact.create!(first_name: "Anna", last_name: "Berg", email: "anna@acme.com", company: "Acme SCI")
    dupont = Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@other.com")

    assert_equal [ berg ], Contact.search("anna").to_a
    assert_equal [ berg ], Contact.search("BERG").to_a
    assert_equal [ berg ], Contact.search("acme").to_a
    assert_equal [ dupont ], Contact.search("other.com").to_a
    assert_equal [], Contact.search("nomatch").to_a
  end

  test "search returns all when query is blank" do
    Contact.create!(first_name: "Anna", last_name: "Berg")
    Contact.create!(first_name: "Jean", last_name: "Dupont")
    assert_equal 2, Contact.search(nil).count
    assert_equal 2, Contact.search("  ").count
  end

  test "peers and contacts_only scopes split on the peer category" do
    contact = Contact.create!(last_name: "Ordinary")
    prospect = Contact.create!(last_name: "Curieux", category: "prospect")
    owner = Contact.create!(last_name: "Bailleur", category: "owner")
    tenant = Contact.create!(last_name: "Preneur", category: "tenant")
    peer = Contact.create!(last_name: "Confrère", category: "peer")

    assert_equal [ peer ], Contact.peers.to_a
    assert_equal [ contact, prospect, owner, tenant ].sort_by(&:id),
                 Contact.contacts_only.order(:id).to_a
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

  test "listing_name joins last and first name" do
    contact = Contact.new(last_name: "Dupont", first_name: "Jean")
    assert_equal "Dupont Jean", contact.listing_name
  end

  test "listing_name skips blank name parts" do
    assert_equal "Berg", Contact.new(last_name: "Berg", first_name: "").listing_name
    assert_equal "Anna", Contact.new(last_name: nil, first_name: "Anna").listing_name
  end

  test "listing_name falls back to company when there is no name" do
    contact = Contact.new(company: "Consulat de Finlande", email: "info@consulatfinlande.mc")
    assert_equal "Consulat de Finlande", contact.listing_name
  end

  test "listing_name falls back to email when there is no name or company" do
    contact = Contact.new(email: "info@consulatfinlande.mc")
    assert_equal "info@consulatfinlande.mc", contact.listing_name
  end
end
