require "test_helper"

class PropertyBrochureGenerationJobTest < ActiveJob::TestCase
  LOCALES = %i[fr en it de sv no da fi ru]

  setup do
    @property = Property.create!(
      reference: "MC-BROCHURE-JOB",
      title: { "fr" => "Studio" },
      description: { "fr" => "Desc" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_000_000,
      published: true
    )
    # Clear attachments that a model callback may have enqueued + run.
    @property.brochures.purge if @property.brochures.attached?
  end

  test "attaches one PDF per locale in both logo variants" do
    PropertyPdfGenerator.stub_any_instance(:generate, "%PDF-1.4 fake") do
      PropertyBrochureGenerationJob.perform_now(@property.id)
    end

    @property.reload
    LOCALES.each do |locale|
      assert @property.cached_brochure(locale: locale, include_logo: true).present?,
             "missing with-logo brochure for #{locale}"
      assert @property.cached_brochure(locale: locale, include_logo: false).present?,
             "missing no-logo brochure for #{locale}"
    end
  end

  test "regenerating replaces previous attachments" do
    PropertyPdfGenerator.stub_any_instance(:generate, "%PDF-1.4 v1") do
      PropertyBrochureGenerationJob.perform_now(@property.id)
    end
    first_blob_id = @property.cached_brochure(locale: :fr, include_logo: true).blob.id

    PropertyPdfGenerator.stub_any_instance(:generate, "%PDF-1.4 v2") do
      PropertyBrochureGenerationJob.perform_now(@property.id)
    end
    @property.reload
    new_blob_id = @property.cached_brochure(locale: :fr, include_logo: true).blob.id

    refute_equal first_blob_id, new_blob_id
  end

  test "missing property id is a no-op" do
    assert_nothing_raised do
      PropertyBrochureGenerationJob.perform_now(-1)
    end
  end
end

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
