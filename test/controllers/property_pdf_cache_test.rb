require "test_helper"

# Lightweight any-instance stub — avoids a mocha dependency for a one-off need.
unless PropertyPdfGenerator.respond_to?(:stub_any_instance)
  class PropertyPdfGenerator
    def self.stub_any_instance(method, value)
      original = instance_method(method)
      define_method(method) { value }
      yield
    ensure
      define_method(method, original)
    end
  end
end

class PropertyPdfCacheTest < ActionDispatch::IntegrationTest
  setup do
    @property = Property.create!(
      reference: "MC-PDF-CACHE",
      title: { "fr" => "Studio Carré d'Or", "en" => "Sea view studio" },
      description: { "fr" => "Magnifique studio", "en" => "Beautiful studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_290_000,
      published: true
    )
    @property.brochures.purge if @property.brochures.attached?
  end

  def attach_cached_brochure(locale:, include_logo:, bytes:)
    @property.brochures.attach(
      io: StringIO.new(bytes),
      filename: "cached.pdf",
      content_type: "application/pdf",
      metadata: { locale: locale.to_s, include_logo: include_logo }
    )
  end

  test "serves cached PDF bytes when attached (with logo)" do
    attach_cached_brochure(locale: :fr, include_logo: true, bytes: "%PDF-1.4 CACHED-FR-LOGO")

    PropertyPdfGenerator.stub_any_instance(:generate, "should-not-be-called") do
      get "/biens/#{@property.id}-studio-carre-dor/pdf"
    end

    assert_response :success
    assert_equal "application/pdf", response.content_type
    assert_equal "%PDF-1.4 CACHED-FR-LOGO", response.body
  end

  test "serves cached PDF bytes when attached (without logo)" do
    attach_cached_brochure(locale: :fr, include_logo: false, bytes: "%PDF-1.4 CACHED-FR-NOLOGO")

    PropertyPdfGenerator.stub_any_instance(:generate, "should-not-be-called") do
      get "/biens/#{@property.id}-studio-carre-dor/pdf?include_logo=0"
    end

    assert_response :success
    assert_equal "%PDF-1.4 CACHED-FR-NOLOGO", response.body
  end

  test "falls back to on-demand generation when no cached brochure attached" do
    PropertyPdfGenerator.stub_any_instance(:generate, "%PDF-1.4 ON-DEMAND") do
      get "/biens/#{@property.id}-studio-carre-dor/pdf"
    end

    assert_response :success
    assert_equal "%PDF-1.4 ON-DEMAND", response.body
  end

  test "serves correct locale variant" do
    attach_cached_brochure(locale: :fr, include_logo: true, bytes: "%PDF-1.4 FR")
    attach_cached_brochure(locale: :en, include_logo: true, bytes: "%PDF-1.4 EN")

    PropertyPdfGenerator.stub_any_instance(:generate, "should-not-be-called") do
      get "/en/properties/#{@property.id}-sea-view-studio/pdf"
    end
    assert_equal "%PDF-1.4 EN", response.body
  end

  test "admin controller serves cached PDF when attached" do
    User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }

    attach_cached_brochure(locale: :fr, include_logo: true, bytes: "%PDF-1.4 ADMIN-CACHED")

    PropertyPdfGenerator.stub_any_instance(:generate, "should-not-be-called") do
      post admin_property_brochure_url(@property), params: { locale: "fr" }
    end

    assert_response :success
    assert_equal "%PDF-1.4 ADMIN-CACHED", response.body
  end
end
