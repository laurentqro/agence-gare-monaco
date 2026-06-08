require "csv"

# Imports peer agents ("confrères") from the legacy site's partner CSV export
# into the `contacts` table, flagged with `peer: true`. A peer is a fellow
# agent at another agency we cooperate with on listings. Idempotent: rows are
# matched on `(peer: true, legacy_id)`, so peers keep a legacy ID space
# separate from ordinary contacts and re-running updates in place.
#
# Legacy columns: id, person, name, email, telephone, link_agency, link_agent.
# - `person` is "SURNAME Firstname"; split on the first space into last/first.
# - `name` is the agency, stored as `company`.
# - `telephone` is messy (embedded newlines, numbers duplicated with and without
#   a space, "/"-separated alternates); cleaned via {#clean_phone}.
# - link_agency / link_agent (internal Immotoolbox URLs) are dropped.
class LegacyPeerImporter
  Result = Struct.new(:imported, :updated, :skipped, keyword_init: true)

  def initialize(path, logger: nil)
    @path = path
    @logger = logger
  end

  def call
    result = Result.new(imported: 0, updated: 0, skipped: 0)

    CSV.foreach(@path, headers: true) do |row|
      attrs = map_attributes(row)

      unless identifiable?(attrs)
        result.skipped += 1
        next
      end

      contact = Contact.find_or_initialize_by(peer: true, legacy_id: row["id"].to_i)
      was_new = contact.new_record?
      contact.assign_attributes(attrs)
      contact.save!

      was_new ? result.imported += 1 : result.updated += 1
    end

    log "Imported #{result.imported}, updated #{result.updated}, skipped #{result.skipped}."
    result
  end

  private

  def map_attributes(row)
    last, first = split_person(row["person"])
    {
      last_name: last,
      first_name: first,
      company: presence(row["name"]),
      email: presence(row["email"])&.downcase,
      phone: clean_phone(row["telephone"])
    }
  end

  # "SURNAME Firstname" => [last, first]. A single token becomes last_name only.
  def split_person(person)
    value = person.to_s.strip
    return [nil, nil] if value.empty?

    last, first = value.split(/\s+/, 2)
    [presence(last), presence(first)]
  end

  # Strips newlines/whitespace, collapses numbers duplicated with or without a
  # separator, and joins distinct alternates with " / ".
  def clean_phone(raw)
    tokens = raw.to_s.split(%r{[\s/]+}).map(&:strip).reject(&:empty?)
    tokens = tokens.map { |t| collapse_doubled(t) }.uniq
    tokens.empty? ? nil : tokens.join(" / ")
  end

  # A token whose digits are the same string repeated twice (e.g. "06387805460638780546"
  # => "0638780546") is collapsed, preserving a leading "+".
  def collapse_doubled(token)
    digits = token.gsub(/\D/, "")
    return token if digits.length < 8 || digits.length.odd?

    half = digits.length / 2
    return token unless digits[0...half] == digits[half..]

    (token.start_with?("+") ? "+" : "") + digits[0...half]
  end

  def identifiable?(attrs)
    Contact::IDENTIFYING_FIELDS.any? { |f| attrs[f].present? }
  end

  def presence(value)
    value = value.to_s.strip
    value.empty? ? nil : value
  end

  def log(message)
    @logger&.call(message)
  end
end
