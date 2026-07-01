require "test_helper"

class Admin::InformationRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
  end

  def create_contact(attrs = {})
    InformationRequest.create!({
      form_type: "contact",
      name: "Jean Dupont",
      email: "jean@example.com",
      message: "Bonjour, je suis intéressé."
    }.merge(attrs))
  end

  def create_enquiry(attrs = {})
    property = Property.create!(
      reference: "MC-ADM-001",
      title: { "fr" => "Studio Test" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 950_000,
      published: true
    )
    InformationRequest.create!({
      form_type: "enquiry",
      name: "Marie Martin",
      email: "marie@example.com",
      message: "Ce bien est-il toujours disponible ?",
      property: property
    }.merge(attrs))
  end

  # Authentication
  test "redirects unauthenticated users to login" do
    delete session_url
    get admin_information_requests_url
    assert_redirected_to new_session_url
  end

  # INDEX
  test "GET index lists all submissions" do
    create_contact
    create_enquiry
    get admin_information_requests_url
    assert_response :success
    assert_select "table tbody tr", 2
  end

  test "GET index shows submitter name and email" do
    create_contact(name: "Jean Dupont", email: "jean@example.com")
    get admin_information_requests_url
    assert_response :success
    assert_select "td", /Jean Dupont/
    assert_select "td", /jean@example.com/
  end

  test "GET index filters by unread" do
    create_contact(read: true)
    create_contact(read: false, name: "Unread Person")
    get admin_information_requests_url(filter: "unread")
    assert_response :success
    assert_select "table tbody tr", 1
    assert_select "td", /Unread Person/
  end

  test "GET index filters by enquiry" do
    create_contact
    create_enquiry
    get admin_information_requests_url(filter: "enquiry")
    assert_response :success
    assert_select "table tbody tr", 1
  end

  test "GET index filters by contact" do
    create_contact
    create_enquiry
    get admin_information_requests_url(filter: "contact")
    assert_response :success
    assert_select "table tbody tr", 1
  end

  test "GET index orders newest first" do
    older = create_contact(name: "Older")
    older.update_column(:created_at, 2.days.ago)
    create_contact(name: "Newer")
    get admin_information_requests_url
    assert_response :success
    assert_select "table tbody tr:first-child td", /Newer/
  end

  # SHOW
  test "GET show displays the message" do
    submission = create_contact(message: "Un message très spécifique ici.")
    get admin_information_request_url(submission)
    assert_response :success
    assert_select "body", /Un message très spécifique ici\./
  end

  test "GET show marks an unread submission as read" do
    submission = create_contact(read: false)
    get admin_information_request_url(submission)
    assert_response :success
    assert submission.reload.read?
  end

  test "GET show for an enquiry links to the property" do
    submission = create_enquiry
    get admin_information_request_url(submission)
    assert_response :success
    assert_select "a[href=?]", admin_property_path(submission.property)
  end

  # UPDATE (toggle read)
  test "PATCH update can mark a submission unread" do
    submission = create_contact(read: true)
    patch admin_information_request_url(submission), params: { information_request: { read: false } }
    assert_redirected_to admin_information_requests_url
    assert_not submission.reload.read?
  end

  # Sidebar / dashboard unread badge
  test "admin sidebar shows unread count badge" do
    create_contact(read: false)
    create_contact(read: false)
    create_contact(read: true)
    get admin_root_url
    assert_response :success
    assert_select "nav a[href=?] span.bg-accent", admin_information_requests_path, text: "2"
  end

  test "admin sidebar shows no badge when all read" do
    create_contact(read: true)
    get admin_information_requests_url
    assert_response :success
    assert_select "nav a[href=?]", admin_information_requests_path do
      assert_select "span.bg-accent", count: 0
    end
  end

  # DESTROY
  test "DELETE destroy removes the submission" do
    submission = create_contact
    assert_difference("InformationRequest.count", -1) do
      delete admin_information_request_url(submission)
    end
    assert_redirected_to admin_information_requests_url
  end
end
