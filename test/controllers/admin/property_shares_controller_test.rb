require "test_helper"

class Admin::PropertySharesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }

    @property = Property.create!(
      reference: "MC-TEST-001",
      title: { "fr" => "Studio Carré d'Or", "en" => "Studio Carré d'Or" },
      description: { "fr" => "Magnifique studio", "en" => "Beautiful studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_290_000,
      published: true
    )

    @contact1 = Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    @contact2 = Contact.create!(first_name: "Pierre", last_name: "Martin", email: "pierre@example.com")
  end

  # Authentication
  test "redirects unauthenticated users to login" do
    delete session_url
    get new_admin_property_share_url(@property)
    assert_redirected_to new_session_url
  end

  # NEW (select contacts form)
  test "GET new renders contact selection form" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "h1", /Share Property/
    assert_select "input[type='checkbox'][name='contact_ids[]']", 2
  end

  test "GET new shows property summary" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "td", /MC-TEST-001/
  end

  test "GET new lists all contacts with checkboxes" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "label", /Jean Dupont/
    assert_select "label", /Pierre Martin/
  end

  # CREATE (send sharing emails)
  test "POST create sends emails to selected contacts" do
    assert_emails 2 do
      post admin_property_share_url(@property), params: {
        contact_ids: [@contact1.id, @contact2.id]
      }
    end
    assert_redirected_to admin_contacts_url
    assert_equal "Property shared with 2 contacts.", flash[:notice]
  end

  test "POST create sends email to a single contact" do
    assert_emails 1 do
      post admin_property_share_url(@property), params: {
        contact_ids: [@contact1.id]
      }
    end
    assert_redirected_to admin_contacts_url
  end

  test "POST create without selecting contacts redirects with alert" do
    assert_no_emails do
      post admin_property_share_url(@property), params: { contact_ids: [] }
    end
    assert_redirected_to new_admin_property_share_url(@property)
    assert_equal "Please select at least one contact.", flash[:alert]
  end

  test "POST create without contact_ids param redirects with alert" do
    assert_no_emails do
      post admin_property_share_url(@property)
    end
    assert_redirected_to new_admin_property_share_url(@property)
    assert_equal "Please select at least one contact.", flash[:alert]
  end
end
