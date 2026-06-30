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

  test "GET new renders subject, body and attachment fields" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "input[name='outgoing_email[subject]']"
    assert_select "textarea[name='outgoing_email[body]']"
    assert_select "input[type='file'][name='outgoing_email[file]']"
    assert_select "input[type='submit']"
  end

  test "GET new renders a select-all checkbox wired to the select-all controller" do
    get new_admin_outgoing_email_url
    assert_response :success
    # The controller must wrap the frame so it survives Turbo re-render.
    assert_select "[data-controller='select-all'] turbo-frame#compose_recipients"
    assert_select "input[type='checkbox'][data-select-all-target='all']"
    # Row checkboxes are the controller's targets.
    assert_select "input[type='checkbox'][data-select-all-target='item']"
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
end
