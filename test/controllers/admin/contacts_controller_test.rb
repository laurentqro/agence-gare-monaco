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

  test "POST create with invalid data re-renders form" do
    assert_no_difference "Contact.count" do
      post admin_contacts_url, params: {
        contact: { first_name: "", last_name: "", email: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create with duplicate email re-renders form" do
    Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    assert_no_difference "Contact.count" do
      post admin_contacts_url, params: {
        contact: { first_name: "Pierre", last_name: "Martin", email: "jean@example.com" }
      }
    end
    assert_response :unprocessable_entity
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

  test "PATCH update with invalid data re-renders form" do
    contact = Contact.create!(first_name: "Jean", last_name: "Dupont", email: "jean@example.com")
    patch admin_contact_url(contact), params: {
      contact: { email: "" }
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
