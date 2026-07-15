require "test_helper"

class Admin::OutgoingEmailsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }

    @peer1 = Contact.create!(last_name: "Confrère", first_name: "Paul", company: "Agence A", email: "paul@agency.mc", category: "peer")
    @peer2 = Contact.create!(last_name: "Aubert", first_name: "Marie", company: "Agence B", email: "marie@agency.mc", category: "peer")
    @contact1 = Contact.create!(last_name: "Dupont", first_name: "Jean", email: "jean@example.com")
    @contact2 = Contact.create!(last_name: "Martin", first_name: "Luc", email: "luc@example.com")
    @no_email = Contact.create!(last_name: "Sans", first_name: "Email", phone: "0600000000", category: "peer")
  end

  test "redirects unauthenticated users to login" do
    delete session_url
    get new_admin_outgoing_email_url
    assert_redirected_to new_session_url
  end

  test "GET new renders the compose form with both peers and contacts lists stacked" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "h1", /Envoyer un email/
    assert_select "form#compose_form"
    # Both audiences are shown at once (stacked), no tabs: peers AND contacts.
    assert_select "input[type='checkbox'][value='#{@peer1.id}']", 1
    assert_select "input[type='checkbox'][value='#{@contact1.id}']", 1
  end

  test "GET new renders both audience section headings" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "h2", text: /confrères/i
    assert_select "h2", text: /contacts/i
  end

  test "GET new renders a separate turbo frame per audience list" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "turbo-frame#compose_peers"
    assert_select "turbo-frame#compose_contacts"
  end

  test "GET new renders a selected-recipients panel for each audience" do
    get new_admin_outgoing_email_url
    assert_response :success
    # Each list has its own live "selected" panel (the JS fills it in).
    assert_select "[data-recipient-selection-target='peersSelected']"
    assert_select "[data-recipient-selection-target='contactsSelected']"
  end

  test "GET new renders a search field for each audience list" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "input[type='search'][name='peers_q']"
    assert_select "input[type='search'][name='contacts_q']"
  end

  test "GET new pre-fills the body with Adrien's signature" do
    get new_admin_outgoing_email_url
    assert_response :success
    body = css_select("textarea[name='outgoing_email[body]']").first.text
    assert_includes body, "Adrien Maré"
    assert_includes body, "adrien@agencegaremonaco.com"
    assert_includes body, "T: +33 6 62 39 20 65"
    # The signature sits below empty leading lines so the cursor lands above it.
    assert body.start_with?("\n\n"), "expected blank lines before the signature, got #{body.inspect}"
  end

  test "POST create re-render keeps the submitted body, not the default signature" do
    # A validation failure (missing subject) re-renders the form; it must show
    # what Adrien actually typed, never re-stamp the pre-filled signature over it.
    post admin_outgoing_emails_url, params: {
      contact_ids: [ @peer1.id ],
      outgoing_email: { subject: "", body: "Bonjour, voici mon message." }
    }
    assert_response :unprocessable_entity
    body = css_select("textarea[name='outgoing_email[body]']").first.text
    assert_includes body, "Bonjour, voici mon message."
    refute_includes body, "Adrien Maré"
  end

  test "GET new lists only contacts that have an email" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "input[type='checkbox'][value='#{@no_email.id}']", 0
  end

  test "GET new peers search narrows only the peers list" do
    get new_admin_outgoing_email_url(peers_q: "Aubert")
    assert_response :success
    assert_select "input[type='checkbox'][value='#{@peer2.id}']", 1
    assert_select "input[type='checkbox'][value='#{@peer1.id}']", 0
    # The contacts list is unaffected by the peers search term.
    assert_select "input[type='checkbox'][value='#{@contact1.id}']", 1
  end

  test "GET new contacts search narrows only the contacts list" do
    get new_admin_outgoing_email_url(contacts_q: "Martin")
    assert_response :success
    assert_select "input[type='checkbox'][value='#{@contact2.id}']", 1
    assert_select "input[type='checkbox'][value='#{@contact1.id}']", 0
    # The peers list is unaffected by the contacts search term.
    assert_select "input[type='checkbox'][value='#{@peer1.id}']", 1
  end

  test "GET new lists peers ordered by name" do
    get new_admin_outgoing_email_url
    assert_response :success
    names = css_select("turbo-frame#compose_peers td[data-recipient-name]").map { |el| el.text.strip }
    assert_equal names.sort, names
  end

  test "GET new exposes each recipient's display name on the checkbox for the chips UI" do
    get new_admin_outgoing_email_url
    assert_response :success
    # The JS renders removable chips from the checkbox, so the name must travel
    # with it (rows scrolled out of view / filtered away still need their label).
    assert_select "input[type='checkbox'][value='#{@peer1.id}'][data-recipient-name=?]", @peer1.listing_name
  end

  test "GET new wires the recipient-selection controller around both frames" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "[data-controller='recipient-selection'] turbo-frame#compose_peers"
    assert_select "[data-controller='recipient-selection'] turbo-frame#compose_contacts"
    # A select-all header checkbox per list.
    assert_select "input[type='checkbox'][data-recipient-selection-target='all']", 2
    # Row checkboxes are the controller's persisted targets.
    assert_select "input[type='checkbox'][data-recipient-selection-target='item']"
  end

  test "GET new excludes contacts whose email is an empty string" do
    blank_email = Contact.create!(last_name: "Vide", first_name: "Email", email: "", category: "peer")
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "input[type='checkbox'][value='#{blank_email.id}']", 0
  end

  test "POST create drops contacts whose email is an empty string" do
    blank_email = Contact.create!(last_name: "Vide", first_name: "Email", email: "", category: "peer")
    assert_enqueued_jobs 1, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id, blank_email.id ],
        outgoing_email: { subject: "S", body: "B" }
      }
    end
    assert_equal 1, OutgoingEmail.last.pending_count
  end

  # --- create ---

  test "POST create sends to a mixed audience of peers and contacts at once" do
    # The whole point of the redesign: one email can target peers AND contacts.
    assert_enqueued_jobs 3, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id, @contact1.id, @contact2.id ],
        outgoing_email: { subject: "Bonjour", body: "Un message." }
      }
    end
    assert_redirected_to new_admin_outgoing_email_url
    assert_equal "Email envoyé à 3 contacts.", flash[:notice]
    assert_equal 3, OutgoingEmail.last.pending_count
  end

  test "POST create enqueues one send job per resolved recipient and redirects" do
    assert_enqueued_jobs 2, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id, @peer2.id ],
        outgoing_email: { subject: "Bonjour", body: "Un message." }
      }
    end
    assert_redirected_to new_admin_outgoing_email_url
    assert_equal "Email envoyé à 2 contacts.", flash[:notice]
  end

  test "POST create flash uses the singular when sending to exactly one recipient" do
    assert_enqueued_jobs 1, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id ],
        outgoing_email: { subject: "Bonjour", body: "Un message." }
      }
    end
    assert_redirected_to new_admin_outgoing_email_url
    assert_equal "Email envoyé à 1 contact.", flash[:notice]
  end

  test "POST create persists an OutgoingEmail with pending_count = recipient count" do
    assert_difference "OutgoingEmail.count", 1 do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id, @contact1.id ],
        outgoing_email: { subject: "Bonjour", body: "Un message." }
      }
    end
    assert_equal 2, OutgoingEmail.last.pending_count
  end

  test "POST create attaches an uploaded file to the OutgoingEmail" do
    file = Rack::Test::UploadedFile.new(StringIO.new("PDF"), "application/pdf", original_filename: "doc.pdf")
    post admin_outgoing_emails_url, params: {
      contact_ids: [ @peer1.id ],
      outgoing_email: { subject: "S", body: "B", file: file }
    }
    assert OutgoingEmail.last.file.attached?
  end

  test "POST create drops ids with no email and ids that no longer exist" do
    assert_enqueued_jobs 1, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id, @no_email.id, 999_999 ],
        outgoing_email: { subject: "S", body: "B" }
      }
    end
  end

  test "POST create de-duplicates a recipient submitted more than once" do
    # Distinct ids only; a doubled id must not double-send or inflate the count.
    assert_enqueued_jobs 1, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id, @peer1.id ],
        outgoing_email: { subject: "S", body: "B" }
      }
    end
    assert_equal 1, OutgoingEmail.last.pending_count
  end

  test "POST create with no resolvable recipients re-renders with an error" do
    assert_no_enqueued_jobs only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @no_email.id ], # no email → resolves to zero
        outgoing_email: { subject: "S", body: "B" }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".bg-red-50"
  end

  test "POST create with empty contact_ids re-renders with an error and enqueues nothing" do
    assert_no_enqueued_jobs only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [],
        outgoing_email: { subject: "S", body: "B" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create re-render keeps the submitted recipients checked" do
    post admin_outgoing_emails_url, params: {
      contact_ids: [ @peer1.id, @contact1.id ],
      outgoing_email: { subject: "", body: "B" }
    }
    assert_response :unprocessable_entity
    # The picker is re-rendered server-side with the submitted boxes checked, so
    # the recipient-selection controller reseeds its chips from them on connect.
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@peer1.id}'][checked]", 1
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@contact1.id}'][checked]", 1
    assert_select "input[type='checkbox'][name='contact_ids[]'][value='#{@contact2.id}'][checked]", 0
  end

  test "POST create with a missing subject re-renders with errors, enqueues nothing" do
    assert_no_enqueued_jobs only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id ],
        outgoing_email: { subject: "", body: "B" }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".bg-red-50"
  end

  test "POST create with a missing body re-renders with errors, enqueues nothing" do
    assert_no_enqueued_jobs only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id ],
        outgoing_email: { subject: "S", body: "" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create with an oversized attachment re-renders with errors, enqueues nothing" do
    big = Rack::Test::UploadedFile.new(StringIO.new("a" * (10.megabytes + 1)), "application/pdf", original_filename: "big.pdf")
    assert_no_enqueued_jobs only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id ],
        outgoing_email: { subject: "S", body: "B", file: big }
      }
    end
    assert_response :unprocessable_entity
    assert_no_difference "OutgoingEmail.count" do
      # second submit confirms nothing persisted on the failing path
      post admin_outgoing_emails_url, params: {
        contact_ids: [ @peer1.id ],
        outgoing_email: { subject: "S", body: "B", file: big }
      }
    end
  end

  test "admin sidebar links to the compose-email page" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "aside nav a[href='#{new_admin_outgoing_email_path}']", text: /Envoyer un email/
  end

  # Regression: the compose form must not nest the recipient search <form>s
  # (inside the turbo-frames) inside the outer #compose_form. Nested <form>
  # elements are invalid HTML; a real browser auto-closes #compose_form at the
  # inner form, orphaning the submit button and the subject/body fields so
  # clicking "Send" does nothing and never reaches the server. assert_select
  # uses Nokogiri's lenient HTML4 parser and hides this, so parse with the
  # browser-accurate HTML5 parser and assert the real form association.
  test "GET new keeps the submit button and message fields inside #compose_form under HTML5 parsing" do
    get new_admin_outgoing_email_url
    assert_response :success

    doc = Nokogiri::HTML5(response.body)
    compose_form = doc.at_css("form#compose_form")
    assert compose_form, "expected a #compose_form element"
    # File attachments only upload if the form is multipart; the empty-form
    # pattern must keep the enctype even with no file field inside the block.
    assert_equal "multipart/form-data", compose_form["enctype"],
                 "#compose_form must stay multipart so attachments upload"

    # A control belongs to #compose_form if the browser associates it there:
    # either a DOM descendant of the form, or linked to it by the form="" id.
    belongs = lambda do |el|
      el && (el.ancestors("form#compose_form").any? || el["form"] == "compose_form")
    end

    submit = doc.at_css("input[type='submit']")
    assert belongs.call(submit),
           "the Send button must belong to #compose_form (a nested search <form> orphaned it)"
    assert belongs.call(doc.at_css("input[name='outgoing_email[subject]']")),
           "the subject field must belong to #compose_form"
    assert belongs.call(doc.at_css("textarea[name='outgoing_email[body]']")),
           "the body field must belong to #compose_form"
    assert belongs.call(doc.at_css("input[type='file'][name='outgoing_email[file]']")),
           "the file field must belong to #compose_form"
    # Every recipient checkbox (in either list) must belong to the form too, or
    # the send drops them.
    checkboxes = doc.css("input[type='checkbox'][name='contact_ids[]']")
    assert checkboxes.any?, "expected recipient checkboxes"
    checkboxes.each do |box|
      assert belongs.call(box), "recipient checkbox #{box["value"]} must belong to #compose_form"
    end
  end
end
