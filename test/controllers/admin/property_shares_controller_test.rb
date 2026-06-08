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
    assert_select "h1", /Partager le bien/
    assert_select "input[type='checkbox'][name='contact_ids[]']", 2
  end

  test "GET new lists contacts in a table with all columns" do
    get new_admin_property_share_url(@property)
    assert_response :success
    # Header row exposes the full contact columns, with name split in two
    ["Nom", "Prénom", "Société", "Email", "Téléphone", "Ville", "Pays"].each do |col|
      assert_select "table thead th a", text: /#{Regexp.escape(col)}/
    end
    # One data row per contact
    assert_select "table tbody tr", 2
  end

  test "GET new headers are sort links targeting the turbo frame" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "turbo-frame#share_contacts_table"
    assert_select "thead th a[href*='sort=company']"
  end

  test "GET new sorts contacts by a requested column" do
    Contact.where.not(id: nil).update_all(company: nil)
    @contact1.update!(company: "Zeta")
    @contact2.update!(company: "Alpha")
    get new_admin_property_share_url(@property, sort: "company", direction: "asc")
    assert_response :success
    companies = css_select("table tbody td:nth-child(4)").map { |td| td.text.strip }.reject(&:empty?)
    assert_equal %w[Alpha Zeta], companies
  end

  test "GET new ignores an unknown sort column" do
    get new_admin_property_share_url(@property, sort: "evil); DROP TABLE contacts;--")
    assert_response :success
    assert_select "table tbody tr", 2
  end

  test "GET new shows first and last name in separate cells" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "table tbody tr:first-child td", text: "Dupont"
    assert_select "table tbody tr:first-child td", text: "Jean"
  end

  test "GET new shows the full details of a rich contact row" do
    Contact.create!(
      first_name: "Anna", last_name: "Berg", company: "Acme SCI",
      email: "anna@example.com", phone: "+377 99 00", city: "Monaco", country: "Monaco"
    )
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "table tbody td", text: /Acme SCI/
    assert_select "table tbody td", text: /\+377 99 00/
    assert_select "table tbody td", text: /Monaco/
  end

  test "GET new only lists contacts that have an email" do
    no_email = Contact.create!(first_name: "Sans", last_name: "Email", phone: "0600000000")
    get new_admin_property_share_url(@property)
    assert_response :success
    # Email-less contacts are excluded entirely (sharing is email-only)
    assert_select "input[type='checkbox'][value='#{no_email.id}']", 0
    assert_select "input[type='checkbox'][value='#{@contact1.id}']", 1
    # Only the two seeded contacts (both have emails) appear
    assert_select "table tbody tr", 2
  end

  test "GET new shows email preview with property details" do
    get new_admin_property_share_url(@property)
    assert_response :success
    # The preview HTML is escaped into the iframe srcdoc; decode it to inspect
    # the email the user actually sees.
    srcdoc = CGI.unescapeHTML(css_select("iframe[srcdoc]").first["srcdoc"])
    assert_includes srcdoc, "Studio Carré d'Or"
    assert_includes srcdoc, "Adrien Maré"
  end

  test "GET new renders email preview inside a sandboxed iframe, not inline HTML" do
    get new_admin_property_share_url(@property)
    assert_response :success
    # The preview must be isolated from the admin document so any HTML in
    # property fields can't manipulate admin DOM / cookies. An iframe with
    # sandbox and srcdoc achieves that.
    assert_select "iframe[sandbox][srcdoc]", 1
  end

  test "GET new email preview srcdoc contains the full email document" do
    get new_admin_property_share_url(@property)
    assert_response :success
    # The email HTML uses double quotes throughout (inline styles); it must be
    # HTML-escaped into the srcdoc attribute so the iframe receives the WHOLE
    # document, not a fragment truncated at the first inner quote.
    srcdoc = css_select("iframe[srcdoc]").first["srcdoc"]
    assert_includes srcdoc, "Studio Carré d&#39;Or" # body content (escaped apostrophe)
    assert_includes srcdoc, "Adrien Maré"
    assert_includes srcdoc, "</html>"               # the document is not truncated
  end

  test "GET new lists all contacts with checkboxes" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "table tbody td", text: "Dupont"
    assert_select "table tbody td", text: "Martin"
  end

  # CREATE (send sharing emails)
  test "POST create sends emails to selected contacts" do
    assert_emails 2 do
      post admin_property_share_url(@property), params: {
        contact_ids: [ @contact1.id, @contact2.id ]
      }
    end
    assert_redirected_to admin_contacts_url
    assert_equal "Bien partagé avec 2 contacts.", flash[:notice]
  end

  test "POST create sends email to a single contact" do
    assert_emails 1 do
      post admin_property_share_url(@property), params: {
        contact_ids: [ @contact1.id ]
      }
    end
    assert_redirected_to admin_contacts_url
  end

  test "POST create without selecting contacts redirects with alert" do
    assert_no_emails do
      post admin_property_share_url(@property), params: { contact_ids: [] }
    end
    assert_redirected_to new_admin_property_share_url(@property)
    assert_equal "Veuillez sélectionner au moins un contact.", flash[:alert]
  end

  test "POST create without contact_ids param redirects with alert" do
    assert_no_emails do
      post admin_property_share_url(@property)
    end
    assert_redirected_to new_admin_property_share_url(@property)
    assert_equal "Veuillez sélectionner au moins un contact.", flash[:alert]
  end
end
