require "test_helper"

class PropertyTest < ActiveSupport::TestCase
  setup do
    @district = District.create!(name: "Monte-Carlo", city: "Monaco")
    @building = Building.create!(name: "Le Montaigne", city: "Monaco", district: @district)
  end

  test "valid property with minimal attributes" do
    property = Property.new(
      reference: "MC-001",
      title: { "fr" => "Studio Monte-Carlo", "en" => "Studio Monte-Carlo" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      published: true
    )
    assert property.valid?
  end

  test "requires reference" do
    property = Property.new(transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    assert_not property.valid?
    assert_includes property.errors[:reference], "can't be blank"
  end

  test "reference is unique" do
    Property.create!(reference: "MC-001", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    duplicate = Property.new(reference: "MC-001", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:reference], "has already been taken"
  end

  test "requires transaction_type" do
    property = Property.new(reference: "MC-001", property_type: "apartment", country: "MC", city: "Monaco")
    assert_not property.valid?
    assert_includes property.errors[:transaction_type], "can't be blank"
  end

  test "transaction_type must be sale or rental" do
    property = Property.new(reference: "MC-001", transaction_type: "lease", property_type: "apartment", country: "MC", city: "Monaco")
    assert_not property.valid?
    assert_includes property.errors[:transaction_type], "is not included in the list"
  end

  test "requires property_type" do
    property = Property.new(reference: "MC-001", transaction_type: "sale", country: "MC", city: "Monaco")
    assert_not property.valid?
    assert_includes property.errors[:property_type], "can't be blank"
  end

  test "requires country" do
    property = Property.new(reference: "MC-001", transaction_type: "sale", property_type: "apartment", city: "Monaco")
    assert_not property.valid?
    assert_includes property.errors[:country], "can't be blank"
  end

  test "requires city" do
    property = Property.new(reference: "MC-001", transaction_type: "sale", property_type: "apartment", country: "MC")
    assert_not property.valid?
    assert_includes property.errors[:city], "can't be blank"
  end

  test "title is stored as JSON" do
    property = Property.create!(
      reference: "MC-001",
      title: { "fr" => "Studio", "en" => "Studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    property.reload
    assert_equal "Studio", property.title["fr"]
    assert_equal "Studio", property.title["en"]
  end

  test "description is stored as JSON" do
    property = Property.create!(
      reference: "MC-001",
      title: { "fr" => "Studio" },
      description: { "fr" => "Beau studio", "en" => "Beautiful studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    property.reload
    assert_equal "Beau studio", property.description["fr"]
  end

  test "belongs to district optionally" do
    property = Property.new(
      reference: "MC-001",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    assert property.valid?
    assert_nil property.district
  end

  test "belongs to building optionally" do
    property = Property.new(
      reference: "MC-001",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    assert property.valid?
    assert_nil property.building
  end

  test "has many property_images" do
    assert_equal :has_many, Property.reflect_on_association(:property_images).macro
  end

  test "has many property_documents" do
    assert_equal :has_many, Property.reflect_on_association(:property_documents).macro
  end

  test "defaults published to false" do
    property = Property.create!(
      reference: "MC-002",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    assert_equal false, property.published
  end

  test "defaults off_market to false" do
    property = Property.create!(
      reference: "MC-003",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    assert_equal false, property.off_market
  end

  test "immotoolbox_id is unique when present" do
    Property.create!(reference: "MC-001", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco", immotoolbox_id: 100)
    duplicate = Property.new(reference: "MC-002", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco", immotoolbox_id: 100)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:immotoolbox_id], "has already been taken"
  end

  test "stores numeric fields" do
    property = Property.create!(
      reference: "MC-001",
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_290_000,
      num_rooms: 3,
      num_bedrooms: 2,
      num_bathrooms: 1,
      num_parkings: 1,
      num_cellars: 0,
      living_area: 85.5,
      total_area: 120.0,
      terrace_area: 15.0,
      floor: 5
    )
    property.reload
    assert_equal 1_290_000, property.price
    assert_equal 3, property.num_rooms
    assert_equal 2, property.num_bedrooms
    assert_equal 1, property.num_bathrooms
    assert_equal 1, property.num_parkings
    assert_equal 0, property.num_cellars
    assert_in_delta 85.5, property.living_area
    assert_in_delta 120.0, property.total_area
    assert_in_delta 15.0, property.terrace_area
    assert_equal 5, property.floor
  end

  test "scope published returns only published properties" do
    Property.create!(reference: "MC-PUB", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco", published: true)
    Property.create!(reference: "MC-UNP", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco", published: false)
    assert_equal 1, Property.published.count
    assert_equal "MC-PUB", Property.published.first.reference
  end

  test "scope for_sale returns sale properties" do
    Property.create!(reference: "MC-SALE", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    Property.create!(reference: "MC-RENT", transaction_type: "rental", property_type: "apartment", country: "MC", city: "Monaco")
    assert_equal 1, Property.for_sale.count
    assert_equal "MC-SALE", Property.for_sale.first.reference
  end

  test "title_for skips empty string and falls back to French" do
    property = Property.new(
      reference: "MC-T1", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco",
      title: { "fr" => "Studio Monaco", "it" => "" }
    )
    assert_equal "Studio Monaco", property.title_for(:it)
  end

  test "slug_for transliterates with the target locale's rules regardless of current locale" do
    property = Property.new(
      reference: "MC-T3", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco",
      title: { "fr" => "Joli studio en étage élevé", "da" => "Dejlig studio i høj etage" }
    )
    I18n.with_locale(:fr) do
      assert_equal "dejlig-studio-i-hoej-etage", property.slug_for(:da)
    end
    I18n.with_locale(:da) do
      assert_equal "dejlig-studio-i-hoej-etage", property.slug_for(:da)
      assert_equal "joli-studio-en-etage-eleve", property.slug_for(:fr)
    end
  end

  test "slug_for romanizes Cyrillic titles with Russian transliteration rules" do
    property = Property.new(
      reference: "MC-T4", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco",
      title: { "fr" => "Joli studio", "ru" => "Красивая студия" }
    )
    I18n.with_locale(:fr) do
      assert_equal "krasivaya-studiya", property.slug_for(:ru)
    end
  end

  test "description_for skips empty string and falls back to French" do
    property = Property.new(
      reference: "MC-T2", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco",
      title: { "fr" => "Studio" },
      description: { "fr" => "Beau studio", "it" => "" }
    )
    assert_equal "Beau studio", property.description_for(:it)
  end

  test "intro is stored as JSON" do
    property = Property.create!(
      reference: "MC-I1",
      title: { "fr" => "Studio" },
      intro: { "fr" => "Vue mer", "en" => "Sea view" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    )
    property.reload
    assert_equal "Vue mer", property.intro["fr"]
  end

  test "intro_for skips empty string and falls back to French" do
    property = Property.new(
      reference: "MC-I2", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco",
      title: { "fr" => "Studio" },
      intro: { "fr" => "Vue mer", "it" => "" }
    )
    assert_equal "Vue mer", property.intro_for(:it)
  end

  test "location_label returns building name and district name" do
    property = Property.new(
      reference: "MC-LOC1", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", building: @building, district: @district
    )
    assert_equal "Le Montaigne, Monte-Carlo", property.location_label
  end

  test "location_label returns district name when no building" do
    property = Property.new(
      reference: "MC-LOC2", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", district: @district
    )
    assert_equal "Monte-Carlo", property.location_label
  end

  test "location_label returns building name when no district" do
    building_no_district = Building.create!(name: "Le Panorama", city: "Monaco")
    property = Property.new(
      reference: "MC-LOC3", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", building: building_no_district
    )
    assert_equal "Le Panorama", property.location_label
  end

  test "location_label returns city when no building and no district" do
    property = Property.new(
      reference: "MC-LOC4", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco"
    )
    assert_equal "Monaco", property.location_label
  end

  test "brochure_filename with rooms district and building" do
    property = Property.new(
      reference: "MC-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", num_rooms: 2,
      district: @district, building: @building
    )
    assert_equal "2p-monte-carlo-le-montaigne.pdf", property.brochure_filename
  end

  test "brochure_filename without building" do
    property = Property.new(
      reference: "MC-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", num_rooms: 3,
      district: @district
    )
    assert_equal "3p-monte-carlo.pdf", property.brochure_filename
  end

  test "brochure_filename without district or building falls back to reference" do
    property = Property.new(
      reference: "MC-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", num_rooms: 2
    )
    assert_equal "2p-MC-001.pdf", property.brochure_filename
  end

  test "brochure_filename without rooms" do
    property = Property.new(
      reference: "MC-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco",
      district: @district, building: @building
    )
    assert_equal "monte-carlo-le-montaigne.pdf", property.brochure_filename
  end

  test "brochure_filename parameterizes names" do
    district = District.create!(name: "La Condamine", city: "Monaco")
    building = Building.create!(name: "Résidence Stella", city: "Monaco", district: district)
    property = Property.new(
      reference: "MC-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", num_rooms: 2,
      district: district, building: building
    )
    assert_equal "2p-la-condamine-residence-stella.pdf", property.brochure_filename
  end

  test "scope for_rental returns rental properties" do
    Property.create!(reference: "MC-SALE", transaction_type: "sale", property_type: "apartment", country: "MC", city: "Monaco")
    Property.create!(reference: "MC-RENT", transaction_type: "rental", property_type: "apartment", country: "MC", city: "Monaco")
    assert_equal 1, Property.for_rental.count
    assert_equal "MC-RENT", Property.for_rental.first.reference
  end

  test "translated_at_for reads timestamp from translations_status" do
    timestamp = "2026-04-21T12:00:00Z"
    property = Property.create!(
      reference: "MC-TX-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco",
      translations_status: { "de" => { "translated_at" => timestamp } }
    )
    assert_equal Time.iso8601(timestamp), property.translated_at_for(:de)
  end

  test "translated_at_for returns nil when locale not present" do
    property = Property.create!(
      reference: "MC-TX-002", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco",
      translations_status: {}
    )
    assert_nil property.translated_at_for(:de)
  end

  test "TARGET_LOCALES matches the translator's locales" do
    assert_equal PropertyTranslator::LOCALES, Property::TARGET_LOCALES
  end

  test "translated_locale? reflects actual title content, not status stamps" do
    property = Property.create!(
      reference: "MC-TX-003", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco",
      title: { "fr" => "Studio", "en" => "Studio", "it" => "Monolocale" },
      translations_status: { "de" => { "translated_at" => "2026-04-21T12:00:00Z" } }
    )
    assert property.translated_locale?(:en)
    assert property.translated_locale?("it")
    refute property.translated_locale?(:de), "a status stamp without content must not count"
    refute property.translated_locale?(:sv)
  end

  test "translated_locale? treats blank strings as untranslated" do
    property = Property.create!(
      reference: "MC-TX-004", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco",
      title: { "fr" => "Studio", "en" => "  " }
    )
    refute property.translated_locale?(:en)
  end

  test "translated_locale? requires every field with FR content, not just the title" do
    property = Property.create!(
      reference: "MC-TX-005", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco",
      title: { "fr" => "Studio", "en" => "Studio", "it" => "Monolocale" },
      intro: { "fr" => "Belle situation", "en" => "Great location" },
      description: { "fr" => "Grande description", "en" => "Long description" }
    )
    assert property.translated_locale?(:en)
    refute property.translated_locale?(:it), "IT title alone must not count when FR has intro and description"
  end

  test "translated_locale? ignores intro and description when FR has none" do
    property = Property.create!(
      reference: "MC-TX-006", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco",
      title: { "fr" => "Parking", "en" => "Parking" },
      intro: {},
      description: { "fr" => "" }
    )
    assert property.translated_locale?(:en)
  end
end

class PropertyEnqueuePostSaveJobsTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @property = Property.create!(
      reference: "MC-PSJ-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco",
      title: { "fr" => "Titre" }, description: { "fr" => "Description" }
    )
    @property.update_columns(translation_source_hash: "seeded-hash")
    clear_enqueued_jobs
  end

  test "enqueues translation job when FR text just changed" do
    @property.update!(title: { "fr" => "Nouveau titre" })
    assert_enqueued_with(job: PropertyTranslationJob, args: [ @property.id ]) do
      @property.enqueue_post_save_jobs!
    end
  end

  test "enqueues brochure job when only non-text trigger columns just changed" do
    @property.update!(price: 2_000_000)
    @property.enqueue_post_save_jobs!
    brochure_jobs = enqueued_jobs.select { |j| j[:job] == PropertyBrochureGenerationJob }
    translation_jobs = enqueued_jobs.select { |j| j[:job] == PropertyTranslationJob }
    assert_empty translation_jobs
    refute_empty brochure_jobs
  end

  test "no jobs when nothing trigger-worthy changed" do
    @property.update!(subtype: "penthouse")
    @property.enqueue_post_save_jobs!
    assert_empty enqueued_jobs
  end

  test "touch does not enqueue jobs via any callback (regression guard)" do
    # Touch-only writes (e.g. belongs_to :touch, sitemap lastmod bumps) must
    # not fan out into LLM calls or brochure regen. Callers enqueue jobs
    # explicitly via enqueue_post_save_jobs! instead of via after_commit.
    assert_no_enqueued_jobs do
      @property.touch
    end
  end

  test "enqueues translation when hash is nil even if FR text did not just change" do
    @property.update_columns(translation_source_hash: nil)
    @property.update!(price: 2_000_000)
    @property.enqueue_post_save_jobs!
    translation_jobs = enqueued_jobs.select { |j| j[:job] == PropertyTranslationJob }
    refute_empty translation_jobs,
                 "properties with no source hash should always retranslate on save"
  end

  test "keeps retrying a failed translation until it succeeds" do
    # A translation-failed property must keep trying: the causes are usually
    # transient or operator-fixable (expired key, quota, outage), and a property
    # stuck untranslated is worse than the retry cost. The recorded failure is a
    # visibility marker, not a stop sign.
    @property.update_columns(
      translation_source_hash: nil,
      translations_status: { "_error" => { "class" => "RubyLLM::UnauthorizedError",
                                           "message" => "bad key",
                                           "failed_at" => Time.current.iso8601 } }
    )
    @property.update!(price: 2_000_000)

    assert_enqueued_with(job: PropertyTranslationJob, args: [ @property.id ]) do
      @property.enqueue_post_save_jobs!
    end
  end

  test "a failed translation suppresses the brochure branch" do
    # An untranslated property must not get brochures: 8 of the 9 locales would
    # render from missing translations. The :translation branch already takes
    # precedence over :brochure, so a retrying property never reaches it.
    @property.update_columns(
      translation_source_hash: nil,
      translations_status: { "_error" => { "class" => "RubyLLM::UnauthorizedError",
                                           "message" => "bad key",
                                           "failed_at" => Time.current.iso8601 } }
    )
    @property.update!(price: 2_000_000)

    assert_equal :translation, @property.enqueue_post_save_jobs!(defer_brochure: true),
                 "a failed property must take the translation branch, not the brochure one"
    brochure_jobs = enqueued_jobs.select { |j| j[:job] == PropertyBrochureGenerationJob }
    assert_empty brochure_jobs, "no brochures while the property is untranslated"
  end

  test "translation_failed scope finds failed properties in SQL, old hash or not" do
    # A re-translation that fails after a text change keeps the OLD non-nil
    # hash (only success updates it), so the scope must filter on the recorded
    # "_error" itself, not on a nil hash. And it must be SQL: loading the whole
    # table (four multi-locale JSON columns per row) to find the usual handful
    # of failures does not belong in a scope operators run casually.
    failed_no_hash = @property
    failed_no_hash.update_columns(
      translation_source_hash: nil,
      translations_status: { "_error" => { "class" => "RubyLLM::UnauthorizedError",
                                           "message" => "bad key",
                                           "failed_at" => Time.current.iso8601 } }
    )
    failed_old_hash = Property.create!(
      reference: "MC-TF-OLD", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", title: { "fr" => "Titre" }
    )
    failed_old_hash.update_columns(
      translation_source_hash: "stale-but-present",
      translations_status: { "_error" => { "class" => "RubyLLM::ServerError",
                                           "message" => "boom",
                                           "failed_at" => Time.current.iso8601 } }
    )
    healthy = Property.create!(
      reference: "MC-TF-OK", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", title: { "fr" => "Titre" }
    )
    healthy.update_columns(translation_source_hash: "good-hash")

    found = Property.translation_failed
    assert_includes found, failed_no_hash
    assert_includes found, failed_old_hash,
                    "a failed re-translation still carrying its old hash must be found"
    refute_includes found, healthy
  end

  test "clear_translation_failure! drops the marker and forces the next run to translate" do
    @property.update_columns(
      translation_source_hash: "stale-hash",
      translations_status: { "en" => { "translated_at" => Time.current.iso8601 },
                             "_error" => { "class" => "RubyLLM::UnauthorizedError",
                                           "message" => "bad key",
                                           "failed_at" => Time.current.iso8601 } }
    )

    assert_no_enqueued_jobs do
      @property.clear_translation_failure!
    end

    @property.reload
    assert_nil @property.translation_error, "the recorded failure must be gone"
    assert_nil @property.translation_source_hash,
               "the hash must be nilled so the next job translates instead of no-opping"
    assert @property.translations_status["en"].present?,
           "per-locale status entries must survive the clear"
  end

  test "retries a failed translation when the FR text actually changed" do
    # New source text is a genuine reason to try again: it may well succeed
    # where the previous text failed (e.g. ContextLengthExceededError).
    @property.update_columns(
      translation_source_hash: nil,
      translations_status: { "_error" => { "class" => "RubyLLM::ContextLengthExceededError",
                                           "message" => "too long",
                                           "failed_at" => Time.current.iso8601 } }
    )
    @property.update!(title: { "fr" => "Titre retravaillé" })

    assert_enqueued_with(job: PropertyTranslationJob, args: [ @property.id ]) do
      @property.enqueue_post_save_jobs!
    end
  end
end
