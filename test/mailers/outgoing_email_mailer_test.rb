require "test_helper"

class OutgoingEmailMailerTest < ActionMailer::TestCase
  setup do
    @outgoing = OutgoingEmail.create!(
      subject: "Visite jeudi",
      body: "Bonjour,\n\nÊtes-vous disponible jeudi ?\n\nAdrien",
      pending_count: 1
    )
  end

  test "is delivered" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com")
    assert_emails 1 do
      mail.deliver_now
    end
  end

  test "is sent to the recipient" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com")
    assert_equal [ "jean@example.com" ], mail.to
  end

  test "is sent from the agency" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com")
    assert_equal [ "info@agencegaremonaco.com" ], mail.from
  end

  test "from header carries the agency display name" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com")
    assert_equal "\"Agence Immobilière de la Gare\" <info@agencegaremonaco.com>", mail[:from].decoded
  end

  test "reply-to is Adrien" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com")
    assert_equal [ "adrien@agencegaremonaco.com" ], mail.reply_to
  end

  test "uses the composed subject" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com")
    assert_equal "Visite jeudi", mail.subject
  end

  test "body is plain text with line breaks preserved" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com")
    body = mail.body.encoded
    assert_includes body, "Bonjour,"
    assert_includes body, "Êtes-vous disponible jeudi ?"
    assert_includes body, "Adrien"
  end

  test "has no HTML part" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com")
    assert_nil mail.html_part
    assert_equal "text/plain", mail.mime_type
  end

  test "attaches the file when present" do
    @outgoing.file.attach(
      io: StringIO.new("PDF DATA"), filename: "brochure.pdf", content_type: "application/pdf"
    )
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com")
    assert_equal 1, mail.attachments.size
    assert_equal "brochure.pdf", mail.attachments.first.filename
  end

  test "sends cleanly with no attachment" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com")
    assert_empty mail.attachments
  end
end
