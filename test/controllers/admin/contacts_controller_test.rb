require "test_helper"

class Admin::ContactsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
  end

  # Authentication
  test "redirects unauthenticated users to login" do
    delete session_url
    get admin_contacts_url
    assert_redirected_to new_session_url
  end

  # INDEX
  test "GET index lists all contacts" do
    Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    Contact.create!(first_name: "Pierre", last_name: "Martin", email: "pierre@example.com")
    get admin_contacts_url
    assert_response :success
    assert_select "h1", /Contacts/
    assert_select "table tbody tr", 2
  end

  test "GET index shows contact details" do
    Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com", phone: "+33 6 12 34 56 78")
    get admin_contacts_url
    assert_response :success
    assert_select "td", /Jean/
    assert_select "td", /Dupont/
    assert_select "td", /jean@example.com/
  end

  test "GET index orders by last name" do
    Contact.create!(first_name: "Pierre", last_name: "Martin", email: "pierre@example.com")
    Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    get admin_contacts_url
    assert_response :success
    assert_select "table tbody tr:first-child td", /Dupont/
  end

  test "GET index sorts by a requested column ascending" do
    Contact.create!(first_name: "Zoe", last_name: "Martin", email: "b@example.com", company: "Zeta")
    Contact.create!(first_name: "Amy", last_name: "Dupont", email: "a@example.com", company: "Alpha")
    get admin_contacts_url(sort: "company", direction: "asc")
    assert_response :success
    assert_select "table tbody tr:first-child td", /Alpha/
  end

  test "GET index sorts by a requested column descending" do
    Contact.create!(first_name: "Amy", last_name: "Dupont", email: "a@example.com", company: "Alpha")
    Contact.create!(first_name: "Zoe", last_name: "Martin", email: "b@example.com", company: "Zeta")
    get admin_contacts_url(sort: "company", direction: "desc")
    assert_response :success
    assert_select "table tbody tr:first-child td", /Zeta/
  end

  test "GET index ignores an unknown sort column (no SQL injection)" do
    Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    get admin_contacts_url(sort: "phone); DROP TABLE contacts;--", direction: "asc")
    assert_response :success
    assert_select "table tbody tr", 1
  end

  test "GET index headers are sort links targeting the turbo frame" do
    get admin_contacts_url
    assert_response :success
    assert_select "turbo-frame#contacts_table"
    assert_select "thead th a[href*='sort=company']"
  end

  test "GET index table frame can be requested directly via turbo frame" do
    Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    get admin_contacts_url, headers: { "Turbo-Frame" => "contacts_table" }
    assert_response :success
    assert_select "turbo-frame#contacts_table table tbody tr", 1
  end

  # FILTER + SEARCH
  test "GET index defaults to showing all contacts and peers" do
    Contact.create!(last_name: "Ordinary", peer: false)
    Contact.create!(last_name: "Confrère", company: "Agency", peer: true)
    get admin_contacts_url
    assert_response :success
    assert_select "table tbody tr", 2
  end

  test "GET index filters to peers only" do
    Contact.create!(last_name: "Ordinary", peer: false)
    Contact.create!(last_name: "Confrère", company: "Agency", peer: true)
    get admin_contacts_url(filter: "peers")
    assert_response :success
    assert_select "table tbody tr", 1
    assert_select "table tbody td", text: /Confrère/
  end

  test "GET index filters to ordinary contacts only" do
    Contact.create!(last_name: "Ordinary", peer: false)
    Contact.create!(last_name: "Confrère", company: "Agency", peer: true)
    get admin_contacts_url(filter: "contacts")
    assert_response :success
    assert_select "table tbody tr", 1
    assert_select "table tbody td", text: /Ordinary/
  end

  test "GET index searches by name, company, or email" do
    Contact.create!(first_name: "Anna", last_name: "Berg", email: "anna@acme.com", company: "Acme SCI")
    Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@other.com")
    get admin_contacts_url(q: "acme")
    assert_response :success
    assert_select "table tbody tr", 1
    assert_select "table tbody td", text: /Berg/
  end

  test "GET index combines filter and search" do
    Contact.create!(last_name: "Berg", company: "Acme", peer: true)
    Contact.create!(last_name: "Berg", company: "Acme", peer: false)
    get admin_contacts_url(filter: "peers", q: "berg")
    assert_response :success
    assert_select "table tbody tr", 1
  end

  test "GET index renders filter tabs with counts" do
    Contact.create!(last_name: "Ordinary", peer: false)
    Contact.create!(last_name: "Confrère", company: "Agency", peer: true)
    get admin_contacts_url
    assert_response :success
    assert_select "a[href*='filter=peers']"
    assert_select "a[href*='filter=contacts']"
  end

  test "GET index renders a search field" do
    get admin_contacts_url
    assert_response :success
    assert_select "input[type='search'][name='q']"
  end

  test "GET index shows a peer badge on confrère rows" do
    Contact.create!(last_name: "Confrère", company: "Agency", peer: true)
    get admin_contacts_url
    assert_response :success
    assert_select "table tbody tr td", text: /Confrère/
  end

  # NEW
  test "GET new renders contact form" do
    get new_admin_contact_url
    assert_response :success
    assert_select "form"
    assert_select "input[name='contact[first_name]']"
    assert_select "input[name='contact[last_name]']"
    assert_select "input[name='contact[email]']"
    assert_select "input[name='contact[phone]']"
  end

  test "GET new renders the extended legacy fields" do
    get new_admin_contact_url
    assert_response :success
    assert_select "input[name='contact[company]']"
    assert_select "input[name='contact[address]']"
    assert_select "input[name='contact[city]']"
    assert_select "input[name='contact[postcode]']"
    assert_select "input[name='contact[country]']"
    assert_select "textarea[name='contact[notes]']"
  end

  test "POST create persists the extended fields" do
    post admin_contacts_url, params: {
      contact: {
        first_name: "Anna", last_name: "Berg", company: "Acme SCI",
        address: "12 rue de la Gare", city: "Monaco", postcode: "98000",
        country: "Monaco", notes: "Recherche 2 pièces"
      }
    }
    c = Contact.last
    assert_equal "Acme SCI", c.company
    assert_equal "12 rue de la Gare", c.address
    assert_equal "Monaco", c.city
    assert_equal "98000", c.postcode
    assert_equal "Monaco", c.country
    assert_equal "Recherche 2 pièces", c.notes
  end

  test "GET edit shows the extended fields prefilled" do
    contact = Contact.create!(first_name: "Anna", last_name: "Berg", company: "Acme SCI", city: "Monaco")
    get edit_admin_contact_url(contact)
    assert_response :success
    assert_select "input[name='contact[company]'][value='Acme SCI']"
    assert_select "input[name='contact[city]'][value='Monaco']"
  end

  test "GET index shows the company column" do
    Contact.create!(company: "Consulat de Belgique", email: "c@example.mc")
    get admin_contacts_url
    assert_response :success
    assert_select "td", /Consulat de Belgique/
  end

  # CREATE
  test "POST create creates contact and redirects" do
    assert_difference "Contact.count", 1 do
      post admin_contacts_url, params: {
        contact: {
          first_name: "Jean",
          last_name: "Dupont",
          email: "jean@example.com",
          phone: "+33 6 12 34 56 78"
        }
      }
    end
    contact = Contact.last
    assert_equal "Jean", contact.first_name
    assert_equal "Dupont", contact.last_name
    assert_equal "jean@example.com", contact.email
    assert_equal "+33 6 12 34 56 78", contact.phone
    assert_redirected_to admin_contacts_url
  end

  test "POST create with no identifying field re-renders form" do
    assert_no_difference "Contact.count" do
      post admin_contacts_url, params: {
        contact: { first_name: "", last_name: "", email: "", phone: "", company: "", city: "Monaco" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create with duplicate email is allowed" do
    Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    assert_difference "Contact.count", 1 do
      post admin_contacts_url, params: {
        contact: { first_name: "Pierre", last_name: "Martin", email: "jean@example.com" }
      }
    end
    assert_redirected_to admin_contacts_url
  end

  # EDIT
  test "GET edit renders form with existing data" do
    contact = Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com", phone: "+33 6 12 34 56 78")
    get edit_admin_contact_url(contact)
    assert_response :success
    assert_select "input[name='contact[first_name]'][value='Jean']"
    assert_select "input[name='contact[last_name]'][value='Dupont']"
    assert_select "input[name='contact[email]'][value='jean@example.com']"
  end

  # UPDATE
  test "PATCH update updates contact and redirects" do
    contact = Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    patch admin_contact_url(contact), params: {
      contact: { first_name: "Pierre", last_name: "Martin", email: "pierre@example.com" }
    }
    assert_redirected_to admin_contacts_url
    contact.reload
    assert_equal "Pierre", contact.first_name
    assert_equal "Martin", contact.last_name
    assert_equal "pierre@example.com", contact.email
  end

  test "PATCH update with no identifying field re-renders form" do
    contact = Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    patch admin_contact_url(contact), params: {
      contact: { first_name: "", last_name: "", email: "", phone: "", company: "" }
    }
    assert_response :unprocessable_entity
  end

  # DESTROY
  test "DELETE destroy deletes contact and redirects" do
    contact = Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    assert_difference "Contact.count", -1 do
      delete admin_contact_url(contact)
    end
    assert_redirected_to admin_contacts_url
  end
end
