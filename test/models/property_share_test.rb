require "test_helper"

class PropertyShareTest < ActiveSupport::TestCase
  setup do
    @property = Property.create!(
      reference: "MC-PS-001",
      title: { "fr" => "Studio" },
      description: { "fr" => "Studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
  end

  def build_share(**attrs)
    PropertyShare.new({ property: @property, subject: "Sujet", pending_count: 2 }.merge(attrs))
  end

  test "requires a subject" do
    share = build_share(subject: "")
    assert_not share.valid?
    assert share.errors[:subject].any?
  end

  test "requires at least one recipient on create" do
    share = build_share(pending_count: 0)
    assert_not share.valid?
    assert_includes share.errors.full_messages, "Veuillez sélectionner au moins un contact."
  end

  test "attach_pdf defaults to false and include_logo to true" do
    share = PropertyShare.new
    assert_equal false, share.attach_pdf
    assert_equal true, share.include_logo
  end

  test "mark_sent! claims a contact exactly once" do
    share = build_share.tap(&:save!)
    assert share.mark_sent!(42)
    assert_not share.reload.mark_sent!(42), "a replayed claim must return false"
    assert_equal 1, share.reload.pending_count
    assert_equal [ 42 ], share.sent_contact_ids
  end

  test "the last claim destroys the record" do
    share = build_share(pending_count: 1).tap(&:save!)
    assert share.mark_sent!(42)
    assert_not PropertyShare.exists?(share.id)
  end

  test "recipients validation does not block the countdown updates" do
    share = build_share(pending_count: 2).tap(&:save!)
    assert share.mark_sent!(1)
    assert_equal 1, share.reload.pending_count
  end

  test "destroying the property destroys its pending shares" do
    share = build_share.tap(&:save!)
    @property.destroy!
    assert_not PropertyShare.exists?(share.id)
  end
end
