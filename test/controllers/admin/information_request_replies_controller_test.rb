require "test_helper"

class Admin::InformationRequestRepliesControllerTest < ActionDispatch::IntegrationTest
  setup do
    User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
  end

  def create_contact(attrs = {})
    InformationRequest.create!({
      form_type: "contact",
      name: "Carine Charlotte",
      email: "carine@example.com",
      subject: "Estimation de mon appartement",
      message: "Bonjour,\nPouvez-vous estimer mon bien ?"
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

  def reply_body
    css_select("textarea[name='outgoing_email[body]']").first.text
  end

  def reply_subject
    css_select("input[name='outgoing_email[subject]']").first["value"]
  end

  test "redirects unauthenticated users to login" do
    request = create_contact
    delete session_url
    get new_admin_information_request_reply_url(request)
    assert_redirected_to new_session_url
  end

  test "GET new shows the requester as the fixed recipient" do
    request = create_contact
    get new_admin_information_request_reply_url(request)
    assert_response :success
    assert_select "[data-testid='reply-recipient']", text: /Carine Charlotte/
    assert_select "[data-testid='reply-recipient']", text: /carine@example.com/
    assert_select "input[name='outgoing_email[to]']", count: 0
    assert_select "input[name='contact_ids[]']", count: 0
  end

  test "GET new prefills an enquiry subject with the property reference and French title" do
    request = create_enquiry
    get new_admin_information_request_reply_url(request)
    assert_equal "Re: MC-ADM-001 — Studio Test", reply_subject
  end

  test "GET new prefills a contact subject from the requester's own subject" do
    request = create_contact(subject: "Estimation de mon appartement")
    get new_admin_information_request_reply_url(request)
    assert_equal "Re: Estimation de mon appartement", reply_subject
  end

  test "GET new falls back to a generic subject when the request had none" do
    request = create_contact(subject: nil)
    get new_admin_information_request_reply_url(request)
    assert_equal "Re: votre demande", reply_subject
  end

  test "GET new prefills the body with the signature above the quoted message" do
    request = create_contact(created_at: Time.zone.local(2026, 9, 7, 17, 21))
    get new_admin_information_request_reply_url(request)
    body = reply_body
    assert body.start_with?("\n\n"), "expected blank lines before the signature, got #{body.inspect}"
    assert_includes body, "Adrien Maré"
    assert_includes body, "Le 07/09/2026 à 17:21, Carine Charlotte a écrit :"
    assert_includes body, "> Bonjour,\n> Pouvez-vous estimer mon bien ?"
    assert_operator body.index("Adrien Maré"), :<, body.index("a écrit :")
  end

  test "GET new marks an unread request as read" do
    request = create_contact(read: false)
    get new_admin_information_request_reply_url(request)
    assert request.reload.read?
  end

  test "POST create queues one email to the requester and stamps the request" do
    request = create_contact
    assert_enqueued_with(job: SendOutgoingEmailJob, args: ->(args) { args.last == "carine@example.com" }) do
      post admin_information_request_reply_url(request), params: {
        outgoing_email: { subject: "Re: Estimation", body: "Bonjour Carine, avec plaisir." }
      }
    end
    assert_enqueued_jobs 1, only: SendOutgoingEmailJob
    email = OutgoingEmail.last
    assert_equal "Re: Estimation", email.subject
    assert_equal "Bonjour Carine, avec plaisir.", email.body
    assert_equal 1, email.pending_count
    assert_in_delta Time.current, request.reload.replied_at, 5
    assert_redirected_to admin_information_request_url(request)
    assert_equal "Réponse envoyée à Carine Charlotte.", flash[:notice]
  end

  test "POST create attaches an uploaded file to the reply" do
    request = create_contact
    file = Rack::Test::UploadedFile.new(StringIO.new("PDF"), "application/pdf", original_filename: "doc.pdf")
    post admin_information_request_reply_url(request), params: {
      outgoing_email: { subject: "Re: Estimation", body: "Ci-joint.", file: file }
    }
    assert OutgoingEmail.last.file.attached?
  end

  test "POST create with a missing subject re-renders with the typed body and queues nothing" do
    request = create_contact
    assert_no_enqueued_jobs only: SendOutgoingEmailJob do
      post admin_information_request_reply_url(request), params: {
        outgoing_email: { subject: "", body: "Bonjour Carine, voici ma réponse." }
      }
    end
    assert_response :unprocessable_entity
    assert_includes reply_body, "Bonjour Carine, voici ma réponse."
    refute_includes reply_body, "a écrit :"
    assert_nil request.reload.replied_at
  end

  test "POST create with a missing body re-renders with an error" do
    request = create_contact
    post admin_information_request_reply_url(request), params: {
      outgoing_email: { subject: "Re: Estimation", body: "" }
    }
    assert_response :unprocessable_entity
    assert_select ".bg-red-50 li"
  end

  test "POST create on an already answered request overwrites the reply date" do
    request = create_contact(replied_at: 2.days.ago)
    post admin_information_request_reply_url(request), params: {
      outgoing_email: { subject: "Re: Estimation", body: "Suite à votre question." }
    }
    assert_in_delta Time.current, request.reload.replied_at, 5
  end
end
