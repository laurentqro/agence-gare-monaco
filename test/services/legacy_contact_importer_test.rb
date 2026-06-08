require "test_helper"

class LegacyContactImporterTest < ActiveSupport::TestCase
  FIXTURE = Rails.root.join("test/fixtures/files/legacy_contacts.csv")

  test "imports identifiable rows and skips empty ones" do
    result = nil
    assert_difference "Contact.count", 5 do
      result = LegacyContactImporter.new(FIXTURE).call
    end
    assert_equal 5, result.imported
    assert_equal 0, result.updated
    assert_equal 1, result.skipped
  end

  test "maps legacy columns onto contact attributes" do
    LegacyContactImporter.new(FIXTURE).call
    c = Contact.find_by(legacy_id: 10)
    assert_equal "Tanguy", c.first_name
    assert_equal "Anders", c.last_name
    assert_equal "tanguy@example.com", c.email
    assert_equal "+377 99 00 11 22", c.phone
    assert_equal "12 rue de la Gare", c.address
    assert_equal "Monaco", c.city
    assert_equal "98000", c.postcode
    assert_equal "Monaco", c.country
    assert_equal "Recherche 3 pièces", c.notes
  end

  test "keeps a company-only contact" do
    LegacyContactImporter.new(FIXTURE).call
    c = Contact.find_by(legacy_id: 12)
    assert_equal "Consulat de Belgique", c.company
    assert_nil c.first_name
    assert_equal "consulat@example.mc", c.email
  end

  test "trims whitespace and blanks become nil" do
    LegacyContactImporter.new(FIXTURE).call
    c = Contact.find_by(legacy_id: 13)
    assert_equal "Meloni", c.first_name
    assert_equal "Recherche 2 ou 3p loc ou achat", c.notes
    assert_nil c.email
    assert_nil c.address
  end

  test "downcases email" do
    LegacyContactImporter.new(FIXTURE).call
    assert_equal "anna@example.com", Contact.find_by(legacy_id: 15).email
  end

  test "is idempotent and updates on re-run" do
    LegacyContactImporter.new(FIXTURE).call
    result = nil
    assert_no_difference "Contact.count" do
      result = LegacyContactImporter.new(FIXTURE).call
    end
    assert_equal 0, result.imported
    assert_equal 5, result.updated
  end

  test "re-run picks up edited source values" do
    LegacyContactImporter.new(FIXTURE).call
    Contact.find_by(legacy_id: 10).update!(city: "Changed")
    LegacyContactImporter.new(FIXTURE).call
    assert_equal "Monaco", Contact.find_by(legacy_id: 10).reload.city
  end
end
