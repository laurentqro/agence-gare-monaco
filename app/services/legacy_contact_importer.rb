require "csv"

# Imports contacts from the legacy PHP site's MySQL CSV export into the Rails
# `contacts` table. Idempotent: rows are matched on their legacy `id`
# (stored as `Contact#legacy_id`), so re-running updates in place instead of
# duplicating. Rows with no identifying field (name, company, email, phone) are
# skipped. See [[legacy-contacts-import]].
class LegacyContactImporter
  Result = Struct.new(:imported, :updated, :skipped, keyword_init: true)

  # legacy CSV column => Contact attribute
  COLUMN_MAP = {
    "firstname" => :first_name,
    "lastname" => :last_name,
    "company" => :company,
    "address" => :address,
    "city" => :city,
    "zipcode" => :postcode,
    "country" => :country,
    "email" => :email,
    "telephone" => :phone,
    "comments" => :notes
  }.freeze

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

      contact = Contact.find_or_initialize_by(legacy_id: row["id"].to_i)
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
    COLUMN_MAP.each_with_object({}) do |(column, attr), attrs|
      attrs[attr] = normalize(attr, row[column])
    end
  end

  def normalize(attr, value)
    value = value.to_s.strip
    return nil if value.empty?

    attr == :email ? value.downcase : value
  end

  def identifiable?(attrs)
    Contact::IDENTIFYING_FIELDS.any? { |f| attrs[f].present? }
  end

  def log(message)
    @logger&.call(message)
  end
end
