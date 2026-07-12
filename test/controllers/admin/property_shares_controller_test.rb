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
    @peer = Contact.create!(last_name: "Confrère", company: "Agency", email: "peer@agency.mc", peer: true)
  end

  # Authentication
  test "redirects unauthenticated users to login" do
    delete session_url
    get new_admin_property_share_url(@property)
    assert_redirected_to new_session_url
  end

  # NEW (compose-style share form: stacked peers/contacts picker)
  test "GET new renders the share form with both peers and contacts lists stacked" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "h1", /Partager le bien/
    assert_select "form#share_form"
    # Both audiences are shown at once (stacked), no tabs: peers AND contacts.
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@peer.id}']", 1
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@contact1.id}']", 1
    assert_select "a[href*='filter=']", 0
  end

  test "GET new shows which property is being shared" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "p", text: /MC-TEST-001/
  end

  test "GET new renders a separate turbo frame per audience list" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "turbo-frame#share_peers"
    assert_select "turbo-frame#share_contacts"
  end

  test "GET new renders a search field for each audience list" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "input[type='search'][name='peers_q']"
    assert_select "input[type='search'][name='contacts_q']"
  end

  test "GET new wires the recipient-selection controller around both frames" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "[data-controller='recipient-selection'] turbo-frame#share_peers"
    assert_select "[data-controller='recipient-selection'] turbo-frame#share_contacts"
    # A select-all header checkbox per list, plus a live "selected" panel each.
    assert_select "input[type='checkbox'][data-recipient-selection-target='all']", 2
    assert_select "[data-recipient-selection-target='peersSelected']"
    assert_select "[data-recipient-selection-target='contactsSelected']"
  end

  test "GET new only lists contacts that have an email" do
    no_email = Contact.create!(first_name: "Sans", last_name: "Email", phone: "0600000000")
    get new_admin_property_share_url(@property)
    assert_response :success
    # Email-less contacts are excluded entirely (sharing is email-only)
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{no_email.id}']", 0
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@contact1.id}']", 1
  end

  test "GET new with no shareable contacts shows a create-contact call to action" do
    Contact.delete_all
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "p", text: /Aucun contact pour le moment/
    assert_select "a[href='#{new_admin_contact_path}']", text: "Ajouter un contact"
  end

  test "GET new with contacts present shows no create-contact call to action" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "a[href='#{new_admin_contact_path}']", 0
  end

  test "GET new peers search narrows only the peers list" do
    other_peer = Contact.create!(last_name: "Aubert", email: "aubert@agency.mc", peer: true)
    get new_admin_property_share_url(@property, peers_q: "Aubert")
    assert_response :success
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{other_peer.id}']", 1
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@peer.id}']", 0
    # The contacts list is unaffected by the peers search term.
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@contact1.id}']", 1
  end

  test "GET new contacts search narrows only the contacts list" do
    get new_admin_property_share_url(@property, contacts_q: "Martin")
    assert_response :success
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@contact2.id}']", 1
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@contact1.id}']", 0
    # The peers list is unaffected by the contacts search term.
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@peer.id}']", 1
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

  test "GET new pre-fills the subject with the property reference and French title" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "input[name='property_share[subject]'][value=?]", "MC-TEST-001 — Studio Carré d'Or"
  end

  test "GET new renders an empty optional message field" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_equal "", css_select("textarea[name='property_share[body]']").first.text.strip
  end

  test "GET new offers the PDF brochure attachment with logo checked by default" do
    get new_admin_property_share_url(@property)
    assert_response :success
    assert_select "input[type='checkbox'][name='property_share[attach_pdf]']:not([checked])", 1
    assert_select "input[type='checkbox'][name='property_share[include_logo]'][checked]", 1
  end

  # Regression twin of the compose-page test: the share form must not nest the
  # recipient search <form>s inside #share_form. assert_select's lenient HTML4
  # parser hides nesting, so parse with the browser-accurate HTML5 parser and
  # assert the real form association.
  test "GET new keeps the submit button and message fields inside #share_form under HTML5 parsing" do
    get new_admin_property_share_url(@property)
    assert_response :success

    doc = Nokogiri::HTML5(response.body)
    assert doc.at_css("form#share_form"), "expected a #share_form element"

    belongs = lambda do |el|
      el && (el.ancestors("form#share_form").any? || el["form"] == "share_form")
    end

    assert belongs.call(doc.at_css("input[type='submit']")),
           "the Send button must belong to #share_form (a nested search <form> orphaned it)"
    assert belongs.call(doc.at_css("input[name='property_share[subject]']")),
           "the subject field must belong to #share_form"
    assert belongs.call(doc.at_css("textarea[name='property_share[body]']")),
           "the message field must belong to #share_form"
    assert belongs.call(doc.at_css("input[type='checkbox'][name='property_share[attach_pdf]']")),
           "the attach-PDF checkbox must belong to #share_form"
    assert belongs.call(doc.at_css("input[type='checkbox'][name='property_share[include_logo]']")),
           "the include-logo checkbox must belong to #share_form"
    checkboxes = doc.css("input[type='checkbox'][name='contact_ids[]']")
    assert checkboxes.any?, "expected recipient checkboxes"
    checkboxes.each do |box|
      assert belongs.call(box), "recipient checkbox #{box["value"]} must belong to #share_form"
    end
  end

  # CREATE (queue one share email per recipient)
  test "POST create queues one share job per selected contact and returns to the shared property" do
    assert_enqueued_jobs 2, only: SharePropertyEmailJob do
      post admin_property_share_url(@property), params: {
        contact_ids: [ @contact1.id, @contact2.id ],
        property_share: { subject: "Sujet perso", body: "Bonjour", attach_pdf: "0", include_logo: "1" }
      }
    end
    assert_redirected_to admin_property_url(@property)
    assert_equal "Bien partagé avec 2 contacts.", flash[:notice]
  end

  test "POST create persists the send options on a PropertyShare and enqueues per contact" do
    assert_difference "PropertyShare.count", 1 do
      post admin_property_share_url(@property), params: {
        contact_ids: [ @contact1.id ],
        property_share: { subject: "Sujet perso", body: "Bonjour Jean", attach_pdf: "1", include_logo: "0" }
      }
    end
    share = PropertyShare.last
    assert_equal @property, share.property
    assert_equal "Sujet perso", share.subject
    assert_equal "Bonjour Jean", share.body
    assert_equal true, share.attach_pdf
    assert_equal false, share.include_logo
    assert_equal 1, share.pending_count
    assert_enqueued_with(job: SharePropertyEmailJob, args: [ share.id, @contact1.id ])
  end

  test "POST create with the PDF option warms the brochure cache once before the fan-out" do
    post admin_property_share_url(@property), params: {
      contact_ids: [ @contact1.id, @contact2.id ],
      property_share: { subject: "S", attach_pdf: "1", include_logo: "1" }
    }
    assert @property.reload.cached_brochure(locale: :fr, include_logo: true).present?,
           "expected the shared variant to be pre-cached so each job only downloads it"
  end

  test "POST create without the PDF option does not touch the brochure cache" do
    post admin_property_share_url(@property), params: {
      contact_ids: [ @contact1.id ],
      property_share: { subject: "S", attach_pdf: "0" }
    }
    assert_equal 0, @property.reload.brochures.count
  end

  test "POST create with invalid options persists nothing" do
    assert_no_difference "PropertyShare.count" do
      post admin_property_share_url(@property), params: {
        contact_ids: [ @contact1.id ],
        property_share: { subject: "" }
      }
    end
  end

  test "POST create flash uses the singular when sharing with exactly one contact" do
    post admin_property_share_url(@property), params: {
      contact_ids: [ @contact1.id ],
      property_share: { subject: "S" }
    }
    assert_equal "Bien partagé avec 1 contact.", flash[:notice]
  end

  test "POST create de-duplicates a contact submitted more than once" do
    assert_enqueued_jobs 1, only: SharePropertyEmailJob do
      post admin_property_share_url(@property), params: {
        contact_ids: [ @contact1.id, @contact1.id ],
        property_share: { subject: "S" }
      }
    end
  end

  test "POST create drops ids with no email and ids that no longer exist" do
    no_email = Contact.create!(first_name: "Sans", last_name: "Email", phone: "0600000000")
    assert_enqueued_jobs 1, only: SharePropertyEmailJob do
      post admin_property_share_url(@property), params: {
        contact_ids: [ @contact1.id, no_email.id, 999_999 ],
        property_share: { subject: "S" }
      }
    end
  end

  test "POST create with a missing subject re-renders with errors and keeps the typed message" do
    assert_no_enqueued_jobs only: SharePropertyEmailJob do
      post admin_property_share_url(@property), params: {
        contact_ids: [ @contact1.id ],
        property_share: { subject: "", body: "Bonjour, voici un bien." }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".bg-red-50"
    assert_includes css_select("textarea[name='property_share[body]']").first.text, "Bonjour, voici un bien."
  end

  test "POST create without recipients re-renders with an error and queues nothing" do
    assert_no_enqueued_jobs only: SharePropertyEmailJob do
      post admin_property_share_url(@property), params: {
        contact_ids: [],
        property_share: { subject: "S" }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".bg-red-50 li", text: "Veuillez sélectionner au moins un contact."
  end

  test "a validation re-render keeps the submitted recipients checked" do
    post admin_property_share_url(@property), params: {
      contact_ids: [ @contact1.id, @peer.id ],
      property_share: { subject: "" }
    }
    assert_response :unprocessable_entity
    # The picker is re-rendered server-side with the submitted boxes checked, so
    # the recipient-selection controller reseeds its chips from them on connect.
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@contact1.id}'][checked]", 1
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@peer.id}'][checked]", 1
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@contact2.id}'][checked]", 0
  end

  test "POST create surfaces the subject and recipients errors together" do
    post admin_property_share_url(@property), params: {
      property_share: { subject: "" }
    }
    assert_response :unprocessable_entity
    assert_select ".bg-red-50 li", 2
  end

  test "POST create without a property_share key degrades to a validation error, not a 400" do
    # A stripped or non-form client may post only contact_ids; the old
    # controller never raised on that shape, so the new one must not either.
    post admin_property_share_url(@property), params: { contact_ids: [ @contact1.id ] }
    assert_response :unprocessable_entity
    assert_select ".bg-red-50"
  end

  # PREVIEW (live refresh of the email preview while typing)
  test "POST preview returns the email HTML with the typed note escaped" do
    post preview_admin_property_share_url(@property), params: { body: "Bonjour <b>Jean</b>,\nvoici un bien." }
    assert_response :success
    assert_includes response.body, "Studio Carré d&#39;Or"
    assert_includes response.body, "Bonjour &lt;b&gt;Jean&lt;/b&gt;,<br>voici un bien."
    refute_includes response.body, "<b>Jean</b>"
  end

  test "POST preview without a body returns the plain property card" do
    post preview_admin_property_share_url(@property), params: { body: "" }
    assert_response :success
    assert_includes response.body, "Studio Carré d&#39;Or"
  end

  test "POST preview requires authentication" do
    delete session_url
    post preview_admin_property_share_url(@property), params: { body: "x" }
    assert_redirected_to new_session_url
  end

  test "a validation re-render seeds the preview with the typed note" do
    post admin_property_share_url(@property), params: {
      contact_ids: [ @contact1.id ],
      property_share: { subject: "", body: "Ma note personnelle" }
    }
    assert_response :unprocessable_entity
    srcdoc = CGI.unescapeHTML(css_select("iframe[srcdoc]").first["srcdoc"])
    assert_includes srcdoc, "Ma note personnelle"
  end
end
