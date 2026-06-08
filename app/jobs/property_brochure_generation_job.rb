class PropertyBrochureGenerationJob < ApplicationJob
  queue_as :default

  # Many jobs for one property are enqueued during a sync (one per saved image).
  # Serialize them per property so the purge+attach sequence can't interleave and
  # collide on the active_storage_attachments UNIQUE index (RecordNotUnique).
  limits_concurrency to: 1, key: ->(property_id) { property_id }

  LOCALES = %i[fr en it de sv no da fi ru].freeze
  LOGO_VARIANTS = [ true, false ].freeze

  def perform(property_id)
    property = Property.find_by(id: property_id)
    return unless property

    property.brochures.purge

    LOCALES.each do |locale|
      LOGO_VARIANTS.each do |include_logo|
        pdf_bytes = PropertyPdfGenerator.new(property, locale: locale, include_logo: include_logo).generate
        suffix = include_logo ? "" : "-no-logo"
        property.brochures.attach(
          io: StringIO.new(pdf_bytes),
          filename: "#{property.brochure_filename.sub(/\.pdf\z/, '')}-#{locale}#{suffix}.pdf",
          content_type: "application/pdf",
          metadata: { locale: locale.to_s, include_logo: include_logo }
        )
      end
    end
  end
end
