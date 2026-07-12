require "test_helper"

class PropertyBrochureCacheTest < ActiveSupport::TestCase
  setup do
    @property = Property.create!(
      reference: "MC-CACHE-001",
      title: { "fr" => "Studio Carré d'Or" },
      description: { "fr" => "Magnifique studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
  end

  def attach_fake_brochure(include_logo:, bytes: "%PDF-fake")
    @property.brochures.attach(
      io: StringIO.new(bytes),
      filename: "x.pdf",
      content_type: "application/pdf",
      metadata: { locale: "fr", include_logo: include_logo }
    )
  end

  test "ensure_cached attaches the missing variant so later fetches hit the cache" do
    assert_nil @property.cached_brochure(locale: :fr, include_logo: true)

    PropertyBrochureCache.ensure_cached(@property, locale: :fr, include_logo: true)

    cached = @property.reload.cached_brochure(locale: :fr, include_logo: true)
    assert cached.present?, "expected the fr/logo variant to be cached"
    assert_equal "application/pdf", cached.blob.content_type
    # fetch must now serve the cached bytes, not regenerate.
    assert_equal cached.blob.download, PropertyBrochureCache.fetch(@property, locale: :fr, include_logo: true)
  end

  test "ensure_cached is a no-op when the variant is already cached" do
    attach_fake_brochure(include_logo: true)
    blob_id = @property.cached_brochure(locale: :fr, include_logo: true).blob.id

    PropertyBrochureCache.ensure_cached(@property, locale: :fr, include_logo: true)

    assert_equal blob_id, @property.reload.cached_brochure(locale: :fr, include_logo: true).blob.id
    assert_equal 1, @property.brochures.count
  end

  test "ensure_cached only caches the requested variant" do
    attach_fake_brochure(include_logo: true)

    PropertyBrochureCache.ensure_cached(@property, locale: :fr, include_logo: false)

    assert @property.reload.cached_brochure(locale: :fr, include_logo: false).present?
    assert_equal 2, @property.brochures.count
  end
end
