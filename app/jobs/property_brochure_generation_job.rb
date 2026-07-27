class PropertyBrochureGenerationJob < ApplicationJob
  queue_as :default

  # Many jobs for one property are enqueued during a sync (one per saved image).
  # Serialize them per property so the purge+attach sequence can't interleave and
  # collide on the active_storage_attachments UNIQUE index (RecordNotUnique).
  # duration must exceed the worst-case run (18 PDFs) so the lock can't expire
  # mid-run and let a second job in; the Solid Queue default is only 3 minutes.
  limits_concurrency to: 1, key: ->(property_id) { property_id }, duration: 15.minutes

  LOCALES = %i[fr en it de sv no da fi ru].freeze
  LOGO_VARIANTS = [ true, false ].freeze

  def perform(property_id)
    property = Property.find_by(id: property_id)
    return unless property

    # Never render an untranslated property: 8 of the 9 locales would come out
    # of missing translations. Enforced here rather than at each caller because
    # five places enqueue this job (the sync, the PropertyImage callback, the
    # model, the translator, and the backfill rake task). Return before the
    # purge so a property that had good brochures and later failed a
    # re-translation keeps serving the ones it already has.
    return if property.translation_source_hash.nil?

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
