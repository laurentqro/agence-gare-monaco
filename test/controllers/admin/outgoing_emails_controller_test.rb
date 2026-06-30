require "test_helper"

class Admin::OutgoingEmailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }

    @peer1 = Contact.create!(last_name: "Confrère", first_name: "Paul", company: "Agence A", email: "paul@agency.mc", peer: true)
    @peer2 = Contact.create!(last_name: "Aubert", first_name: "Marie", company: "Agence B", email: "marie@agency.mc", peer: true)
    @contact1 = Contact.create!(last_name: "Dupont", first_name: "Jean", email: "jean@example.com", peer: false)
    @no_email = Contact.create!(last_name: "Sans", first_name: "Email", phone: "0600000000", peer: true)
  end

  test "redirects unauthenticated users to login" do
    delete session_url
    get new_admin_outgoing_email_url
    assert_redirected_to new_session_url
  end

  test "GET new renders the compose form defaulting to the peers audience" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "h1", /Envoyer un email/
    assert_select "form#compose_form"
    # Default audience is peers: peers are listed, contacts are not.
    assert_select "input[type='checkbox'][value='#{@peer1.id}']", 1
    assert_select "input[type='checkbox'][value='#{@contact1.id}']", 0
  end

  test "GET new lists only contacts that have an email" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "input[type='checkbox'][value='#{@no_email.id}']", 0
  end

  test "GET new with audience=contacts lists contacts not peers" do
    get new_admin_outgoing_email_url(audience: "contacts")
    assert_response :success
    assert_select "input[type='checkbox'][value='#{@contact1.id}']", 1
    assert_select "input[type='checkbox'][value='#{@peer1.id}']", 0
  end

  test "GET new search narrows the list within the audience" do
    get new_admin_outgoing_email_url(audience: "peers", q: "Aubert")
    assert_response :success
    assert_select "input[type='checkbox'][value='#{@peer2.id}']", 1
    assert_select "input[type='checkbox'][value='#{@peer1.id}']", 0
  end

  test "GET new lists recipients ordered by name" do
    get new_admin_outgoing_email_url(audience: "peers")
    assert_response :success
    names = css_select("tbody [data-recipient-name]").map { |el| el.text.strip }
    assert_equal names.sort, names
  end

  test "GET new renders inside the recipient turbo frame" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "turbo-frame#compose_recipients"
  end

  test "GET new renders the audience toggle and search field" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "a[href*='audience=contacts']"
    assert_select "a[href*='audience=peers']"
    assert_select "input[type='search'][name='q']"
  end
end
