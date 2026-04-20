class PropertyBrochureCache
  def self.fetch(property, locale:, include_logo:)
    cached = property.cached_brochure(locale: locale, include_logo: include_logo)
    return cached.blob.download if cached

    PropertyPdfGenerator.new(property, locale: locale, include_logo: include_logo).generate
  end
end
