require "test_helper"

class Admin::PropertiesControllerTest < ActionDispatch::IntegrationTest
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

  test "GET new shows multilingual title fields" do
    get new_admin_property_url
    assert_select "input[name='property[title][fr]']"
    assert_select "input[name='property[title][en]']"
  end

  test "GET new shows multilingual description fields" do
    get new_admin_property_url
    assert_select "textarea[name='property[description][fr]']"
    assert_select "textarea[name='property[description][en]']"
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
    assert_equal "New studio", prop.title["en"]
    assert_equal 850_000, prop.price
    assert_equal "sale", prop.transaction_type
    assert_equal "studio", prop.property_type
    assert_equal "MC", prop.country
    assert_equal "Monaco", prop.city
    assert prop.published
    assert_redirected_to admin_properties_url
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
    assert_select "input[name='property[title][en]'][value='Existing studio']"
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

  test "PATCH update marks synced property as manually_edited" do
    prop = create_property(reference: "MC-001", immotoolbox_id: 12345, manually_edited: false)
    patch admin_property_url(prop), params: {
      property: { title: { fr: "Changed by admin" } }
    }
    prop.reload
    assert prop.manually_edited
  end

  test "PATCH update does not mark non-synced property as manually_edited" do
    prop = create_property(reference: "MC-001", immotoolbox_id: nil, manually_edited: false)
    patch admin_property_url(prop), params: {
      property: { title: { fr: "Changed by admin" } }
    }
    prop.reload
    refute prop.manually_edited
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

  private

  def property_params
    {
      reference: "MC-100",
      title: { fr: "Studio neuf", en: "New studio" },
      description: { fr: "Beau studio", en: "Beautiful studio" },
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
