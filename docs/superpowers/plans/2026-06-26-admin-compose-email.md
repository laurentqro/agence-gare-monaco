# Admin "Compose Email" Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give the admin user (Adrien) a standalone page to compose a free-text email (subject, body, one optional attachment ≤ 10 MB) and send it as a separate plain-text message to each selected peer **or** contact, delivered asynchronously, with the attachment auto-purged after the last send.

**Architecture:** A temporary `OutgoingEmail` Active Storage record carries the attachment past the request so background jobs can read it and acts as a completion counter. `Admin::OutgoingEmailsController#create` resolves recipients at enqueue time and fans out one `SendOutgoingEmailJob` per recipient; each job sends via `OutgoingEmailMailer#compose` then calls `decrement_and_maybe_purge!`. The last job purges the blob and destroys the record; a daily `PurgeStaleOutgoingEmailsJob` sweeps orphans. The compose page reuses the `Contact` `.peers`/`.contacts_only`/`.search` scopes, the email-only filter, the per-recipient send-loop shape, and the in-frame Turbo-Frame refresh pattern from the property-share flow, while leaving the property-share flow itself untouched.

**Tech Stack:** Rails 8.1.2, SQLite, Active Storage (`:local`/`:test` Disk service), Solid Queue, Action Mailer (Brevo SMTP), Turbo Frames + Stimulus, Tailwind, Minitest. French-only admin (`Admin::BaseController` forces `I18n.with_locale(:fr)`).

**Conventions to follow (verified against the codebase):**
- TDD always: write the failing test, run it red, write minimal code, run it green, commit. No exceptions (project CLAUDE.md).
- No `Co-Authored-By` lines in commits (user global rule). Commit to the current branch `admin-compose-email`; do not create new branches.
- Admin controller tests authenticate by creating a `User` then POSTing to `session_url` (see Task 5 setup). The test helper sets `I18n.locale = :en` in setup but the admin layout forces French via `Admin::BaseController`, so admin response bodies are French.
- Active Storage tables already exist (migration `20260302210830_create_active_storage_tables`); do NOT reinstall them.
- Migration version timestamps in this repo look like `20260626NNNNNN_*.rb`. Generate yours with `bin/rails generate migration` so the timestamp is fresh and monotonic.
- Run the full suite with `bin/rails test`. Run one file with `bin/rails test test/path/to/file.rb`. Run one test by name with `bin/rails test test/path/to/file.rb -n test_name_with_underscores` or `-n "/regex/"`.

---

## File Structure

**New files:**
- `db/migrate/<ts>_create_outgoing_emails.rb` — `outgoing_emails` table (subject, body, pending_count, timestamps).
- `app/models/outgoing_email.rb` — model: validations, `has_one_attached :file`, `decrement_and_maybe_purge!`.
- `app/mailers/outgoing_email_mailer.rb` — `compose(outgoing_email, recipient_email, recipient_name)`.
- `app/views/outgoing_email_mailer/compose.text.erb` — plain-text body template (text part only).
- `app/jobs/send_outgoing_email_job.rb` — sends one recipient's email then decrements/purges.
- `app/jobs/purge_stale_outgoing_emails_job.rb` — sweeper for records older than 24h.
- `app/controllers/admin/outgoing_emails_controller.rb` — `new` (compose page) + `create` (resolve + enqueue).
- `app/views/admin/outgoing_emails/new.html.erb` — compose form (audience toggle, search, recipient list frame, subject/body/attachment, submit).
- `app/views/admin/outgoing_emails/_recipient_list.html.erb` — Turbo-Frame partial re-rendered on audience/search change.
- `app/javascript/controllers/select_all_controller.js` — stateless select-all (toggles currently-listed checkboxes, reflects indeterminate/checked).
- Test files mirroring each of the above under `test/`.

**Modified files:**
- `config/routes.rb` — add `resources :outgoing_emails, only: [:new, :create]` inside `namespace :admin`.
- `config/recurring.yml` — add the daily sweeper under `production:`.
- `app/views/layouts/admin.html.erb` — add an "Envoyer un email" sidebar entry.
- `config/locales/admin.fr.yml` — add `admin.layout.compose_email` and an `admin.outgoing_emails.*` namespace.

**Left untouched (no regression risk):** `app/javascript/controllers/share_selection_controller.js`, `app/views/admin/property_shares/*`, `app/controllers/admin/property_shares_controller.rb`.

---

## Task 1: `OutgoingEmail` model + migration

**Files:**
- Create: `db/migrate/<ts>_create_outgoing_emails.rb`
- Create: `app/models/outgoing_email.rb`
- Test: `test/models/outgoing_email_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/models/outgoing_email_test.rb`:

```ruby
require "test_helper"

class OutgoingEmailTest < ActiveSupport::TestCase
  def build_email(**attrs)
    OutgoingEmail.new({ subject: "Bonjour", body: "Un message.", pending_count: 1 }.merge(attrs))
  end

  test "valid with subject, body and pending_count" do
    assert build_email.valid?
  end

  test "requires a subject" do
    email = build_email(subject: "")
    assert_not email.valid?
    assert_includes email.errors.attribute_names, :subject
  end

  test "requires a body" do
    email = build_email(body: "")
    assert_not email.valid?
    assert_includes email.errors.attribute_names, :body
  end

  test "accepts an attachment up to 10 MB" do
    email = build_email
    email.file.attach(
      io: StringIO.new("a" * 1.megabyte),
      filename: "ok.pdf",
      content_type: "application/pdf"
    )
    assert email.valid?
  end

  test "rejects an attachment over 10 MB" do
    email = build_email
    email.file.attach(
      io: StringIO.new("a" * (10.megabytes + 1)),
      filename: "too-big.pdf",
      content_type: "application/pdf"
    )
    assert_not email.valid?
    assert_includes email.errors.attribute_names, :file
  end

  test "decrement_and_maybe_purge! decrements but keeps the record above zero" do
    email = build_email(pending_count: 2)
    email.save!
    email.decrement_and_maybe_purge!
    assert OutgoingEmail.exists?(email.id)
    assert_equal 1, email.reload.pending_count
  end

  test "decrement_and_maybe_purge! destroys the record and purges the blob at zero" do
    email = build_email(pending_count: 1)
    email.file.attach(io: StringIO.new("x"), filename: "a.txt", content_type: "text/plain")
    email.save!
    blob_id = email.file.blob.id

    email.decrement_and_maybe_purge!

    assert_not OutgoingEmail.exists?(email.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
  end

  test "decrement_and_maybe_purge! purges exactly once under concurrent last calls" do
    email = build_email(pending_count: 1)
    email.save!

    # Two references to the same row both call the last decrement. Exactly one
    # should win the destroy; the other must not raise.
    a = OutgoingEmail.find(email.id)
    b = OutgoingEmail.find(email.id)
    assert_nothing_raised do
      a.decrement_and_maybe_purge!
      b.decrement_and_maybe_purge!
    end
    assert_not OutgoingEmail.exists?(email.id)
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/models/outgoing_email_test.rb`
Expected: FAIL — `NameError: uninitialized constant OutgoingEmail` (model/table do not exist yet).

- [ ] **Step 3: Generate the migration**

Run: `bin/rails generate migration CreateOutgoingEmails`

Replace the generated file's contents with:

```ruby
class CreateOutgoingEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :outgoing_emails do |t|
      t.string :subject, null: false
      t.text :body, null: false
      t.integer :pending_count, null: false, default: 0

      t.timestamps
    end
  end
end
```

- [ ] **Step 4: Run the migration**

Run: `bin/rails db:migrate`
Expected: creates `outgoing_emails`; `db/schema.rb` updated.

- [ ] **Step 5: Add the attachment-size error message to the locale file**

The model's size validation references this key, so add it before the model. Edit `config/locales/admin.fr.yml`. After the `property_shares:` block (after its `flash:` entry near line 295, at the same indentation as `property_shares:`), add:

```yaml
    outgoing_emails:
      errors:
        attachment_too_big: "Le fichier dépasse 10 Mo."
```

(Task 5 later extends this same `outgoing_emails:` namespace with the remaining keys. If you implement out of order and the namespace already exists, just add the `errors.attachment_too_big` key under it rather than redeclaring `outgoing_emails:`.)

- [ ] **Step 6: Write the model**

Create `app/models/outgoing_email.rb`:

```ruby
class OutgoingEmail < ApplicationRecord
  MAX_ATTACHMENT_BYTES = 10.megabytes

  has_one_attached :file

  validates :subject, presence: true
  validates :body, presence: true
  validate :attachment_within_size_limit

  # Atomically records that one more recipient's send finished. When the last
  # send completes (post-decrement count reaches 0) it purges the attachment
  # and destroys the record. The conditional UPDATE means exactly one caller
  # can drive the count to 0, so exactly one caller purges — two jobs finishing
  # at the same instant can't both purge or both skip.
  def decrement_and_maybe_purge!
    rows = self.class.where(id: id).where("pending_count > 0")
                 .update_all("pending_count = pending_count - 1")
    return if rows.zero?

    if reload.pending_count <= 0
      file.purge if file.attached?
      destroy
    end
  rescue ActiveRecord::RecordNotFound
    # Another concurrent caller already destroyed it; nothing to do.
  end

  private

  def attachment_within_size_limit
    return unless file.attached?
    return if file.blob.byte_size <= MAX_ATTACHMENT_BYTES

    # Explicit message (not a bare :too_big symbol) because rails-i18n ships no
    # `too_big` default in FR, so the rendered error box would otherwise show a
    # missing-translation string.
    errors.add(:file, I18n.t("admin.outgoing_emails.errors.attachment_too_big"))
  end
end
```

> The locale key `admin.outgoing_emails.errors.attachment_too_big` ("Le fichier dépasse 10 Mo.") is added in Step 3a below, before the model that references it. Task 1's tests run with `I18n.locale = :en` (set by the test helper) but the admin namespace only defines French; `I18n.t` resolves to the French string here. The model test asserts on `errors.attribute_names`, not the message text, so it is robust either way.

- [ ] **Step 7: Run the test to verify it passes**

Run: `bin/rails test test/models/outgoing_email_test.rb`
Expected: PASS (all 9 tests).

- [ ] **Step 8: Commit**

```bash
git add db/migrate/*_create_outgoing_emails.rb db/schema.rb app/models/outgoing_email.rb config/locales/admin.fr.yml test/models/outgoing_email_test.rb
git commit -m "Add OutgoingEmail model with attachment size cap and atomic purge"
```

---

## Task 2: `OutgoingEmailMailer#compose`

**Files:**
- Create: `app/mailers/outgoing_email_mailer.rb`
- Create: `app/views/outgoing_email_mailer/compose.text.erb`
- Test: `test/mailers/outgoing_email_mailer_test.rb`

**Reuse note:** `from` is inherited from `ApplicationMailer` (`"Agence Immobilière de la Gare <info@agencegaremonaco.com>"`); `reply_to` mirrors `PropertyMailer`'s `adrien@agencegaremonaco.com`. The template is text-only (no HTML part), so Adrien's free-text body is rendered verbatim with no HTML-escaping or injection surface.

- [ ] **Step 1: Write the failing test**

Create `test/mailers/outgoing_email_mailer_test.rb`:

```ruby
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
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com", "Jean Dupont")
    assert_emails 1 do
      mail.deliver_now
    end
  end

  test "is sent to the recipient" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com", "Jean Dupont")
    assert_equal [ "jean@example.com" ], mail.to
  end

  test "is sent from the agency" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com", "Jean Dupont")
    assert_equal [ "info@agencegaremonaco.com" ], mail.from
  end

  test "from header carries the agency display name" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com", "Jean Dupont")
    assert_equal "\"Agence Immobilière de la Gare\" <info@agencegaremonaco.com>", mail[:from].decoded
  end

  test "reply-to is Adrien" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com", "Jean Dupont")
    assert_equal [ "adrien@agencegaremonaco.com" ], mail.reply_to
  end

  test "uses the composed subject" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com", "Jean Dupont")
    assert_equal "Visite jeudi", mail.subject
  end

  test "body is plain text with line breaks preserved" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com", "Jean Dupont")
    body = mail.body.encoded
    assert_includes body, "Bonjour,"
    assert_includes body, "Êtes-vous disponible jeudi ?"
    assert_includes body, "Adrien"
  end

  test "has no HTML part" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com", "Jean Dupont")
    assert_nil mail.html_part
    assert_equal "text/plain", mail.mime_type
  end

  test "attaches the file when present" do
    @outgoing.file.attach(
      io: StringIO.new("PDF DATA"), filename: "brochure.pdf", content_type: "application/pdf"
    )
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com", "Jean Dupont")
    assert_equal 1, mail.attachments.size
    assert_equal "brochure.pdf", mail.attachments.first.filename
  end

  test "sends cleanly with no attachment" do
    mail = OutgoingEmailMailer.compose(@outgoing, "jean@example.com", "Jean Dupont")
    assert_empty mail.attachments
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/mailers/outgoing_email_mailer_test.rb`
Expected: FAIL — `NameError: uninitialized constant OutgoingEmailMailer`.

- [ ] **Step 3: Write the mailer**

Create `app/mailers/outgoing_email_mailer.rb`:

```ruby
class OutgoingEmailMailer < ApplicationMailer
  # Replies reach Adrien while the verified agency address stays the From (keeps
  # Brevo/DKIM alignment). Matches PropertyMailer.
  REPLY_TO = "adrien@agencegaremonaco.com".freeze

  def compose(outgoing_email, recipient_email, recipient_name)
    @body = outgoing_email.body
    @recipient_name = recipient_name

    if outgoing_email.file.attached?
      blob = outgoing_email.file.blob
      attachments[blob.filename.to_s] = {
        mime_type: blob.content_type,
        content: outgoing_email.file.download
      }
    end

    mail(
      to: recipient_email,
      reply_to: REPLY_TO,
      subject: outgoing_email.subject
    )
  end
end
```

- [ ] **Step 4: Write the text template**

Create `app/views/outgoing_email_mailer/compose.text.erb`:

```erb
<%= @body %>
```

(The text template renders the body verbatim. Action Mailer wraps `.text.erb` as the text part; line breaks in `@body` are preserved as-is.)

- [ ] **Step 5: Run the test to verify it passes**

Run: `bin/rails test test/mailers/outgoing_email_mailer_test.rb`
Expected: PASS (all 11 tests).

> If "has no HTML part" fails because the `mailer` layout injects an HTML wrapper, the cause is the layout, not the template. `compose.text.erb` produces only a text part, so `html_part` should be nil; the `layout "mailer"` from ApplicationMailer applies per-format and there is no `mailer.html.erb` being rendered here. If a stray HTML part appears, scope it out with `mail(...) { |format| format.text }` inside `compose`.

- [ ] **Step 6: Commit**

```bash
git add app/mailers/outgoing_email_mailer.rb app/views/outgoing_email_mailer/compose.text.erb test/mailers/outgoing_email_mailer_test.rb
git commit -m "Add OutgoingEmailMailer: plain-text compose with agency from and Adrien reply-to"
```

---

## Task 3: `SendOutgoingEmailJob`

**Files:**
- Create: `app/jobs/send_outgoing_email_job.rb`
- Test: `test/jobs/send_outgoing_email_job_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/jobs/send_outgoing_email_job_test.rb`:

```ruby
require "test_helper"

class SendOutgoingEmailJobTest < ActiveJob::TestCase
  setup do
    @outgoing = OutgoingEmail.create!(subject: "Hi", body: "Body", pending_count: 2)
  end

  test "delivers exactly one email to the right recipient" do
    assert_emails 1 do
      SendOutgoingEmailJob.perform_now(@outgoing.id, "jean@example.com", "Jean Dupont")
    end
    assert_equal [ "jean@example.com" ], ActionMailer::Base.deliveries.last.to
  end

  test "a non-last job decrements but leaves the record intact" do
    SendOutgoingEmailJob.perform_now(@outgoing.id, "jean@example.com", "Jean Dupont")
    assert OutgoingEmail.exists?(@outgoing.id)
    assert_equal 1, @outgoing.reload.pending_count
  end

  test "the last job purges the record and its blob" do
    @outgoing.update!(pending_count: 1)
    @outgoing.file.attach(io: StringIO.new("x"), filename: "a.txt", content_type: "text/plain")
    blob_id = @outgoing.file.blob.id

    SendOutgoingEmailJob.perform_now(@outgoing.id, "jean@example.com", "Jean Dupont")

    assert_not OutgoingEmail.exists?(@outgoing.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
  end

  test "missing record id is a no-op (does not raise)" do
    assert_nothing_raised do
      SendOutgoingEmailJob.perform_now(-1, "jean@example.com", "Jean Dupont")
    end
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/jobs/send_outgoing_email_job_test.rb`
Expected: FAIL — `NameError: uninitialized constant SendOutgoingEmailJob`.

- [ ] **Step 3: Write the job**

Create `app/jobs/send_outgoing_email_job.rb`:

```ruby
class SendOutgoingEmailJob < ApplicationJob
  queue_as :default

  def perform(outgoing_email_id, recipient_email, recipient_name)
    outgoing_email = OutgoingEmail.find_by(id: outgoing_email_id)
    return if outgoing_email.nil?

    OutgoingEmailMailer.compose(outgoing_email, recipient_email, recipient_name).deliver_now
    outgoing_email.decrement_and_maybe_purge!
  end
end
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bin/rails test test/jobs/send_outgoing_email_job_test.rb`
Expected: PASS (all 4 tests).

- [ ] **Step 5: Commit**

```bash
git add app/jobs/send_outgoing_email_job.rb test/jobs/send_outgoing_email_job_test.rb
git commit -m "Add SendOutgoingEmailJob: per-recipient send then decrement/purge"
```

---

## Task 4: `PurgeStaleOutgoingEmailsJob` (sweeper) + schedule

**Files:**
- Create: `app/jobs/purge_stale_outgoing_emails_job.rb`
- Modify: `config/recurring.yml`
- Test: `test/jobs/purge_stale_outgoing_emails_job_test.rb`

- [ ] **Step 1: Write the failing test**

Create `test/jobs/purge_stale_outgoing_emails_job_test.rb`:

```ruby
require "test_helper"

class PurgeStaleOutgoingEmailsJobTest < ActiveJob::TestCase
  test "purges records older than 24 hours and their blobs" do
    stale = OutgoingEmail.create!(subject: "Old", body: "Body", pending_count: 3)
    stale.file.attach(io: StringIO.new("x"), filename: "a.txt", content_type: "text/plain")
    blob_id = stale.file.blob.id
    stale.update_column(:created_at, 25.hours.ago)

    PurgeStaleOutgoingEmailsJob.perform_now

    assert_not OutgoingEmail.exists?(stale.id)
    assert_not ActiveStorage::Blob.exists?(blob_id)
  end

  test "leaves recent records untouched" do
    recent = OutgoingEmail.create!(subject: "New", body: "Body", pending_count: 1)
    recent.update_column(:created_at, 1.hour.ago)

    PurgeStaleOutgoingEmailsJob.perform_now

    assert OutgoingEmail.exists?(recent.id)
  end
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/jobs/purge_stale_outgoing_emails_job_test.rb`
Expected: FAIL — `NameError: uninitialized constant PurgeStaleOutgoingEmailsJob`.

- [ ] **Step 3: Write the sweeper job**

Create `app/jobs/purge_stale_outgoing_emails_job.rb`:

```ruby
class PurgeStaleOutgoingEmailsJob < ApplicationJob
  queue_as :default

  STALE_AFTER = 24.hours

  # Safety net for OutgoingEmail rows whose send jobs exhausted retries before
  # decrementing pending_count to 0, leaving an orphaned record + blob.
  def perform
    OutgoingEmail.where("created_at < ?", STALE_AFTER.ago).find_each do |email|
      email.file.purge if email.file.attached?
      email.destroy
    end
  end
end
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bin/rails test test/jobs/purge_stale_outgoing_emails_job_test.rb`
Expected: PASS (both tests).

- [ ] **Step 5: Schedule the sweeper**

Edit `config/recurring.yml`. Under the `production:` block, after the `clear_solid_queue_finished_jobs` entry, add:

```yaml
  purge_stale_outgoing_emails:
    class: PurgeStaleOutgoingEmailsJob
    schedule: every day at 4am
```

- [ ] **Step 6: Verify recurring config parses**

Run: `bin/rails runner "puts YAML.safe_load_file('config/recurring.yml', permitted_classes: [], aliases: true).dig('production','purge_stale_outgoing_emails','class')"`
Expected output: `PurgeStaleOutgoingEmailsJob`

- [ ] **Step 7: Commit**

```bash
git add app/jobs/purge_stale_outgoing_emails_job.rb config/recurring.yml test/jobs/purge_stale_outgoing_emails_job_test.rb
git commit -m "Add daily sweeper for stale OutgoingEmail records"
```

---

## Task 5: Route + controller skeleton + auth + locale labels

**Files:**
- Modify: `config/routes.rb:11` (inside `namespace :admin`)
- Modify: `config/locales/admin.fr.yml`
- Create: `app/controllers/admin/outgoing_emails_controller.rb`
- Create: `app/views/admin/outgoing_emails/new.html.erb` (minimal for now; fleshed out in Task 6)
- Create: `app/views/admin/outgoing_emails/_recipient_list.html.erb` (minimal for now; fleshed out in Task 6)
- Test: `test/controllers/admin/outgoing_emails_controller_test.rb`

This task gets `new` rendering with the audience-scoped recipient list and auth in place. `create` and select-all markup come in Tasks 6 and 7. Write the `new`/auth/list tests now; the `create` tests are added in Task 7.

- [ ] **Step 1: Add the route**

Edit `config/routes.rb`. Inside `namespace :admin do ... end`, after the `resources :contacts` line, add:

```ruby
    resources :outgoing_emails, only: %i[new create]
```

- [ ] **Step 2: Add locale labels**

Edit `config/locales/admin.fr.yml`.

(a) Under `admin.layout:` (after `information_requests:` on line 10), add:

```yaml
      compose_email: "Envoyer un email"
```

(b) Extend the `outgoing_emails:` namespace created in Task 1. It currently holds only `errors.attachment_too_big`. Add the remaining keys so the full block reads:

```yaml
    outgoing_emails:
      title: "Envoyer un email"
      audience:
        peers: "Confrères"
        contacts: "Contacts"
      search_placeholder: "Rechercher…"
      select_all: "Tout sélectionner"
      no_results: "Aucun résultat."
      no_recipients: "Aucun destinataire pour le moment."
      fields:
        subject: "Sujet"
        body: "Message"
        attachment: "Pièce jointe (optionnelle, 10 Mo max)"
      send: "Envoyer"
      flash:
        queued: "Email mis en file pour %{count} contacts."
        no_recipients: "Veuillez sélectionner au moins un destinataire."
      errors:
        attachment_too_big: "Le fichier dépasse 10 Mo."
```

(The `errors.attachment_too_big` key was added in Task 1; it is shown here for completeness. Merge the new keys into the existing block rather than creating a second `outgoing_emails:`.)

- [ ] **Step 3: Write the failing controller test (new + auth + list scoping)**

Create `test/controllers/admin/outgoing_emails_controller_test.rb`:

```ruby
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
end
```

- [ ] **Step 4: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/outgoing_emails_controller_test.rb`
Expected: FAIL — routing/controller missing (`uninitialized constant Admin::OutgoingEmailsController` or "no route matches").

- [ ] **Step 5: Write the controller (`new` only for now)**

Create `app/controllers/admin/outgoing_emails_controller.rb`:

```ruby
module Admin
  class OutgoingEmailsController < BaseController
    AUDIENCES = %w[peers contacts].freeze

    def new
      load_recipients
    end

    private

    # Recipients are email-bearing contacts of the chosen audience, name-ordered.
    # Mirrors PropertySharesController#new (audience filter then search), minus
    # sorting — this page deliberately has no sortable columns.
    def load_recipients
      @audience = AUDIENCES.include?(params[:audience]) ? params[:audience] : "peers"
      @query = params[:q]

      emailable = Contact.where.not(email: nil)
      @recipients = audience_scope(emailable)
                      .search(@query)
                      .order(:last_name, :first_name)
    end

    def audience_scope(relation)
      @audience == "contacts" ? relation.contacts_only : relation.peers
    end
  end
end
```

- [ ] **Step 6: Write a minimal `new` view + recipient list partial**

Create `app/views/admin/outgoing_emails/new.html.erb`:

```erb
<div class="p-8">
  <h1 class="heading-page mb-6"><%= t("admin.outgoing_emails.title") %></h1>

  <%= form_with url: admin_outgoing_emails_path, method: :post, id: "compose_form", multipart: true do |f| %>
    <%= f.hidden_field :audience, value: @audience, id: "compose_audience" %>

    <div class="bg-white rounded shadow p-6 mb-6">
      <%= render "recipient_list" %>
    </div>
  <% end %>
</div>
```

Create `app/views/admin/outgoing_emails/_recipient_list.html.erb`:

```erb
<%= turbo_frame_tag "compose_recipients" do %>
  <% frame = "compose_recipients" %>

  <div class="flex flex-wrap items-center justify-between gap-4 mb-4">
    <nav class="inline-flex rounded-lg border border-gray-200 bg-white p-1 text-sm">
      <% [["peers", t("admin.outgoing_emails.audience.peers")],
          ["contacts", t("admin.outgoing_emails.audience.contacts")]].each do |value, label| %>
        <% active = @audience == value %>
        <%= link_to new_admin_outgoing_email_path({ audience: value, q: @query }.compact_blank),
              data: { turbo_frame: frame },
              class: "px-3 py-1.5 rounded-md #{active ? "bg-navy text-white" : "text-gray-600 hover:text-navy"}" do %>
          <%= label %>
        <% end %>
      <% end %>
    </nav>

    <%= form_with url: new_admin_outgoing_email_path, method: :get, data: { turbo_frame: frame }, class: "relative w-full sm:w-80" do |sf| %>
      <%= sf.hidden_field :audience, value: @audience %>
      <%= sf.search_field :q, value: @query, placeholder: t("admin.outgoing_emails.search_placeholder"),
            class: "w-full rounded-lg border border-gray-300 bg-gray-50 px-3 py-2.5 text-sm shadow-sm focus:bg-white focus:border-navy focus:ring-2 focus:ring-navy/30" %>
    <% end %>
  </div>

  <% if @recipients.any? %>
    <div class="overflow-x-auto border border-gray-200 rounded">
      <table class="w-full text-sm">
        <tbody class="divide-y divide-gray-100">
          <% @recipients.each do |contact| %>
            <tr class="hover:bg-gray-50">
              <td class="px-3 py-2 w-10">
                <input type="checkbox" name="contact_ids[]" value="<%= contact.id %>" form="compose_form"
                       class="rounded border-gray-300 text-navy focus:ring-navy">
              </td>
              <td class="px-3 py-2 font-medium" data-recipient-name>
                <%= [contact.last_name, contact.first_name].compact_blank.join(" ") %>
              </td>
              <td class="px-3 py-2 text-gray-500"><%= contact.email %></td>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  <% else %>
    <p class="text-gray-500 text-sm"><%= t("admin.outgoing_emails.no_results") %></p>
  <% end %>
<% end %>
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `bin/rails test test/controllers/admin/outgoing_emails_controller_test.rb`
Expected: PASS (all 8 tests).

- [ ] **Step 8: Commit**

```bash
git add config/routes.rb config/locales/admin.fr.yml app/controllers/admin/outgoing_emails_controller.rb app/views/admin/outgoing_emails/ test/controllers/admin/outgoing_emails_controller_test.rb
git commit -m "Add admin compose-email new action with audience-scoped recipient list"
```

---

## Task 6: Compose form fields, select-all markup, and Stimulus controller

**Files:**
- Modify: `app/views/admin/outgoing_emails/new.html.erb` (add subject/body/attachment + submit)
- Modify: `app/views/admin/outgoing_emails/_recipient_list.html.erb` (add select-all checkbox)
- Create: `app/javascript/controllers/select_all_controller.js`
- Test: extend `test/controllers/admin/outgoing_emails_controller_test.rb` (markup assertions)

The select-all toggle's client behavior is verified via markup/data-attributes (Minitest integration test). There is no system-test harness in this repo (no `test/system/`, no `application_system_test_case.rb`), so we assert the wiring, not the JS runtime.

- [ ] **Step 1: Write the failing markup tests**

Add to `test/controllers/admin/outgoing_emails_controller_test.rb` (inside the class, before the final `end`):

```ruby
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/admin/outgoing_emails_controller_test.rb -n "/select-all|subject, body/"`
Expected: FAIL — fields and select-all markup not present yet.

- [ ] **Step 3: Add the select-all checkbox + controller wiring to the partial**

Edit `app/views/admin/outgoing_emails/_recipient_list.html.erb`.

(a) Wrap the frame in the `select-all` controller. Change the first line from:

```erb
<%= turbo_frame_tag "compose_recipients" do %>
  <% frame = "compose_recipients" %>
```

to:

```erb
<div data-controller="select-all">
<%= turbo_frame_tag "compose_recipients" do %>
  <% frame = "compose_recipients" %>
```

and add a matching closing `</div>` on the very last line, changing:

```erb
<% end %>
```

to:

```erb
<% end %>
</div>
```

(b) Give the table a header row with the select-all checkbox. Replace the `<table ...>` opening + `<tbody ...>` with:

```erb
      <table class="w-full text-sm">
        <thead class="bg-gray-100 text-left text-xs uppercase tracking-wider border-b-2 border-gray-200">
          <tr>
            <th class="px-3 py-2 w-10">
              <input type="checkbox" data-select-all-target="all"
                     data-action="change->select-all#toggleAll"
                     aria-label="<%= t("admin.outgoing_emails.select_all") %>"
                     class="rounded border-gray-300 text-navy focus:ring-navy">
            </th>
            <th class="px-3 py-2 font-semibold text-gray-700"><%= t("admin.contacts.table.last_name") %></th>
            <th class="px-3 py-2 font-semibold text-gray-700"><%= t("admin.contacts.table.email") %></th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100">
```

(c) Add the controller target + action to each row checkbox. Change the row checkbox input to:

```erb
                <input type="checkbox" name="contact_ids[]" value="<%= contact.id %>" form="compose_form"
                       data-select-all-target="item"
                       data-action="change->select-all#itemChanged"
                       class="rounded border-gray-300 text-navy focus:ring-navy">
```

- [ ] **Step 4: Add the form fields + submit to the compose view**

Edit `app/views/admin/outgoing_emails/new.html.erb`. Replace the entire file with:

```erb
<div class="p-8">
  <h1 class="heading-page mb-6"><%= t("admin.outgoing_emails.title") %></h1>

  <%= form_with url: admin_outgoing_emails_path, method: :post, id: "compose_form", multipart: true do |f| %>
    <%= f.hidden_field :audience, value: @audience, id: "compose_audience" %>

    <% if @outgoing_email&.errors&.any? %>
      <div class="bg-red-50 border border-red-200 text-red-700 rounded p-4 mb-6">
        <ul class="list-disc list-inside text-sm">
          <% @outgoing_email.errors.full_messages.each do |msg| %>
            <li><%= msg %></li>
          <% end %>
        </ul>
      </div>
    <% end %>

    <div class="bg-white rounded shadow p-6 mb-6">
      <%= render "recipient_list" %>
    </div>

    <div class="bg-white rounded shadow p-6 mb-6 space-y-4">
      <div>
        <%= label_tag "outgoing_email[subject]", t("admin.outgoing_emails.fields.subject"), class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= text_field_tag "outgoing_email[subject]", @outgoing_email&.subject,
              class: "w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm focus:border-navy focus:ring-2 focus:ring-navy/30" %>
      </div>
      <div>
        <%= label_tag "outgoing_email[body]", t("admin.outgoing_emails.fields.body"), class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= text_area_tag "outgoing_email[body]", @outgoing_email&.body, rows: 10,
              class: "w-full rounded-lg border border-gray-300 px-3 py-2.5 text-sm focus:border-navy focus:ring-2 focus:ring-navy/30" %>
      </div>
      <div>
        <%= label_tag "outgoing_email[file]", t("admin.outgoing_emails.fields.attachment"), class: "block text-sm font-medium text-gray-700 mb-1" %>
        <%= file_field_tag "outgoing_email[file]", class: "block text-sm text-gray-700" %>
      </div>
    </div>

    <div class="flex gap-3">
      <%= submit_tag t("admin.outgoing_emails.send"), class: "bg-navy text-white px-4 py-2 rounded hover:bg-navy/90 cursor-pointer" %>
      <%= link_to t("admin.shared.cancel"), admin_root_path, class: "px-4 py-2 border border-gray-300 rounded text-gray-700 hover:bg-gray-50" %>
    </div>
  <% end %>
</div>
```

- [ ] **Step 5: Write the Stimulus controller**

Create `app/javascript/controllers/select_all_controller.js`:

```javascript
import { Controller } from "@hotwired/stimulus"

// Stateless "select all" for the compose recipient list. The header checkbox
// toggles every CURRENTLY-LISTED row checkbox; the header reflects an
// all/none/indeterminate state as rows change. Because the list shows a single
// audience filtered by search, "select all" unambiguously means "everyone
// currently shown" — there is no cross-audience selection to persist (unlike
// the property-share picker). The controller lives OUTSIDE the Turbo Frame, so
// after the frame re-renders (audience/search change) it resyncs the header to
// whatever rows are now present.
export default class extends Controller {
  static targets = ["all", "item"]

  connect() {
    this.syncHeader()
  }

  // Header checkbox clicked: apply its state to every visible row.
  toggleAll() {
    const checked = this.allTarget.checked
    this.itemTargets.forEach((box) => { box.checked = checked })
  }

  // A row changed: refresh the header's checked/indeterminate state.
  itemChanged() {
    this.syncHeader()
  }

  // Re-run when Stimulus connects new item targets after a frame render.
  itemTargetConnected() {
    this.syncHeader()
  }

  itemTargetDisconnected() {
    this.syncHeader()
  }

  syncHeader() {
    if (!this.hasAllTarget) return
    const total = this.itemTargets.length
    const checked = this.itemTargets.filter((box) => box.checked).length
    this.allTarget.checked = total > 0 && checked === total
    this.allTarget.indeterminate = checked > 0 && checked < total
  }
}
```

- [ ] **Step 6: Run the markup tests to verify they pass**

Run: `bin/rails test test/controllers/admin/outgoing_emails_controller_test.rb`
Expected: PASS (all 10 tests — the 8 from Task 5 plus the 2 new ones).

- [ ] **Step 7: Commit**

```bash
git add app/views/admin/outgoing_emails/ app/javascript/controllers/select_all_controller.js test/controllers/admin/outgoing_emails_controller_test.rb
git commit -m "Add compose form fields and stateless select-all controller"
```

---

## Task 7: `create` action — resolve recipients, validate, enqueue

**Files:**
- Modify: `app/controllers/admin/outgoing_emails_controller.rb` (add `create` + helpers)
- Test: extend `test/controllers/admin/outgoing_emails_controller_test.rb`

**Reuse note:** the send loop mirrors `PropertySharesController#create` (lines 37-40: `contacts.each { ... }`), swapping `PropertyMailer.deliver_now` → `SendOutgoingEmailJob.perform_later`. Recipients are resolved (and audience-filtered) at enqueue time and snapshotted into each job as `(email, name)` — this is why the model has no Contact association.

- [ ] **Step 1: Write the failing `create` tests**

Add to `test/controllers/admin/outgoing_emails_controller_test.rb` (inside the class, before the final `end`):

```ruby
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
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `bin/rails test test/controllers/admin/outgoing_emails_controller_test.rb -n "/create/"`
Expected: FAIL — `create` action / `AbstractController::ActionNotFound` or "no route" is already there, so it will fail on missing action behavior (the controller has no `create`).

- [ ] **Step 3: Implement `create`**

Edit `app/controllers/admin/outgoing_emails_controller.rb`. Add a `create` action and the supporting private methods. Full file after the change:

```ruby
module Admin
  class OutgoingEmailsController < BaseController
    AUDIENCES = %w[peers contacts].freeze

    def new
      load_recipients
      @outgoing_email ||= OutgoingEmail.new
    end

    def create
      @outgoing_email = OutgoingEmail.new(outgoing_email_params)
      recipients = resolve_recipients

      if recipients.empty?
        @outgoing_email.errors.add(:base, t("admin.outgoing_emails.flash.no_recipients"))
        return render_new_with_errors
      end

      @outgoing_email.pending_count = recipients.size
      unless @outgoing_email.save
        return render_new_with_errors
      end

      recipients.each do |email, name|
        SendOutgoingEmailJob.perform_later(@outgoing_email.id, email, name)
      end

      redirect_to new_admin_outgoing_email_url,
                  notice: t("admin.outgoing_emails.flash.queued", count: recipients.size)
    end

    private

    def outgoing_email_params
      params.require(:outgoing_email).permit(:subject, :body, :file)
    end

    # Resolves submitted contact_ids to [email, name] pairs, keeping only
    # contacts that still exist, belong to the submitted audience, and have a
    # non-nil email. Out-of-audience / missing / now-email-less ids are silently
    # dropped (page-load vs submit drift); if that leaves zero, the create path
    # treats it as "no recipients selected".
    def resolve_recipients
      ids = Array(params[:contact_ids]).reject(&:blank?)
      return [] if ids.empty?

      audience_scope(Contact.where.not(email: nil).where(id: ids))
        .map { |c| [ c.email, [ c.last_name, c.first_name ].compact_blank.join(" ") ] }
    end

    def render_new_with_errors
      load_recipients
      render :new, status: :unprocessable_entity
    end

    # Recipients are email-bearing contacts of the chosen audience, name-ordered.
    # Mirrors PropertySharesController#new (audience filter then search), minus
    # sorting — this page deliberately has no sortable columns.
    def load_recipients
      @audience = AUDIENCES.include?(params[:audience]) ? params[:audience] : "peers"
      @query = params[:q]

      emailable = Contact.where.not(email: nil)
      @recipients = audience_scope(emailable)
                      .search(@query)
                      .order(:last_name, :first_name)
    end

    def audience_scope(relation)
      @audience ||= AUDIENCES.include?(params[:audience]) ? params[:audience] : "peers"
      @audience == "contacts" ? relation.contacts_only : relation.peers
    end
  end
end
```

> Note: `audience_scope` is used both by `load_recipients` (the list) and `resolve_recipients` (the send filter), so a submitted id is dropped unless it matches the submitted audience. The `@audience ||=` guard makes it safe to call from `resolve_recipients` before `load_recipients` runs.

- [ ] **Step 4: Run the create tests to verify they pass**

Run: `bin/rails test test/controllers/admin/outgoing_emails_controller_test.rb`
Expected: PASS (all tests in the file — the Task 5/6 set plus the new `create` set).

- [ ] **Step 5: Commit**

```bash
git add app/controllers/admin/outgoing_emails_controller.rb test/controllers/admin/outgoing_emails_controller_test.rb
git commit -m "Implement compose-email create: resolve audience recipients, validate, enqueue"
```

---

## Task 8: Sidebar link

**Files:**
- Modify: `app/views/layouts/admin.html.erb` (add nav entry after Contacts)
- Test: extend `test/controllers/admin/outgoing_emails_controller_test.rb`

- [ ] **Step 1: Write the failing test**

Add to `test/controllers/admin/outgoing_emails_controller_test.rb` (inside the class, before the final `end`):

```ruby
  test "admin sidebar links to the compose-email page" do
    get new_admin_outgoing_email_url
    assert_response :success
    assert_select "aside nav a[href='#{new_admin_outgoing_email_path}']", text: /Envoyer un email/
  end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `bin/rails test test/controllers/admin/outgoing_emails_controller_test.rb -n "/sidebar/"`
Expected: FAIL — no sidebar link yet.

- [ ] **Step 3: Add the sidebar entry**

Edit `app/views/layouts/admin.html.erb`. After the Contacts `<a>...</a>` block (ends at line 75, before the Information Requests link at line 76), insert:

```erb
            <a href="<%= new_admin_outgoing_email_path %>" class="<%= admin_nav_link_class(new_admin_outgoing_email_path) %>">
              <%# paper-airplane %>
              <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="<%= nav_icon_class %>">
                <path stroke-linecap="round" stroke-linejoin="round" d="M6 12L3.269 3.126A59.768 59.768 0 0121.485 12 59.77 59.77 0 013.27 20.876L5.999 12zm0 0h7.5" />
              </svg>
              <span><%= t("admin.layout.compose_email") %></span>
            </a>
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `bin/rails test test/controllers/admin/outgoing_emails_controller_test.rb -n "/sidebar/"`
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add app/views/layouts/admin.html.erb test/controllers/admin/outgoing_emails_controller_test.rb
git commit -m "Add Envoyer un email link to admin sidebar"
```

---

## Task 9: Full-suite regression check + final commit

- [ ] **Step 1: Run the entire test suite**

Run: `bin/rails test`
Expected: all tests green, including the existing property-share suite (this feature touches none of it).

- [ ] **Step 2: If anything is red, fix it before proceeding**

Address failures directly. Do not edit `share_selection_controller.js`, `app/views/admin/property_shares/*`, or `PropertySharesController` — if a property-share test fails, the cause is elsewhere (e.g. a shared locale key) and must be fixed without changing the property-share flow.

- [ ] **Step 3: Lint check (if configured)**

Run: `bin/rubocop app/models/outgoing_email.rb app/controllers/admin/outgoing_emails_controller.rb app/mailers/outgoing_email_mailer.rb app/jobs/send_outgoing_email_job.rb app/jobs/purge_stale_outgoing_emails_job.rb`
Expected: no offenses (or auto-correct with `-a` and re-run the relevant tests). If RuboCop is not installed, skip.

- [ ] **Step 4: Final commit (only if Steps 2-3 produced changes)**

```bash
git add -A
git commit -m "Compose-email feature: full suite green"
```

---

## Self-Review (completed during plan authoring)

**Spec coverage check — every spec component maps to a task:**
- `OutgoingEmail` model (validations, `has_one_attached`, `decrement_and_maybe_purge!`) → Task 1.
- `OutgoingEmailMailer#compose` (plain text, agency from / Adrien reply-to, attachment) → Task 2.
- `SendOutgoingEmailJob` (send one, then decrement/purge) → Task 3.
- `PurgeStaleOutgoingEmailsJob` (24h sweeper + recurring schedule) → Task 4.
- `Admin::OutgoingEmailsController#new` (audience toggle, email-only, search, name order, Turbo Frame, no Sortable) → Task 5.
- Compose view fields + select-all controller (stateless) → Task 6.
- `#create` (resolve at enqueue time, audience filter, validations, enqueue, drop drifted ids) → Task 7.
- Sidebar link → Task 8.
- Locale keys: `admin.outgoing_emails.errors.attachment_too_big` → Task 1 (the model references it); `admin.layout.compose_email` + the rest of `admin.outgoing_emails.*` → Task 5.
- Route → Task 5.
- "Leave property-share untouched / regression check" → Task 9.

**Reuse coverage (spec "Code reuse" section):**
- `.peers`/`.contacts_only`/`.search` scopes → `audience_scope` + `load_recipients` (Tasks 5, 7).
- Email-only `.where.not(email: nil)` → Tasks 5, 7.
- Per-recipient send-loop shape from `PropertySharesController#create` → Task 7 (`each { perform_later }`).
- In-frame Turbo-Frame refresh from `property_shares/new` (tabs + search target the frame) → Task 5 partial.
- `has_one_attached :file` convention (`PropertyDocument` precedent) → Task 1.
- Mailer from/reply-to precedent from `PropertyMailer` → Task 2.
- `Admin::BaseController` + flash/form styling → Tasks 5-8.
- Opportunistic `filtered_scope`: implemented as a two-line `audience_scope` (the spec's allowed "reimplement as a small audience scope" option) rather than extracting a shared concern, since compose needs only the peers-or-contacts subset and a heavyweight refactor of the property-share flow is explicitly discouraged.

**Type/name consistency check:**
- `decrement_and_maybe_purge!` — same name in Task 1 (def), Task 3 (call), Task 1 + Task 3 tests.
- `OutgoingEmailMailer.compose(outgoing_email, recipient_email, recipient_name)` — same 3-arg signature in Task 2 (def + test) and Task 3 (job call).
- `SendOutgoingEmailJob.perform(outgoing_email_id, recipient_email, recipient_name)` — same arity in Task 3 (def + test) and Task 7 (`perform_later`).
- Turbo Frame id `compose_recipients`, form id `compose_form`, controller `select-all` with targets `all`/`item` — consistent across Tasks 5, 6, and their tests.
- Locale keys referenced in views/controller (`admin.outgoing_emails.title|audience.*|search_placeholder|select_all|no_results|fields.*|send|flash.queued|flash.no_recipients`) all defined in Task 5; the model's size-validation message uses `admin.outgoing_emails.errors.attachment_too_big`, defined in Task 1 before the model. The model test asserts on `errors.attribute_names`, not the message string, so it is independent of the message text.

**Placeholder scan:** none — every code step contains complete code; every run step has an exact command and expected result.
