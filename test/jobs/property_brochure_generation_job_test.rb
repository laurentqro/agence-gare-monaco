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
    # The job declines to render an untranslated property, so the default
    # fixture must look translated. Tests that exercise the decline path
    # nil this out themselves.
    @property.update_columns(translation_source_hash: "translated-hash")
    # Clear attachments that a model callback may have enqueued + run.
    @property.brochures.purge if @property.brochures.attached?
  end

  test "generates nothing for a property whose translation failed" do
    # Enforced here rather than at each caller: five places enqueue this job
    # (sync, image callback, model, translator, backfill rake task), and an
    # untranslated property must get brochures from none of them. 8 of the 9
    # locales would otherwise render from missing translations.
    @property.update_columns(
      translation_source_hash: nil,
      translations_status: { "_error" => { "class" => "RubyLLM::UnauthorizedError",
                                           "message" => "bad key",
                                           "failed_at" => Time.current.iso8601 } }
    )

    PropertyPdfGenerator.stub_any_instance(:generate, "%PDF-1.4 fake") do
      PropertyBrochureGenerationJob.perform_now(@property.id)
    end

    refute @property.reload.brochures.attached?,
           "an untranslated property must not get a brochure cache"
  end

  test "logs its decline so an operator can see why a property has no cache" do
    # A bare return is invisible: brochures:backfill reports "N enqueued" while
    # the jobs all no-op, and an operator has nothing to grep for.
    @property.update_columns(translation_source_hash: nil)

    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    begin
      PropertyPdfGenerator.stub_any_instance(:generate, "%PDF-1.4 fake") do
        PropertyBrochureGenerationJob.perform_now(@property.id)
      end
    ensure
      Rails.logger = original_logger
    end

    assert_match(/#{@property.id}/, io.string, "the declined property id must be logged")
    assert_match(/translat/i, io.string, "the log line must say why the job declined")
  end

  test "does not purge existing brochures when it declines to regenerate" do
    # A property that had good brochures and later fails a re-translation must
    # keep serving what it has: purging would leave every download paying full
    # Typst generation for a property we are refusing to regenerate.
    PropertyPdfGenerator.stub_any_instance(:generate, "%PDF-1.4 fake") do
      PropertyBrochureGenerationJob.perform_now(@property.id)
    end
    assert @property.reload.brochures.attached?, "precondition: brochures exist"
    count_before = @property.brochures.count

    @property.update_columns(
      translation_source_hash: nil,
      translations_status: { "_error" => { "class" => "RubyLLM::ServerError",
                                           "message" => "later failure",
                                           "failed_at" => Time.current.iso8601 } }
    )
    PropertyPdfGenerator.stub_any_instance(:generate, "%PDF-1.4 fake") do
      PropertyBrochureGenerationJob.perform_now(@property.id)
    end

    assert_equal count_before, @property.reload.brochures.count,
                 "existing brochures must survive a declined regeneration"
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

  test "serializes concurrent runs per property to avoid attachment races" do
    # Many jobs for the same property are enqueued during a sync (one per saved
    # PropertyImage). Without per-property concurrency control they interleave
    # purge+attach and collide on the active_storage_attachments UNIQUE index,
    # raising ActiveRecord::RecordNotUnique. The concurrency key must be scoped
    # to the property so only one runs at a time and the rest queue.
    assert_equal 1, PropertyBrochureGenerationJob.concurrency_limit,
                 "expected per-property serialization (concurrency limit 1)"

    # The instance #concurrency_key computes the final key string from the
    # configured proc and the job arguments.
    key = PropertyBrochureGenerationJob.new(@property.id).concurrency_key
    assert key.present?, "expected a concurrency key scoped to the property"
    assert_includes key.to_s, @property.id.to_s,
                    "concurrency key must include the property id so distinct properties run in parallel"
  end

  test "concurrency lock outlasts a full brochure generation run" do
    # The lock duration must exceed the worst-case run time (18 PDFs) so the
    # semaphore can't expire mid-run and let a second job in, reopening the
    # race. The Solid Queue default is only 3 minutes; pin it explicitly.
    assert_operator PropertyBrochureGenerationJob.concurrency_duration, :>=, 10.minutes,
                    "expected an explicit concurrency duration well above worst-case run time"
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
