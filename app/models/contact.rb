class Contact < ApplicationRecord
  IDENTIFYING_FIELDS = %i[first_name last_name company email phone].freeze

  SEARCHABLE_FIELDS = %i[first_name last_name company email].freeze

  validate :must_have_identifying_field

  # peer: true = confrères (agents at other agencies we share listings with);
  # peer: false = our own contacts/leads.
  scope :peers, -> { where(peer: true) }
  scope :contacts_only, -> { where(peer: false) }

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

  # "Last First" for list rows and email greetings, skipping blank parts.
  def listing_name
    [ last_name, first_name ].compact_blank.join(" ")
  end

  private

  def must_have_identifying_field
    return if IDENTIFYING_FIELDS.any? { |f| self[f].present? }

    errors.add(:base, "must have a name, company, email, or phone")
  end
end
