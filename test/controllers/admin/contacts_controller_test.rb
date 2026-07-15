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
    Contact.create!(last_name: "Ordinary")
    Contact.create!(last_name: "Confrère", company: "Agency", category: "peer")
    get admin_contacts_url
    assert_response :success
    assert_select "table tbody tr", 2
  end

  test "GET index filters to peers only" do
    Contact.create!(last_name: "Ordinary")
    Contact.create!(last_name: "Confrère", company: "Agency", category: "peer")
    get admin_contacts_url(filter: "peers")
    assert_response :success
    assert_select "table tbody tr", 1
    assert_select "table tbody td", text: /Confrère/
  end

  test "GET index filters to ordinary contacts only" do
    Contact.create!(last_name: "Ordinary")
    Contact.create!(last_name: "Confrère", company: "Agency", category: "peer")
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
    Contact.create!(last_name: "Berg", company: "Acme", category: "peer")
    Contact.create!(last_name: "Berg", company: "Acme")
    get admin_contacts_url(filter: "peers", q: "berg")
    assert_response :success
    assert_select "table tbody tr", 1
  end

  test "GET index renders a filter tab per category with counts" do
    Contact.create!(last_name: "Ordinary")
    Contact.create!(last_name: "Confrère", company: "Agency", category: "peer")
    Contact.create!(last_name: "Bailleur", category: "owner")
    get admin_contacts_url
    assert_response :success
    assert_select "a[href*='filter=contacts']"
    assert_select "a[href*='filter=prospects']"
    assert_select "a[href*='filter=peers']"
    assert_select "a[href*='filter=owners']"
    assert_select "a[href*='filter=tenants']"
    assert_select "nav a[href*='filter=owners'] span", text: "1"
    assert_select "nav a[href*='filter=prospects'] span", text: "0"
  end

  test "GET index filters to owners only" do
    Contact.create!(last_name: "Bailleur", category: "owner")
    Contact.create!(last_name: "Preneur", category: "tenant")
    Contact.create!(last_name: "Ordinary")
    get admin_contacts_url(filter: "owners")
    assert_response :success
    assert_select "table tbody tr", 1
    assert_select "table tbody td", text: /Bailleur/
  end

  test "GET index filters to tenants only" do
    Contact.create!(last_name: "Bailleur", category: "owner")
    Contact.create!(last_name: "Preneur", category: "tenant")
    get admin_contacts_url(filter: "tenants")
    assert_response :success
    assert_select "table tbody tr", 1
    assert_select "table tbody td", text: /Preneur/
  end

  test "GET index filters to prospects only" do
    Contact.create!(last_name: "Curieux", category: "prospect")
    Contact.create!(last_name: "Ordinary")
    get admin_contacts_url(filter: "prospects")
    assert_response :success
    assert_select "table tbody tr", 1
    assert_select "table tbody td", text: /Curieux/
  end

  test "GET index contacts filter excludes the classified categories" do
    Contact.create!(last_name: "Ordinary")
    Contact.create!(last_name: "Bailleur", category: "owner")
    Contact.create!(last_name: "Confrère", company: "Agency", category: "peer")
    get admin_contacts_url(filter: "contacts")
    assert_response :success
    assert_select "table tbody tr", 1
    assert_select "table tbody td", text: /Ordinary/
  end

  test "GET index tabs drive a full-page navigation, not a frame swap" do
    # The tab bar lives outside the turbo frame, so it must navigate the whole
    # page; otherwise the active highlight never moves off "Tous".
    get admin_contacts_url
    assert_response :success
    assert_select "nav a[data-turbo-frame='_top'][href*='filter=peers']"
  end

  test "GET index highlights the active filter tab" do
    get admin_contacts_url(filter: "peers")
    assert_response :success
    # The active tab carries the navy highlight; inactive ones do not.
    assert_select "nav a[href*='filter=peers'].bg-navy"
    assert_select "nav a[href*='filter=contacts'].bg-navy", false
  end

  test "GET index highlights Tous when no filter is set" do
    get admin_contacts_url
    assert_response :success
    # The "Tous" tab links back to the bare index (no filter param).
    assert_select "nav a.bg-navy", text: /Tous/
  end

  test "GET index renders a search field" do
    get admin_contacts_url
    assert_response :success
    assert_select "input[type='search'][name='q']"
  end

  test "GET index shows a peer badge on confrère rows" do
    Contact.create!(last_name: "Smith", company: "Agency", category: "peer")
    get admin_contacts_url
    assert_response :success
    assert_select "table tbody tr td", text: /Confrère/
  end

  test "GET index shows a category badge per row" do
    Contact.create!(last_name: "Bailleur", category: "owner")
    Contact.create!(last_name: "Preneur", category: "tenant")
    Contact.create!(last_name: "Curieux", category: "prospect")
    get admin_contacts_url
    assert_response :success
    assert_select "table tbody tr td", text: /Propriétaire/
    assert_select "table tbody tr td", text: /Locataire/
    assert_select "table tbody tr td", text: /Prospect/
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

  test "GET new renders a radio button per category" do
    get new_admin_contact_url
    assert_response :success
    Contact::CATEGORIES.each do |category|
      assert_select "input[type=radio][name='contact[category]'][value='#{category}']"
    end
  end

  test "GET new preselects the plain contact category" do
    get new_admin_contact_url
    assert_response :success
    assert_select "input[type=radio][name='contact[category]'][value='contact'][checked]"
    assert_select "input[type=radio][name='contact[category]'][checked]", 1
  end

  test "POST create can mark a contact as a peer" do
    post admin_contacts_url, params: {
      contact: { first_name: "Paul", last_name: "Smith", company: "Other Agency", category: "peer" }
    }
    assert_equal "peer", Contact.last.category
  end

  test "POST create rejects an unknown category" do
    assert_no_difference "Contact.count" do
      post admin_contacts_url, params: {
        contact: { last_name: "Dupont", category: "banana" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "GET edit preselects the contact's category" do
    peer = Contact.create!(last_name: "Smith", company: "Other Agency", category: "peer")
    get edit_admin_contact_url(peer)
    assert_response :success
    assert_select "input[type=radio][name='contact[category]'][value='peer'][checked]"
    assert_select "input[type=radio][name='contact[category]'][checked]", 1
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

  test "POST create flash says contact for an ordinary contact" do
    post admin_contacts_url, params: { contact: { last_name: "Dupont" } }
    assert_equal "Contact créé.", flash[:notice]
  end

  test "POST create flash says confrère for a peer" do
    post admin_contacts_url, params: { contact: { last_name: "Smith", category: "peer" } }
    assert_equal "Confrère créé.", flash[:notice]
  end

  test "POST create flash names the category" do
    post admin_contacts_url, params: { contact: { last_name: "Bailleur", category: "owner" } }
    assert_equal "Propriétaire créé.", flash[:notice]

    post admin_contacts_url, params: { contact: { last_name: "Preneur", category: "tenant" } }
    assert_equal "Locataire créé.", flash[:notice]

    post admin_contacts_url, params: { contact: { last_name: "Curieux", category: "prospect" } }
    assert_equal "Prospect créé.", flash[:notice]
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

  test "PATCH update flash says confrère when the contact is a peer" do
    peer = Contact.create!(last_name: "Smith", category: "peer")
    patch admin_contact_url(peer), params: { contact: { last_name: "Smith II" } }
    assert_equal "Confrère mis à jour.", flash[:notice]
  end

  test "PATCH update flash reflects a recategorization" do
    contact = Contact.create!(last_name: "Dupont")
    patch admin_contact_url(contact), params: { contact: { category: "tenant" } }
    assert_equal "Locataire mis à jour.", flash[:notice]
  end

  test "DELETE flash says confrère for a peer" do
    peer = Contact.create!(last_name: "Smith", category: "peer")
    delete admin_contact_url(peer)
    assert_equal "Confrère supprimé.", flash[:notice]
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
