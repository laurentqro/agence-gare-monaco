require "test_helper"

class ImmotoolboxSyncTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @base_url = "https://clientapi.immotoolbox.com/api"

    # Stub all API endpoints with realistic data matching the actual API format
    stub_districts
    stub_buildings
    stub_properties
  end

  # --- Sync Districts ---

  test "sync creates new districts from API data" do
    assert_difference "District.count", 2 do
      ImmotoolboxSync.new(api_token: "test-token").sync_districts
    end

    district = District.find_by(immotoolbox_id: 1)
    assert_equal "Monte-Carlo", district.name
    assert_equal "Monaco", district.city
    assert_in_delta 43.7384, district.latitude.to_f, 0.0001
    assert_in_delta 7.4246, district.longitude.to_f, 0.0001
    assert_equal "monte-carlo", district.slug
  end

  test "sync updates existing districts" do
    District.create!(name: "Old Name", city: "Monaco", immotoolbox_id: 1)
    District.create!(name: "Fontvieille", city: "Monaco", immotoolbox_id: 2)

    assert_no_difference "District.count" do
      ImmotoolboxSync.new(api_token: "test-token").sync_districts
    end

    district = District.find_by(immotoolbox_id: 1)
    assert_equal "Monte-Carlo", district.name
  end

  test "sync does not delete districts not in API response" do
    District.create!(name: "Manual District", city: "Monaco")

    ImmotoolboxSync.new(api_token: "test-token").sync_districts

    assert District.find_by(name: "Manual District").present?
  end

  # --- Sync Buildings ---

  test "sync creates new buildings from API data" do
    District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 1)

    assert_difference "Building.count", 1 do
      ImmotoolboxSync.new(api_token: "test-token").sync_buildings
    end

    building = Building.find_by(immotoolbox_id: 10)
    assert_equal "Le Millefiori", building.name
    assert_equal "Le Millefiori", building.name_alt
    assert_equal "1 Rue du Ténao", building.address
    assert_equal "Monaco", building.city
    assert_equal 1, building.district.immotoolbox_id
  end

  test "sync updates existing buildings" do
    District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 1)
    Building.create!(name: "Old Name", city: "Monaco", immotoolbox_id: 10)

    assert_no_difference "Building.count" do
      ImmotoolboxSync.new(api_token: "test-token").sync_buildings
    end

    building = Building.find_by(immotoolbox_id: 10)
    assert_equal "Le Millefiori", building.name
  end

  test "sync links building to district by immotoolbox_id" do
    district = District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 1)

    ImmotoolboxSync.new(api_token: "test-token").sync_buildings

    building = Building.find_by(immotoolbox_id: 10)
    assert_equal district, building.district
  end

  # --- Sync Properties ---

  test "sync creates new properties from API data" do
    setup_districts_and_buildings

    assert_difference "Property.count", 1 do
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    end

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal "AG-001", property.reference
    assert_equal 1_500_000, property.price
    assert_equal "EUR", property.currency
    assert_equal "sale", property.transaction_type
    assert_equal "apartment", property.property_type
    assert_equal "MC", property.country
    assert_equal "Monaco", property.city
    assert_equal 3, property.num_rooms
    assert_equal 2, property.num_bedrooms
    assert_equal 1, property.num_bathrooms
    assert_in_delta 75.5, property.living_area.to_f, 0.01
    assert_equal true, property.published
    assert property.synced_at.present?
  end

  test "sync stores French title and description only; discards English from API" do
    setup_districts_and_buildings

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal "Studio Monte-Carlo", property.title["fr"]
    assert_equal "Magnifique studio", property.description["fr"]
    refute property.title.key?("en"), "EN title from API should be discarded"
    refute property.description.key?("en"), "EN description from API should be discarded"
  end

  test "sync stores French intro only; discards English from API" do
    setup_districts_and_buildings

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal "Vue mer panoramique", property.intro["fr"]
    refute property.intro.key?("en"), "EN intro from API should be discarded"
  end

  test "sync strips HTML tags from French description but keeps paragraph breaks" do
    setup_districts_and_buildings

    WebMock.reset!
    html_property = property_data(
      "texts" => {
        "fr" => { "id" => 300, "title" => "Studio Monte-Carlo", "description" => "<p>Magnifique studio</p><p>au coeur de Monaco</p>", "languageCode" => "FR" }
      }
    )
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [ html_property ].to_json,
        headers: { "Content-Type" => "application/json" }
      )
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "2" })
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    refute_includes property.description["fr"], "<p>"
    assert_includes property.description["fr"], "Magnifique studio"
    assert_includes property.description["fr"], "au coeur de Monaco"
    # The two paragraphs must remain on separate lines, not be squished together.
    refute_includes property.description["fr"], "Magnifique studio au coeur"
    assert_match(/Magnifique studio\nau coeur de Monaco/, property.description["fr"])
  end

  test "sync preserves <br> line breaks and bullet lists in French description" do
    setup_districts_and_buildings

    WebMock.reset!
    api_html = "<p>Intro paragraph.<br />\r\nDeuxi&egrave;me ligne.<br />\r\n" \
               "L&#39;appartement se compose de&nbsp;:<br />\r\n" \
               "- Un hall d&#39;entr&eacute;e,<br />\r\n- Une cuisine &eacute;quip&eacute;e</p>"
    html_property = property_data(
      "texts" => {
        "fr" => { "id" => 300, "title" => "Studio Monte-Carlo", "description" => api_html, "languageCode" => "FR" }
      }
    )
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(status: 200, body: [ html_property ].to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "2" })
      .to_return(status: 200, body: [].to_json, headers: { "Content-Type" => "application/json" })

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    desc = Property.find_by(immotoolbox_id: 100).description["fr"]
    refute_includes desc, "<br"
    refute_includes desc, "&nbsp;"
    refute_includes desc, "&#39;"
    refute_includes desc, "&eacute;"
    assert_includes desc, "deuxième ligne".sub("deuxième", "Deuxième")
    # Each <br> becomes a newline; the bullet lines stay on their own lines.
    assert_match(/Intro paragraph\.\nDeuxième ligne\./, desc)
    assert_match(/- Un hall d'entrée,\n- Une cuisine équipée/, desc)
    # No run of 3+ newlines.
    refute_match(/\n{3,}/, desc)
  end

  test "sync strips HTML entities from French title and description" do
    setup_districts_and_buildings

    WebMock.reset!
    html_property = property_data(
      "texts" => {
        "fr" => { "id" => 300, "title" => "Studio&nbsp;Monte-Carlo", "description" => "Situé&nbsp;au c&oelig;ur de <b>Monaco</b>,&nbsp;proche du port", "languageCode" => "FR" }
      }
    )
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [ html_property ].to_json,
        headers: { "Content-Type" => "application/json" }
      )
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "2" })
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal "Studio Monte-Carlo", property.title["fr"]
    refute_includes property.description["fr"], "&nbsp;"
    refute_includes property.description["fr"], "<b>"
    assert_includes property.description["fr"], "Situé au"
    assert_includes property.description["fr"], "proche du port"
  end

  test "sync creates property images from inline images" do
    setup_districts_and_buildings

    assert_difference "PropertyImage.count", 2 do
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    end

    property = Property.find_by(immotoolbox_id: 100)
    photo = property.property_images.find_by(immotoolbox_id: 200)
    assert_equal "https://cdn.example.com/large/img1.jpg", photo.remote_url
    assert_equal "https://cdn.example.com/thumb/img1.jpg", photo.thumb_url
    assert_equal "https://cdn.example.com/small/img1.jpg", photo.small_url
    assert_equal "https://cdn.example.com/medium/img1.jpg", photo.medium_url
    assert_equal "https://cdn.example.com/large/img1.jpg", photo.large_url
    assert_equal 1, photo.position
    assert_equal false, photo.is_plan

    plan = property.property_images.find_by(immotoolbox_id: 201)
    assert_equal true, plan.is_plan
  end

  test "sync enqueues exactly one brochure job per property despite multiple images" do
    setup_districts_and_buildings
    # Seed an existing property whose FR text matches the API (so no translation
    # job) but whose metadata changes, forcing the direct-brochure path. This
    # isolates the per-image dedup: the property has multiple images in the API
    # response, but only one brochure job should result.
    prop = Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", price: 999_999, immotoolbox_id: 100,
      num_rooms: 1,
      title: { "fr" => "Studio Monte-Carlo" },
      intro: { "fr" => "Vue mer panoramique" },
      description: { "fr" => "Magnifique studio" }
    )
    prop.update_columns(translation_source_hash: "seeded-hash")
    clear_enqueued_jobs

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    prop.reload
    assert_operator prop.property_images.count, :>, 1,
                    "fixture should have multiple images to make the dedup meaningful"

    brochure_jobs = enqueued_jobs.select do |j|
      j[:job] == PropertyBrochureGenerationJob && j[:args] == [ prop.id ]
    end
    assert_equal 1, brochure_jobs.size,
                 "expected a single brochure job for the property, not one per image"
  end

  test "sync does not enqueue a brochure job when nothing about the property changed" do
    setup_districts_and_buildings
    # First sync establishes the property exactly as the API describes it. The
    # second sync sees identical data, so it must enqueue no brochure job at all:
    # regenerating 18 PDFs per property per run is what makes a frequent sync
    # schedule (every 5 minutes) untenable.
    ImmotoolboxSync.new(api_token: "test-token").sync_properties
    prop = Property.find_by(immotoolbox_id: 100)
    # The first sync leaves translation pending; simulate the translation job
    # having completed so the second sync takes neither the :translation branch
    # nor a text-changed branch. The brochure cache must be complete, or the
    # sync would (rightly) enqueue a job to fill it in.
    prop.update_columns(translation_source_hash: "seeded-hash")
    attach_complete_brochure_cache(prop)
    clear_enqueued_jobs

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    brochure_jobs = enqueued_jobs.select do |j|
      j[:job] == PropertyBrochureGenerationJob && j[:args] == [ prop.id ]
    end
    assert_empty brochure_jobs,
                 "an unchanged property must not regenerate its brochures on every sync"
  end

  test "sync re-enqueues brochures for a translated property whose cache is empty" do
    setup_districts_and_buildings
    # The brochure job purges before attaching 18 PDFs one by one, and declares
    # no retry_on: a worker killed mid-run (deploy restart, OOM) leaves the
    # property with no cache. Nothing about the property changes afterwards, so
    # a purely change-driven gate would never fire again and every download
    # would silently pay full on-demand Typst generation forever. The sync is
    # the natural healer: it visits every property every tick anyway.
    ImmotoolboxSync.new(api_token: "test-token").sync_properties
    prop = Property.find_by(immotoolbox_id: 100)
    prop.update_columns(translation_source_hash: "seeded-hash")
    clear_enqueued_jobs

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    brochure_jobs = enqueued_jobs.select do |j|
      j[:job] == PropertyBrochureGenerationJob && j[:args] == [ prop.id ]
    end
    assert_equal 1, brochure_jobs.size,
                 "a translated property with no cached brochures must be re-enqueued"
  end

  test "sync completes a partial brochure cache" do
    setup_districts_and_buildings
    # A share flow can attach a single on-demand variant, and a killed job can
    # leave any count between 1 and 17. brochures.attached? alone would treat
    # those as healthy; only the full 18-variant set counts as complete.
    ImmotoolboxSync.new(api_token: "test-token").sync_properties
    prop = Property.find_by(immotoolbox_id: 100)
    prop.update_columns(translation_source_hash: "seeded-hash")
    prop.brochures.attach(
      io: StringIO.new("%PDF-1.4 fake"), filename: "b-fr.pdf",
      content_type: "application/pdf", metadata: { locale: "fr", include_logo: true }
    )
    clear_enqueued_jobs

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    brochure_jobs = enqueued_jobs.select do |j|
      j[:job] == PropertyBrochureGenerationJob && j[:args] == [ prop.id ]
    end
    assert_equal 1, brochure_jobs.size,
                 "a partial brochure cache must be completed, not treated as healthy"
  end

  test "sync does not re-enqueue brochures for an untranslated property with no cache" do
    setup_districts_and_buildings
    # An untranslated property takes the :translation branch, and the brochure
    # job would decline it anyway. The self-heal check must not turn that into
    # 288 no-op brochure enqueues a day.
    ImmotoolboxSync.new(api_token: "test-token").sync_properties
    prop = Property.find_by(immotoolbox_id: 100)
    assert_nil prop.translation_source_hash, "precondition: property is untranslated"
    clear_enqueued_jobs

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    brochure_jobs = enqueued_jobs.select do |j|
      j[:job] == PropertyBrochureGenerationJob && j[:args] == [ prop.id ]
    end
    assert_empty brochure_jobs,
                 "an untranslated property gets its brochures after translation, not from the self-heal"
  end

  test "an image shared between properties does not report a change on every sync" do
    setup_districts_and_buildings
    # A building image shared across properties gets one row per property, each
    # carrying that property's own position and is_plan. If the sharers instead
    # fought over a single row, the image would look changed forever and
    # regenerate 18 PDFs per property per tick.
    a = Property.create!(
      reference: "SH-A", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 9001
    )
    b = Property.create!(
      reference: "SH-B", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 9002
    )
    # The two properties list the same image at DIFFERENT positions, which is the
    # realistic case: `order` is per-property, as is `isPlan`. Each property's own
    # row holds its own values, so neither owner disturbs the other.
    base = {
      "id" => 77_001,
      "large" => "https://cdn.example.com/large/shared.jpg",
      "thumb" => "https://cdn.example.com/thumb/shared.jpg"
    }
    for_a = base.merge("order" => 1, "isPlan" => false)
    for_b = base.merge("order" => 5, "isPlan" => true)
    sync = ImmotoolboxSync.new(api_token: "test-token")
    sync_images = sync.method(:sync_property_images)

    assert sync_images.call(a, [ for_a ]), "first sync creates the image, so it changed"
    sync_images.call(b, [ for_b ])

    refute sync_images.call(a, [ for_a ]),
           "a shared image must not report a change just because another property owns it"
    refute sync_images.call(b, [ for_b ]),
           "ownership must not ping-pong between properties sharing an image"
    refute sync_images.call(a, [ for_a ]),
           "steady state must stay quiet across repeated ticks"
  end

  test "an image shared between two properties appears in both galleries" do
    setup_districts_and_buildings
    # A building shot listed by two properties must end up in BOTH galleries.
    # A single globally-unique row can only belong to one property at a time, so
    # whichever synced last would steal it and the other would render one photo
    # short (and bake incomplete brochures).
    a = Property.create!(
      reference: "GAL-A", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 9010
    )
    b = Property.create!(
      reference: "GAL-B", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 9011
    )
    shared = {
      "id" => 77_010,
      "large" => "https://cdn.example.com/large/building.jpg",
      "order" => 1
    }
    sync_images = ImmotoolboxSync.new(api_token: "test-token").method(:sync_property_images)

    sync_images.call(a, [ shared ])
    sync_images.call(b, [ shared ])

    assert_equal 1, a.property_images.reload.count, "property A must keep the shared image"
    assert_equal 1, b.property_images.reload.count, "property B must also have the shared image"

    # And it must stay that way across further ticks, not alternate owners.
    sync_images.call(a, [ shared ])
    sync_images.call(b, [ shared ])
    assert_equal 1, a.property_images.reload.count, "A must not lose the image to B on later ticks"
    assert_equal 1, b.property_images.reload.count, "B must not lose the image to A on later ticks"
  end

  test "reordering a property's photos reports a change so brochures regenerate" do
    setup_districts_and_buildings
    # The PDF generator orders photos by position: a reorder in Immotoolbox is a
    # real visual change (new cover photo, new page order) and the cached
    # brochures must follow it.
    prop = Property.create!(
      reference: "ORD-A", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 9020
    )
    first = { "id" => 77_020, "order" => 1, "large" => "https://cdn.example.com/large/one.jpg" }
    second = { "id" => 77_021, "order" => 2, "large" => "https://cdn.example.com/large/two.jpg" }
    sync_images = ImmotoolboxSync.new(api_token: "test-token").method(:sync_property_images)

    sync_images.call(prop, [ first, second ])
    refute sync_images.call(prop, [ first, second ]), "unchanged order must stay quiet"

    swapped = [ first.merge("order" => 2), second.merge("order" => 1) ]
    assert sync_images.call(prop, swapped),
           "a photo reorder changes the brochure cover and page order and must regenerate"
    assert_equal [ 77_021, 77_020 ],
                 prop.property_images.reload.order(:position).pluck(:immotoolbox_id),
                 "the new order must be persisted"
  end

  test "reclassifying a photo as a floor plan reports a change" do
    setup_districts_and_buildings
    # is_plan decides whether the image renders in the photo section or the plan
    # section of the PDF, so flipping it must regenerate brochures.
    prop = Property.create!(
      reference: "PLN-A", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 9030
    )
    img = { "id" => 77_030, "order" => 1, "isPlan" => false,
            "large" => "https://cdn.example.com/large/plan.jpg" }
    sync_images = ImmotoolboxSync.new(api_token: "test-token").method(:sync_property_images)

    sync_images.call(prop, [ img ])
    refute sync_images.call(prop, [ img ]), "unchanged classification must stay quiet"

    assert sync_images.call(prop, [ img.merge("isPlan" => true) ]),
           "moving an image between photo and plan sections must regenerate brochures"
  end

  test "an unchanged property keeps its updated_at so sitemap lastmod stays honest" do
    setup_districts_and_buildings
    # synced_at is written on every run, and the sitemap publishes updated_at as
    # <lastmod>. At a 5-minute cadence an unchanged property would otherwise claim
    # ~288 modifications a day, which is both a bad crawl signal and pointless
    # write amplification on SQLite.
    ImmotoolboxSync.new(api_token: "test-token").sync_properties
    prop = Property.find_by(immotoolbox_id: 100)
    prop.update_columns(translation_source_hash: "seeded-hash", updated_at: 3.days.ago)
    before = prop.reload.updated_at

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    assert_equal before.to_i, prop.reload.updated_at.to_i,
                 "a no-op sync must not bump updated_at"
    assert prop.synced_at > before, "synced_at should still record that the sync ran"
  end

  test "a no-op sync writes synced_at as one batched statement, not one per property" do
    setup_districts_and_buildings
    # In steady state every property takes the unchanged branch every 5 minutes.
    # Per-property single-row updates would mean ~288 x N write transactions a
    # day competing for SQLite's single writer; one update_all per run carries
    # the same information.
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [ property_data, property_data.merge("id" => 101, "reference" => "AG-002") ].to_json,
        headers: { "Content-Type" => "application/json" }
      )
    ImmotoolboxSync.new(api_token: "test-token").sync_properties
    Property.where(immotoolbox_id: [ 100, 101 ]).find_each do |prop|
      prop.update_columns(translation_source_hash: "seeded-hash")
      attach_complete_brochure_cache(prop)
    end
    before = 2.hours.ago
    Property.where(immotoolbox_id: [ 100, 101 ]).update_all(synced_at: before)

    synced_at_updates = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      sql = payload[:sql].to_s
      synced_at_updates << sql if sql.match?(/UPDATE "properties"/i) && sql.include?("synced_at")
    end
    begin
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    ensure
      ActiveSupport::Notifications.unsubscribe(subscriber)
    end

    assert_equal 1, synced_at_updates.size,
                 "unchanged properties must share one batched synced_at write per run"
    Property.where(immotoolbox_id: [ 100, 101 ]).find_each do |prop|
      assert_operator prop.synced_at, :>, before, "every unchanged property must still get synced_at"
    end
  end

  test "a real change still bumps updated_at" do
    setup_districts_and_buildings
    # The lastmod guard must not blind the sitemap to genuine edits.
    ImmotoolboxSync.new(api_token: "test-token").sync_properties
    prop = Property.find_by(immotoolbox_id: 100)
    prop.update_columns(translation_source_hash: "seeded-hash", updated_at: 3.days.ago, price: 1)
    before = prop.reload.updated_at

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    assert_operator prop.reload.updated_at, :>, before,
                    "a genuine price change must move updated_at for the sitemap"
  end

  test "a genuine change to a shared image's own content still reports a change" do
    setup_districts_and_buildings
    # The change gate must see real edits: if the CDN URL changes, brochures
    # genuinely need regenerating.
    prop = Property.create!(
      reference: "SH-C", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 9003
    )
    img = { "id" => 77_002, "order" => 1, "large" => "https://cdn.example.com/large/v1.jpg" }
    sync_images = ImmotoolboxSync.new(api_token: "test-token").method(:sync_property_images)

    sync_images.call(prop, [ img ])
    refute sync_images.call(prop, [ img ]), "unchanged image must stay quiet"

    assert sync_images.call(prop, [ img.merge("large" => "https://cdn.example.com/large/v2.jpg") ]),
           "a new remote URL is a real change and must regenerate brochures"
  end

  test "brochure job is enqueued only after images are synced (no stale image set)" do
    setup_districts_and_buildings
    # Same direct-brochure setup as above: metadata changes but FR text does not,
    # so enqueue_post_save_jobs! takes the :brochure path. The brochure job MUST
    # be enqueued after sync_property_images so an async worker can't regenerate
    # with the old image set.
    prop = Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", price: 999_999, immotoolbox_id: 100,
      num_rooms: 1,
      title: { "fr" => "Studio Monte-Carlo" },
      intro: { "fr" => "Vue mer panoramique" },
      description: { "fr" => "Magnifique studio" }
    )
    prop.update_columns(translation_source_hash: "seeded-hash")
    # Pre-seed a stale image that the API response does NOT include, so it should
    # be gone by the time the brochure job is enqueued.
    prop.property_images.create!(immotoolbox_id: 999_999, remote_url: "https://old.example.com/stale.jpg", position: 99)
    clear_enqueued_jobs

    images_at_enqueue = nil
    stale_present_at_enqueue = nil
    target_id = prop.id
    original = PropertyBrochureGenerationJob.method(:perform_later)
    PropertyBrochureGenerationJob.define_singleton_method(:perform_later) do |property_id|
      if property_id == target_id
        images_at_enqueue = Property.find(target_id).property_images.count
        stale_present_at_enqueue = PropertyImage.exists?(immotoolbox_id: 999_999, property_id: target_id)
      end
      original.call(property_id)
    end
    begin
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    ensure
      PropertyBrochureGenerationJob.singleton_class.send(:remove_method, :perform_later)
    end

    refute_nil images_at_enqueue, "brochure job should have been enqueued for the property"
    assert_equal prop.property_images.reload.count, images_at_enqueue,
                 "image set must be fully synced before the brochure job is enqueued"
    assert_equal false, stale_present_at_enqueue,
                 "stale image must be removed before the brochure job is enqueued"
  end

  test "sync updates existing properties" do
    setup_districts_and_buildings
    Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", price: 1_000_000, immotoolbox_id: 100
    )

    assert_no_difference "Property.count" do
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    end

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal 1_500_000, property.price
  end

  test "sync enqueues PropertyTranslationJob when FR content changes" do
    setup_districts_and_buildings
    Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", price: 999_999, immotoolbox_id: 100,
      title: { "fr" => "Old title" }, description: { "fr" => "Old description" }
    )

    assert_enqueued_with(job: PropertyTranslationJob) do
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    end
  end

  test "sync enqueues brochure job directly when only non-text trigger columns change" do
    setup_districts_and_buildings
    # Seed property with FR text matching what the API returns and a non-nil
    # translation_source_hash, so only price and other metadata change on sync.
    prop = Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", price: 999_999, immotoolbox_id: 100,
      num_rooms: 1,
      title: { "fr" => "Studio Monte-Carlo" },
      intro: { "fr" => "Vue mer panoramique" },
      description: { "fr" => "Magnifique studio" }
    )
    prop.update_columns(translation_source_hash: "seeded-hash")
    clear_enqueued_jobs

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    translation_jobs = enqueued_jobs.select { |j| j[:job] == PropertyTranslationJob }
    brochure_jobs = enqueued_jobs.select { |j| j[:job] == PropertyBrochureGenerationJob }
    assert_empty translation_jobs, "Should not enqueue translation job when FR text is unchanged"
    refute_empty brochure_jobs, "Should enqueue brochure job when price/rooms change"
  end

  test "sync unpublishes properties not in API response" do
    setup_districts_and_buildings
    stale = Property.create!(
      reference: "AG-OLD", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", published: true, immotoolbox_id: 999
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    stale.reload
    assert_equal false, stale.published
  end

  test "sync does not unpublish non-synced properties" do
    setup_districts_and_buildings
    manual = Property.create!(
      reference: "MANUAL-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", published: true, immotoolbox_id: nil
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    manual.reload
    assert_equal true, manual.published
  end

  test "sync links property to district and building" do
    district = District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 1)
    building = Building.create!(name: "Le Millefiori", city: "Monaco", immotoolbox_id: 10, district: district)

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal district, property.district
    assert_equal building, property.building
  end

  test "sync sets property media URLs" do
    setup_districts_and_buildings

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_equal "https://youtube.com/watch?v=abc123", property.video_url
    assert_equal "https://my.matterport.com/show?m=xyz", property.virtual_tour_url
  end

  test "sync updates existing images by immotoolbox_id" do
    setup_districts_and_buildings
    property = Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 100
    )
    existing_image = PropertyImage.create!(
      property: property, remote_url: "https://old.url/img.jpg",
      immotoolbox_id: 200, position: 99
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    existing_image.reload
    assert_equal "https://cdn.example.com/large/img1.jpg", existing_image.remote_url
    assert_equal 1, existing_image.position
  end

  test "sync removes images no longer in API response" do
    setup_districts_and_buildings
    property = Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 100
    )
    orphan = PropertyImage.create!(
      property: property, remote_url: "https://old.url/orphan.jpg",
      immotoolbox_id: 999
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    assert_nil PropertyImage.find_by(id: orphan.id)
  end

  test "sync handles non-numeric num_rooms gracefully" do
    setup_districts_and_buildings

    # Override properties stub with non-numeric num_rooms
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [ property_data(num_rooms: "Non défini/Aucun", num_bedrooms: "", num_bathrooms: "") ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property = Property.find_by(immotoolbox_id: 100)
    assert_nil property.num_rooms
    assert_nil property.num_bedrooms
    assert_nil property.num_bathrooms
  end

  test "sync updates FR and preserves all other locales (which will be refreshed by translation job)" do
    setup_districts_and_buildings
    property = Property.create!(
      reference: "AG-001", transaction_type: "sale", property_type: "apartment",
      country: "MC", city: "Monaco", immotoolbox_id: 100,
      title: { "fr" => "Old FR", "en" => "Stale EN", "it" => "Titolo italiano", "de" => "Deutscher Titel" },
      description: { "fr" => "Old FR desc", "en" => "Stale EN desc", "it" => "Descrizione", "de" => "Beschreibung" }
    )

    ImmotoolboxSync.new(api_token: "test-token").sync_properties

    property.reload
    assert_equal "Studio Monte-Carlo", property.title["fr"]
    assert_equal "Magnifique studio", property.description["fr"]
    # All non-FR locales are preserved at the DB layer; the translation job
    # will overwrite them on the next run (stale EN stays until the async job runs).
    assert_equal "Stale EN", property.title["en"]
    assert_equal "Titolo italiano", property.title["it"]
    assert_equal "Deutscher Titel", property.title["de"]
    assert_equal "Descrizione", property.description["it"]
  end

  test "sync handles shared images across properties" do
    setup_districts_and_buildings

    # Two properties sharing the same image (e.g. building image)
    shared_image_id = 200
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [
          property_data,
          property_data.merge(
            "id" => 101, "reference" => "AG-002",
            "images" => [
              { "id" => shared_image_id, "order" => 1, "thumb" => "https://cdn.example.com/thumb/img1.jpg",
                "small" => "https://cdn.example.com/small/img1.jpg", "medium" => "https://cdn.example.com/medium/img1.jpg",
                "large" => "https://cdn.example.com/large/img1.jpg", "isPlan" => false }
            ]
          )
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    assert_nothing_raised do
      ImmotoolboxSync.new(api_token: "test-token").sync_properties
    end

    assert_equal 2, Property.count
  end

  # --- Full sync ---

  test "sync_all runs districts, buildings, then properties in order" do
    setup_districts_and_buildings

    result = ImmotoolboxSync.new(api_token: "test-token").sync_all

    assert result[:districts].is_a?(Hash)
    assert result[:buildings].is_a?(Hash)
    assert result[:properties].is_a?(Hash)
    assert_operator District.count, :>=, 2
    assert_operator Building.count, :>=, 1
    assert_operator Property.count, :>=, 1
  end

  test "sync_all returns summary statistics" do
    result = ImmotoolboxSync.new(api_token: "test-token").sync_all

    assert_includes result[:districts].keys, :created
    assert_includes result[:districts].keys, :updated
    assert_includes result[:buildings].keys, :created
    assert_includes result[:buildings].keys, :updated
    assert_includes result[:properties].keys, :created
    assert_includes result[:properties].keys, :updated
    assert_includes result[:properties].keys, :unpublished
  end

  private

  # A "complete" cache is one PDF per locale in both logo variants (18 files),
  # matching what PropertyBrochureGenerationJob produces.
  def attach_complete_brochure_cache(property)
    PropertyBrochureGenerationJob::LOCALES.each do |locale|
      PropertyBrochureGenerationJob::LOGO_VARIANTS.each do |include_logo|
        property.brochures.attach(
          io: StringIO.new("%PDF-1.4 fake"),
          filename: "b-#{locale}#{include_logo ? '' : '-no-logo'}.pdf",
          content_type: "application/pdf",
          metadata: { locale: locale.to_s, include_logo: include_logo }
        )
      end
    end
  end

  def setup_districts_and_buildings
    District.create!(name: "Monte-Carlo", city: "Monaco", immotoolbox_id: 1)
    District.create!(name: "Fontvieille", city: "Monaco", immotoolbox_id: 2)
    Building.create!(name: "Le Millefiori", city: "Monaco", immotoolbox_id: 10,
                     district: District.find_by(immotoolbox_id: 1))
  end

  def stub_districts
    # Real API returns a Hash keyed by ID strings, not an Array
    stub_request(:get, "#{@base_url}/districts")
      .to_return(
        status: 200,
        body: {
          "1" => { "id" => 1, "name" => "Monte-Carlo", "city" => { "id" => 4, "name" => "Monaco", "country" => "/api/countries/1" }, "lat" => "43.7384", "lng" => "7.4246" },
          "2" => { "id" => 2, "name" => "Fontvieille", "city" => { "id" => 4, "name" => "Monaco", "country" => "/api/countries/1" }, "lat" => "43.7272", "lng" => "7.4145" }
        }.to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def stub_buildings
    # Real API returns an Array; city is an object, name_alt uses underscore
    stub_request(:get, "#{@base_url}/buildings")
      .to_return(
        status: 200,
        body: [
          {
            "id" => 10, "name" => "Le Millefiori", "name_alt" => "Le Millefiori",
            "address" => "1 Rue du Ténao",
            "city" => { "id" => 4, "name" => "Monaco", "country" => "/api/countries/1" },
            "district" => { "id" => 1, "name" => "Monte-Carlo" }
          }
        ].to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end

  def property_data(overrides = {})
    {
      "id" => 100,
      "reference" => "AG-001",
      "price" => 1_500_000,
      "currency" => "EUR",
      "servicecharges" => 500,
      "serviceschargesIncluded" => false,
      "type_transaction_code" => "sale",
      "type_property" => "Apartment",
      "type_property_id" => 1,
      "subtype_property" => "Studio",
      "subtype_property_id" => 1,
      "country" => { "id" => 1, "code" => "MC", "name" => "Monaco" },
      "country_code" => "MC",
      "city" => { "id" => 4, "name" => "Monaco" },
      "city_name" => "Monaco",
      "district" => { "id" => 1, "name" => "Monte-Carlo" },
      "building" => "Le Millefiori",
      "building_id" => 10,
      "address" => "1 Rue du Ténao",
      "lat" => "43.7384",
      "lng" => "7.4246",
      "floor" => "5",
      "num_rooms" => overrides.fetch(:num_rooms, "3"),
      "num_bedrooms" => overrides.fetch(:num_bedrooms, "2"),
      "num_bathrooms" => overrides.fetch(:num_bathrooms, "1"),
      "num_parkings" => "1",
      "num_cellars" => "0",
      "living_area" => 75.5,
      "total_area" => 85.0,
      "terrace_area" => 10.0,
      "land_area" => nil,
      "garden_area" => nil,
      "furnished" => false,
      "status" => "published",
      "featured" => true,
      "exclusivity" => false,
      "sharedExclusivity" => false,
      "urlVideo" => "https://youtube.com/watch?v=abc123",
      "urlVirtual" => "https://my.matterport.com/show?m=xyz",
      "texts" => {
        "fr" => { "id" => 300, "title" => "Studio Monte-Carlo", "intro" => "Vue mer panoramique", "description" => "Magnifique studio", "languageCode" => "FR" },
        "en" => { "id" => 301, "title" => "Studio Monte-Carlo EN", "intro" => "Panoramic sea view", "description" => "Beautiful studio", "languageCode" => "EN" }
      },
      "images" => [
        {
          "id" => 200,
          "order" => 1,
          "thumb" => "https://cdn.example.com/thumb/img1.jpg",
          "small" => "https://cdn.example.com/small/img1.jpg",
          "medium" => "https://cdn.example.com/medium/img1.jpg",
          "large" => "https://cdn.example.com/large/img1.jpg",
          "isPlan" => false
        },
        {
          "id" => 201,
          "order" => 2,
          "thumb" => "https://cdn.example.com/thumb/plan1.jpg",
          "small" => "https://cdn.example.com/small/plan1.jpg",
          "medium" => "https://cdn.example.com/medium/plan1.jpg",
          "large" => "https://cdn.example.com/large/plan1.jpg",
          "isPlan" => true
        }
      ]
    }.merge(overrides)
  end

  def stub_properties
    # Page 1: one property with inline texts and images
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "1" })
      .to_return(
        status: 200,
        body: [ property_data ].to_json,
        headers: { "Content-Type" => "application/json" }
      )

    # Page 2: empty (signals end of pagination)
    stub_request(:get, "#{@base_url}/properties")
      .with(query: { "status" => "published", "page" => "2" })
      .to_return(
        status: 200,
        body: [].to_json,
        headers: { "Content-Type" => "application/json" }
      )
  end
end
