class PropertyBrochureCache
  def self.fetch(property, locale:, include_logo:)
    cached = property.cached_brochure(locale: locale, include_logo: include_logo)
    return cached.blob.download if cached

    PropertyPdfGenerator.new(property, locale: locale, include_logo: include_logo).generate
  end

  # Generates and attaches one variant if it is not cached yet, so a fan-out
  # (one share job per recipient) pays the Typst generation at most once
  # instead of once per recipient. Attaching a fresh blob cannot collide with
  # a concurrent PropertyBrochureGenerationJob run: distinct blobs never hit
  # the attachments unique index, and that job's purge clears any extras.
  def self.ensure_cached(property, locale:, include_logo:)
    return if property.cached_brochure(locale: locale, include_logo: include_logo)
    # Never persist a variant for an untranslated property: a lone attached PDF
    # makes the property look cached and would linger until translation
    # succeeds. Callers still get on-demand bytes via fetch; only the caching
    # is declined. Mirrors the guard in PropertyBrochureGenerationJob.
    return if property.translation_source_hash.nil?

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
