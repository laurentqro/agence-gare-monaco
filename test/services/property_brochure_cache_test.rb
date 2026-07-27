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
    # ensure_cached declines to persist variants for an untranslated property,
    # so the default fixture must look translated. Tests exercising the decline
    # path nil this out themselves.
    @property.update_columns(translation_source_hash: "translated-hash")
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

  test "ensure_cached does not persist a variant for an untranslated property" do
    # A lone attached variant makes the property look cached (attached? is true)
    # and would survive until translation succeeds. The share flow can still
    # generate on demand; it just must not leave a persistent artifact of the
    # untranslated state.
    @property.update_columns(translation_source_hash: nil)

    PropertyBrochureCache.ensure_cached(@property, locale: :fr, include_logo: true)

    refute @property.reload.brochures.attached?,
           "an untranslated property must not accumulate cached brochure variants"
  end

  test "fetch still serves an on-demand PDF for an untranslated property without caching it" do
    # The public page for an untranslated property already renders FR-fallback
    # text, so its download button must keep working; the PDF matches the page.
    # What must not happen is the bytes being persisted as a cached variant.
    @property.update_columns(translation_source_hash: nil)

    pdf_bytes = PropertyBrochureCache.fetch(@property, locale: :fr, include_logo: true)

    assert pdf_bytes.start_with?("%PDF"), "fetch must still produce a PDF on demand"
    refute @property.reload.brochures.attached?, "fetch must not cache for an untranslated property"
  end
end
