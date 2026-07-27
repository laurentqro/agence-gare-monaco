require "test_helper"

class Admin::PropertiesControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    @district = District.create!(name: "Monte-Carlo", city: "Monaco", slug: "monte-carlo")
    @building = Building.create!(name: "Park Palace", city: "Monaco", district: @district)
  end

  # Authentication
  test "redirects unauthenticated users to login" do
    delete session_url
    get admin_properties_url
    assert_redirected_to new_session_url
  end

  # INDEX
  test "GET index lists all properties" do
    create_property(reference: "MC-001", title: { "fr" => "Studio Monte-Carlo" })
    create_property(reference: "MC-002", title: { "fr" => "Appartement Carré d'Or" })
    get admin_properties_url
    assert_response :success
    assert_select "h1", /Biens/
    assert_select "table tbody tr", 2
  end

  test "GET index shows property details" do
    create_property(
      reference: "MC-001",
      title: { "fr" => "Studio Monte-Carlo" },
      price: 1_290_000,
      transaction_type: "sale",
      property_type: "studio",
      published: true
    )
    get admin_properties_url
    assert_response :success
    assert_select "td", /MC-001/
    assert_select "td", /Studio Monte-Carlo/
  end

  test "GET index shows published/draft status badges" do
    create_property(reference: "MC-001", published: true)
    create_property(reference: "MC-002", published: false)
    get admin_properties_url
    assert_select "span", /Publié/
    assert_select "span", /Brouillon/
  end

  test "GET index shows share link for each property" do
    prop = create_property(reference: "MC-001")
    get admin_properties_url
    assert_select "a[href='#{new_admin_property_share_path(prop)}']"
  end

  test "GET index shows one chip per target locale, green when translated" do
    property = create_property(
      reference: "MC-001",
      title: { "fr" => "Studio", "en" => "Studio", "it" => "Monolocale" },
      description: { "fr" => "Description", "en" => "Description", "it" => "Descrizione" }
    )
    property.update_columns(translation_source_hash: property.current_fr_hash)
    get admin_properties_url
    assert_select "th", /Traductions/
    assert_select "[data-locale-chip]", Property::TARGET_LOCALES.size
    assert_select "[data-locale-chip='en'][data-locale-status='translated']", text: "EN"
    assert_select "[data-locale-chip='it'][data-locale-status='translated']", text: "IT"
    assert_select "[data-locale-chip='de'][data-locale-status='missing']", text: "DE"
    assert_select "[data-locale-chip='ru'][data-locale-status='missing']", text: "RU"
  end

  test "GET index shows stale chips when the FR text changed since translation" do
    property = create_property(
      reference: "MC-STALE",
      title: { "fr" => "Studio", "en" => "Studio" },
      description: { "fr" => "Description", "en" => "Description" }
    )
    property.update_columns(translation_source_hash: property.current_fr_hash)
    property.update_columns(title: { "fr" => "Studio rénové", "en" => "Studio" })
    get admin_properties_url
    assert_select "[data-locale-chip='en'][data-locale-status='stale']", text: "EN"
    assert_select "[data-locale-chip='de'][data-locale-status='missing']", text: "DE"
  end

  test "GET index attributes chips to their own row" do
    full = Property::TARGET_LOCALES.index_with { "Translated" }.merge("fr" => "Original")
    translated = create_property(
      reference: "MC-ALL", title: full, description: full, created_at: 1.hour.ago
    )
    translated.update_columns(translation_source_hash: translated.current_fr_hash)
    create_property(reference: "MC-NONE", title: { "fr" => "Studio" }, created_at: 2.days.ago)

    get admin_properties_url
    assert_select "tbody tr:first-child [data-locale-chip='en'][data-locale-status='translated']"
    assert_select "tbody tr:last-child [data-locale-chip='en'][data-locale-status='missing']"
  end

  test "GET index shows a translation error marker with the exception class" do
    create_property(
      reference: "MC-ERR",
      translations_status: { "_error" => { "class" => "RubyLLM::RateLimitError", "message" => "quota" } }
    )
    create_property(reference: "MC-OK", title: { "fr" => "Studio" })
    get admin_properties_url
    assert_select "[data-translation-error][title=?]", "RubyLLM::RateLimitError", count: 1
  end

  test "GET index orders by most recent first" do
    create_property(reference: "MC-OLD", title: { "fr" => "Old" }, created_at: 2.days.ago)
    create_property(reference: "MC-NEW", title: { "fr" => "New" }, created_at: 1.hour.ago)
    get admin_properties_url
    assert_select "table tbody tr:first-child td", /MC-NEW/
  end

  # NEW
  test "GET new renders property form" do
    get new_admin_property_url
    assert_response :success
    assert_select "form"
    assert_select "input[name='property[reference]']"
    assert_select "select[name='property[transaction_type]']"
    assert_select "select[name='property[property_type]']"
  end

  test "GET new shows only FR title field" do
    get new_admin_property_url
    assert_select "input[name='property[title][fr]']"
    assert_select "input[name='property[title][en]']", false
  end

  test "GET new shows only FR description field" do
    get new_admin_property_url
    assert_select "textarea[name='property[description][fr]']"
    assert_select "textarea[name='property[description][en]']", false
  end

  # CREATE
  test "POST create creates property and redirects" do
    assert_difference "Property.count", 1 do
      post admin_properties_url, params: {
        property: property_params
      }
    end
    prop = Property.last
    assert_equal "MC-100", prop.reference
    assert_equal "Studio neuf", prop.title["fr"]
    assert_nil prop.title["en"]
    assert_equal 850_000, prop.price
    assert_equal "sale", prop.transaction_type
    assert_equal "studio", prop.property_type
    assert_equal "MC", prop.country
    assert_equal "Monaco", prop.city
    assert prop.published
    assert_redirected_to admin_properties_url
  end

  test "POST create forces off_market to true even if false passed in" do
    post admin_properties_url, params: {
      property: property_params.merge(off_market: "0")
    }
    prop = Property.last
    assert prop.off_market
  end

  test "POST create enqueues PropertyTranslationJob" do
    assert_enqueued_with(job: PropertyTranslationJob) do
      post admin_properties_url, params: { property: property_params }
    end
  end

  test "POST create with district and building" do
    post admin_properties_url, params: {
      property: property_params.merge(district_id: @district.id, building_id: @building.id)
    }
    prop = Property.last
    assert_equal @district, prop.district
    assert_equal @building, prop.building
  end

  test "POST create with invalid data re-renders form" do
    assert_no_difference "Property.count" do
      post admin_properties_url, params: {
        property: property_params.merge(reference: "")
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create with duplicate reference re-renders form" do
    create_property(reference: "MC-100")
    assert_no_difference "Property.count" do
      post admin_properties_url, params: {
        property: property_params
      }
    end
    assert_response :unprocessable_entity
  end

  # EDIT
  test "GET edit renders form with existing data" do
    prop = create_property(
      reference: "MC-001",
      title: { "fr" => "Studio existant", "en" => "Existing studio" },
      price: 1_200_000
    )
    get edit_admin_property_url(prop)
    assert_response :success
    assert_select "input[name='property[reference]'][value='MC-001']"
    assert_select "input[name='property[title][fr]'][value='Studio existant']"
    assert_select "input[name='property[title][en]']", false
  end

  # UPDATE
  test "PATCH update updates property and redirects" do
    prop = create_property(reference: "MC-001", title: { "fr" => "Old title" })
    patch admin_property_url(prop), params: {
      property: {
        title: { fr: "Updated title" },
        price: 1_500_000
      }
    }
    assert_redirected_to admin_properties_url
    prop.reload
    assert_equal "Updated title", prop.title["fr"]
    assert_equal 1_500_000, prop.price
  end

  # Editing FR in the admin form must never destroy the translated locales:
  # the translator may be unable to rebuild them (API outage, spend cap).
  test "PATCH update preserves translated title locales when editing French" do
    prop = create_property(
      reference: "MC-TRANS-1",
      title: { "fr" => "Studio", "en" => "Studio flat", "sv" => "Etta" }
    )
    patch admin_property_url(prop), params: { property: { title: { fr: "Studio rénové" } } }

    prop.reload
    assert_equal "Studio rénové", prop.title["fr"]
    assert_equal "Studio flat", prop.title["en"]
    assert_equal "Etta", prop.title["sv"]
  end

  test "PATCH update preserves translated description locales when editing French" do
    prop = create_property(
      reference: "MC-TRANS-2",
      description: { "fr" => "Beau studio", "en" => "Lovely studio", "de" => "Schönes Studio" }
    )
    patch admin_property_url(prop), params: { property: { description: { fr: "Très beau studio" } } }

    prop.reload
    assert_equal "Très beau studio", prop.description["fr"]
    assert_equal "Lovely studio", prop.description["en"]
    assert_equal "Schönes Studio", prop.description["de"]
  end

  test "PATCH update preserves other locales when editing title and description together" do
    prop = create_property(
      reference: "MC-TRANS-3",
      title: { "fr" => "Studio", "it" => "Monolocale" },
      description: { "fr" => "Beau studio", "it" => "Bel monolocale" }
    )
    patch admin_property_url(prop), params: {
      property: { title: { fr: "Studio vue mer" }, description: { fr: "Studio avec vue" } }
    }

    prop.reload
    assert_equal "Monolocale", prop.title["it"]
    assert_equal "Bel monolocale", prop.description["it"]
  end

  test "POST create accepts a French-only title and description" do
    assert_difference "Property.count", 1 do
      post admin_properties_url, params: {
        property: {
          reference: "MC-NEW-1",
          title: { fr: "Nouveau bien" },
          description: { fr: "Description" },
          transaction_type: "sale",
          property_type: "apartment",
          country: "MC",
          city: "Monaco"
        }
      }
    end
    prop = Property.find_by(reference: "MC-NEW-1")
    assert_equal({ "fr" => "Nouveau bien" }, prop.title)
    assert_equal({ "fr" => "Description" }, prop.description)
  end

  test "PATCH update can toggle published flag" do
    prop = create_property(reference: "MC-001", published: false)
    patch admin_property_url(prop), params: {
      property: { published: "1" }
    }
    prop.reload
    assert prop.published
  end

  test "PATCH update can unpublish property" do
    prop = create_property(reference: "MC-001", published: true)
    patch admin_property_url(prop), params: {
      property: { published: "0" }
    }
    prop.reload
    refute prop.published
  end

  test "PATCH update can toggle featured flag" do
    prop = create_property(reference: "MC-001", featured: false)
    patch admin_property_url(prop), params: {
      property: { featured: "1" }
    }
    prop.reload
    assert prop.featured
  end

  test "GET show on synced property renders read-only view with translation timestamps" do
    prop = create_property(
      reference: "MC-SYNC-001", immotoolbox_id: 42,
      title: { "fr" => "Synced title", "de" => "Deutscher Titel" },
      translations_status: { "de" => { "translated_at" => "2026-04-20T10:00:00Z" } }
    )
    get admin_property_url(prop)
    assert_response :success
    assert_select "a", text: /Modifier/, count: 0
    assert_select "td", /Deutscher Titel/
  end

  test "GET edit on synced property returns 404" do
    prop = create_property(reference: "MC-001", immotoolbox_id: 12345)
    get edit_admin_property_url(prop)
    assert_response :not_found
  end

  test "PATCH update on synced property returns 404" do
    prop = create_property(reference: "MC-001", immotoolbox_id: 12345, title: { "fr" => "Original" })
    patch admin_property_url(prop), params: {
      property: { title: { fr: "Changed by admin" } }
    }
    assert_response :not_found
    prop.reload
    assert_equal "Original", prop.title["fr"]
  end

  test "DELETE destroy on synced property returns 404" do
    prop = create_property(reference: "MC-001", immotoolbox_id: 12345)
    assert_no_difference "Property.count" do
      delete admin_property_url(prop)
    end
    assert_response :not_found
  end

  test "PATCH update enqueues PropertyTranslationJob when FR title changes" do
    prop = create_property(reference: "MC-001", title: { "fr" => "Old title" })
    clear_enqueued_jobs
    assert_enqueued_with(job: PropertyTranslationJob, args: [ prop.id ]) do
      patch admin_property_url(prop), params: {
        property: { title: { fr: "New title" } }
      }
    end
  end

  test "PATCH update enqueues brochure job directly when only price changes" do
    prop = create_property(reference: "MC-001", title: { "fr" => "Title" }, price: 1_000_000)
    prop.update_columns(translation_source_hash: "seeded-hash")
    clear_enqueued_jobs
    patch admin_property_url(prop), params: {
      property: { price: 2_000_000 }
    }
    translation_jobs = enqueued_jobs.select { |j| j[:job] == PropertyTranslationJob }
    brochure_jobs = enqueued_jobs.select { |j| j[:job] == PropertyBrochureGenerationJob }
    assert_empty translation_jobs
    refute_empty brochure_jobs
  end

  test "PATCH update with invalid data re-renders form" do
    prop = create_property(reference: "MC-001")
    create_property(reference: "MC-002")
    patch admin_property_url(prop), params: {
      property: { reference: "MC-002" }
    }
    assert_response :unprocessable_entity
  end

  # DESTROY
  test "DELETE destroy deletes property and redirects" do
    prop = create_property(reference: "MC-001")
    assert_difference "Property.count", -1 do
      delete admin_property_url(prop)
    end
    assert_redirected_to admin_properties_url
  end

  # OFF-MARKET FILTER
  test "GET index with filter=off_market shows only off-market properties" do
    on_market = create_property(reference: "MC-ON", off_market: false, published: true)
    off_market = create_property(reference: "MC-OFF", off_market: true, published: true)
    get admin_properties_url(filter: "off_market")
    assert_response :success
    assert_select "td", /MC-OFF/
    assert_select "td", text: /MC-ON/, count: 0
  end

  test "GET index with filter=immotool shows only synced properties" do
    synced = create_property(reference: "MC-SYNC", immotoolbox_id: 9999)
    manual = create_property(reference: "MC-MANUAL", off_market: true)
    get admin_properties_url(filter: "immotool")
    assert_response :success
    assert_select "td", /MC-SYNC/
    assert_select "td", text: /MC-MANUAL/, count: 0
  end

  test "GET index without filter shows all properties" do
    on_market = create_property(reference: "MC-ON", off_market: false)
    off_market = create_property(reference: "MC-OFF", off_market: true)
    get admin_properties_url
    assert_response :success
    assert_select "td", /MC-ON/
    assert_select "td", /MC-OFF/
  end

  # Admin sidebar
  test "admin sidebar shows Biens link" do
    get admin_properties_url
    assert_select "a", text: "Biens"
  end

  # URL path
  test "admin properties are served under /admin/biens" do
    assert_equal "/admin/biens", admin_properties_path
  end

  test "admin property member path uses biens segment" do
    prop = create_property
    assert_equal "/admin/biens/#{prop.id}", admin_property_path(prop)
  end

  private

  def property_params
    {
      reference: "MC-100",
      title: { fr: "Studio neuf" },
      description: { fr: "Beau studio" },
      price: 850_000,
      transaction_type: "sale",
      property_type: "studio",
      country: "MC",
      city: "Monaco",
      published: "1"
    }
  end

  def create_property(overrides = {})
    defaults = {
      reference: "MC-#{SecureRandom.hex(3)}",
      title: { "fr" => "Test Property" },
      description: { "fr" => "Description" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco"
    }
    Property.create!(defaults.merge(overrides))
  end
end
