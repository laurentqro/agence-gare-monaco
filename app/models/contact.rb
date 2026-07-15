class Contact < ApplicationRecord
  IDENTIFYING_FIELDS = %i[first_name last_name company email phone].freeze

  SEARCHABLE_FIELDS = %i[first_name last_name company email].freeze

  # What the person is to the agency (not their role on a given transaction).
  # "contact" is the unclassified default; a prospect who signs a mandate gets
  # recategorized to owner or tenant. Everything except "peer" is a client or
  # potential client and belongs on the AML screening roster.
  # `validate: true` (instead of the raising default) keeps an unknown value a
  # form error, not an ArgumentError.
  enum :category, %w[contact prospect peer owner tenant].index_with(&:itself), validate: true

  CATEGORIES = categories.keys.freeze

  validate :must_have_identifying_field
  validate :legacy_id_unique_within_partition

  # category "peer" = confrères (agents at other agencies we share listings
  # with); every other category = our own contacts/leads. Named aliases of the
  # enum scopes (peer / not_peer) that read better at call sites.
  scope :peers, -> { peer }
  scope :contacts_only, -> { not_peer }

  # Contacts that can actually be emailed: a present (non-nil, non-blank) email.
  scope :with_email, -> { where.not(email: [ nil, "" ]) }

  # Case-insensitive match across name, company, and email. Blank query returns
  # the full relation.
  scope :search, ->(query) {
    query = query.to_s.strip
    next all if query.blank?

    pattern = "%#{sanitize_sql_like(query)}%"
    clause = SEARCHABLE_FIELDS.map { |f| "#{f} LIKE :pattern" }.join(" OR ")
    where(clause, pattern: pattern)
  }

  # The persisted category string even when it is outside the enum mapping
  # (the enum reads an out-of-taxonomy value as nil). The admin UI uses this
  # to surface anomalous rows instead of hiding them.
  def raw_category
    category || category_before_type_cast.to_s.presence
  end

  # "Last First" for list rows and email greetings, skipping blank parts.
  # Name-less contacts (consulates, SCIs) fall back to company, then email, so
  # picker rows and selection chips are never blank.
  def listing_name
    name = [ last_name, first_name ].compact_blank.join(" ")
    name.presence || company.presence || email.to_s
  end

  private

  def must_have_identifying_field
    return if IDENTIFYING_FIELDS.any? { |f| self[f].present? }

    errors.add(:base, "must have a name, company, email, or phone")
  end

  # Mirrors the partial unique indexes on legacy_id: confrères and everyone
  # else draw from two separate legacy ID spaces, and those spaces overlap.
  # Validating here turns a colliding save (typically a recategorization
  # across the peer boundary) into a form error instead of a database-level
  # RecordNotUnique.
  def legacy_id_unique_within_partition
    return if legacy_id.blank?

    partition = category == "peer" ? Contact.peers : Contact.contacts_only
    return unless partition.where(legacy_id: legacy_id).where.not(id: id).exists?

    errors.add(:legacy_id, "is already used by another contact in the same peer / non-peer group")
  end
end
