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
      audience: "peers",
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

  test "GET new renders subject, body and attachment fields" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "input[name='outgoing_email[subject]']"
    assert_select "textarea[name='outgoing_email[body]']"
    assert_select "input[type='file'][name='outgoing_email[file]']"
    assert_select "input[type='submit']"
  end

  test "GET new renders a styled French file picker, not the bare browser control" do
    get new_admin_outgoing_email_url
    assert_response :success
    # The native input is hidden and driven by a styled label-button so the
    # control matches the admin theme and shows French text (the browser's own
    # "Choose file / No file chosen" ignores the locale).
    assert_select "[data-controller='file-input']"
    assert_select "input[type='file'][name='outgoing_email[file]'].hidden"
    assert_select "[data-controller='file-input'] label", text: /Choisir un fichier/
    assert_select "[data-file-input-target='filename']", text: /Aucun fichier sélectionné/
  end

  test "GET new wires the recipient-selection controller around the frame for select-all and persistence" do
    get new_admin_outgoing_email_url
    assert_response :success
    # The controller wraps the frame (and the hidden audience field) so both the
    # checked rows AND the audience survive a Turbo re-render on search/toggle.
    assert_select "[data-controller='recipient-selection'] turbo-frame#compose_recipients"
    assert_select "input[type='checkbox'][data-recipient-selection-target='all']"
    # Row checkboxes are the controller's persisted targets.
    assert_select "input[type='checkbox'][data-recipient-selection-target='item']"
  end

  test "GET new exposes the current audience on the frame so JS can keep the hidden field in sync" do
    get new_admin_outgoing_email_url(audience: "contacts")
    assert_response :success
    # The hidden audience field the controller writes to is inside the wrapper,
    # and the frame advertises its current audience for the controller to read
    # after each re-render. Without this, switching audience leaves the submitted
    # value stale and the chosen recipients get filtered out on the server.
    assert_select "[data-controller='recipient-selection'] input#compose_audience[type='hidden']"
    assert_select "turbo-frame#compose_recipients[data-audience='contacts']"
  end

  test "GET new carries the audience on a marker INSIDE the frame so it survives a Turbo swap" do
    # Turbo's frame render replaces only the frame's CONTENTS, never the
    # <turbo-frame> element's own attributes. So the audience the JS reads to
    # sync the submitted hidden field must live on an element inside the frame
    # (swapped in on every toggle/search), not on the frame element itself.
    # Otherwise, after switching peers -> contacts, the form submits audience
    # "peers" with contact ids, the server filters them all out, and the user
    # gets "select at least one recipient" despite having selected recipients.
    get new_admin_outgoing_email_url(audience: "contacts")
    assert_response :success
    assert_select "turbo-frame#compose_recipients [data-recipient-selection-target='marker'][data-audience='contacts']"

    get new_admin_outgoing_email_url(audience: "peers")
    assert_response :success
    assert_select "turbo-frame#compose_recipients [data-recipient-selection-target='marker'][data-audience='peers']"
  end

  test "GET new excludes contacts whose email is an empty string" do
    blank_email = Contact.create!(last_name: "Vide", first_name: "Email", email: "", peer: true)
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "input[type='checkbox'][value='#{blank_email.id}']", 0
  end

  test "POST create drops contacts whose email is an empty string" do
    blank_email = Contact.create!(last_name: "Vide", first_name: "Email", email: "", peer: true)
    assert_enqueued_jobs 1, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        audience: "peers",
        contact_ids: [ @peer1.id, blank_email.id ],
        outgoing_email: { subject: "S", body: "B" }
      }
    end
    assert_equal 1, OutgoingEmail.last.pending_count
  end

  test "POST create resolves recipients matching the submitted audience" do
    # Server-side guard: even if the audience and ids drift, the audience cross-
    # filter keeps a send single-audience. Submitting contacts under the contacts
    # audience emails the contacts (not peers).
    assert_enqueued_jobs 1, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        audience: "contacts",
        contact_ids: [ @contact1.id, @peer1.id ],
        outgoing_email: { subject: "S", body: "B" }
      }
    end
    assert_equal 1, OutgoingEmail.last.pending_count
  end

  # --- create ---

  test "POST create enqueues one send job per resolved peer and redirects" do
    assert_enqueued_jobs 2, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        audience: "peers",
        contact_ids: [ @peer1.id, @peer2.id ],
        outgoing_email: { subject: "Bonjour", body: "Un message." }
      }
    end
    assert_redirected_to new_admin_outgoing_email_url
    assert_equal "Email mis en file pour 2 contacts.", flash[:notice]
  end

  test "POST create persists an OutgoingEmail with pending_count = recipient count" do
    assert_difference "OutgoingEmail.count", 1 do
      post admin_outgoing_emails_url, params: {
        audience: "peers",
        contact_ids: [ @peer1.id, @peer2.id ],
        outgoing_email: { subject: "Bonjour", body: "Un message." }
      }
    end
    assert_equal 2, OutgoingEmail.last.pending_count
  end

  test "POST create attaches an uploaded file to the OutgoingEmail" do
    file = Rack::Test::UploadedFile.new(StringIO.new("PDF"), "application/pdf", original_filename: "doc.pdf")
    post admin_outgoing_emails_url, params: {
      audience: "peers",
      contact_ids: [ @peer1.id ],
      outgoing_email: { subject: "S", body: "B", file: file }
    }
    assert OutgoingEmail.last.file.attached?
  end

  test "POST create drops ids that are out of the submitted audience" do
    # contact1 is NOT a peer; submitting it under audience=peers must drop it.
    assert_enqueued_jobs 1, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        audience: "peers",
        contact_ids: [ @peer1.id, @contact1.id ],
        outgoing_email: { subject: "S", body: "B" }
      }
    end
    assert_equal 1, OutgoingEmail.last.pending_count
  end

  test "POST create drops ids with no email and ids that no longer exist" do
    assert_enqueued_jobs 1, only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        audience: "peers",
        contact_ids: [ @peer1.id, @no_email.id, 999_999 ],
        outgoing_email: { subject: "S", body: "B" }
      }
    end
  end

  test "POST create with no resolvable recipients re-renders with an error" do
    assert_no_enqueued_jobs only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        audience: "peers",
        contact_ids: [ @contact1.id ], # out of audience → resolves to zero
        outgoing_email: { subject: "S", body: "B" }
      }
    end
    assert_response :unprocessable_entity
    assert_select ".bg-red-50"
  end

  test "POST create with empty contact_ids re-renders with an error and enqueues nothing" do
    assert_no_enqueued_jobs only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        audience: "peers",
        contact_ids: [],
        outgoing_email: { subject: "S", body: "B" }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create with a missing subject re-renders with errors, enqueues nothing" do
    assert_no_enqueued_jobs only: SendOutgoingEmailJob do
      post admin_outgoing_emails_url, params: {
        audience: "peers",
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
        audience: "peers",
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
        audience: "peers",
        contact_ids: [ @peer1.id ],
        outgoing_email: { subject: "S", body: "B", file: big }
      }
    end
    assert_response :unprocessable_entity
    assert_no_difference "OutgoingEmail.count" do
      # second submit confirms nothing persisted on the failing path
      post admin_outgoing_emails_url, params: {
        audience: "peers",
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

  # Regression: the compose form must not nest the recipient search <form>
  # (inside the turbo-frame) inside the outer #compose_form. Nested <form>
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
    assert belongs.call(doc.at_css("input[name='audience']")),
           "the audience field must belong to #compose_form"
    # Every recipient checkbox must belong to the form too, or the send is empty.
    checkboxes = doc.css("input[type='checkbox'][name='contact_ids[]']")
    assert checkboxes.any?, "expected recipient checkboxes"
    checkboxes.each do |box|
      assert belongs.call(box), "recipient checkbox #{box["value"]} must belong to #compose_form"
    end
  end
end
