# Admin "Compose Email" feature — Design

**Date:** 2026-06-25
**Status:** Approved (design phase)

## Summary

Give the admin user (Adrien) a standalone page to compose and send an email to
one or more contacts/peers from the address book. The email has free-text
subject and body and one optional attachment. Each selected recipient receives
their own separate email; recipients never see each other. Sends run in the
background; the attachment is stored briefly, used for the sends, then purged.

## Goals

- Adrien can write a free-text subject and body and send to one or more contacts.
- Adrien can optionally attach one file of any type (up to 10 MB).
- Each recipient gets an individual email (no shared To/CC, no BCC list visible).
- The email reads like a normal personal message (plain text, no branding).
- Replies reach Adrien while preserving Brevo/DKIM deliverability.
- No long-term storage of sent emails or attachments.

## Non-goals (YAGNI)

- No sent-email history / audit log.
- No Markdown or rich-text formatting of the body.
- No multiple attachments.
- No per-email configurable sender (always agency from / Adrien reply-to).
- No deep-link "email selected" action from the Contacts list (standalone page only).

## Design decisions

| Decision | Choice | Rationale |
|---|---|---|
| Recipient handling | Separate email per contact | Discretion among peers; matches existing property-share loop |
| Entry point | Standalone "Envoyer un email" page + sidebar link | Discoverable, self-contained, not tied to a property |
| Body format | Plain text, no branding | Reads like a personal email, not a marketing template |
| From / Reply-To | From agency (`info@agencegaremonaco.com`, display name "Agence Immobilière de la Gare"), Reply-To `adrien@agencegaremonaco.com` | Keeps verified Brevo sender + DKIM; replies reach Adrien. Matches `PropertyMailer` and `ApplicationMailer` default. Display name kept (not personalized to Adrien) for deliverability; the personal tone comes from the plain-text body and the Reply-To |
| Attachment | One optional file, any type, ≤ 10 MB | Covers the stated need; size cap keeps within email limits |
| Delivery | Async via Solid Queue (`deliver_later`-style jobs), no stored history | Instant UX; one failed recipient doesn't block the rest |
| Attachment lifecycle | Active Storage (local disk), auto-purged after last send | Survives the request for background jobs; no disk accumulation |

## User flow

1. Adrien clicks **"Envoyer un email"** in the admin sidebar.
2. The compose page shows a recipient picker (tabs Tous/Contacts/Peers, search,
   sortable table, checkboxes) plus **Subject**, **Body**, and **Attachment** fields.
3. Adrien selects recipients, writes subject + body, optionally attaches a file.
4. Adrien clicks **Envoyer**.
5. The controller validates, persists an `OutgoingEmail` record (with the
   attachment), enqueues one send job per recipient, flashes
   "Email mis en file pour N contacts", and redirects.
6. Each job sends one plain-text email (from agency, Reply-To Adrien, with the
   attachment if present), then decrements a completion counter.
7. When the last job completes, the attachment blob and the `OutgoingEmail`
   record are purged.

## Components

Each unit has one clear purpose, a defined interface, and is testable in isolation.

### 1. `OutgoingEmail` model (new, temporary record)

- **Purpose:** hold the attachment past the request so background jobs can read
  it, and act as a completion counter so we know when to purge.
- **Fields:** `subject:string`, `body:text`, `pending_count:integer`.
- **Attachment:** `has_one_attached :file` (Active Storage, `:local` service).
- **Validations:** presence of `subject` and `body`; attachment byte size ≤ 10 MB.
- **Key method:** `decrement_and_maybe_purge!` — atomically decrements
  `pending_count`; when the post-decrement value reaches 0, purges the attachment
  and destroys the record. Atomic (DB-level update + transaction) so two jobs
  finishing near-simultaneously can't both purge or both skip.
- **No Contact association** — recipients are resolved at enqueue time and passed
  to each job; they are not persisted (fire-and-forget).

### 2. `Admin::OutgoingEmailsController` (new)

- Inherits `Admin::BaseController` (admin layout, French locale).
- `new` — renders the compose page (recipient picker + form).
- `create` — receives `contact_ids[]` from the picker. Resolves them at enqueue
  time: loads the contacts, keeps only those that still exist and have a non-nil
  email, and maps each to a `(recipient_email, recipient_name)` pair. This is why
  the model has no Contact association — recipients are snapshotted into the jobs.
  Validates (≥ 1 resolvable recipient, subject + body present, attachment within
  size cap); builds the `OutgoingEmail` (`pending_count` = number of resolved
  recipients); enqueues one `SendOutgoingEmailJob` per recipient; flashes and
  redirects. On validation failure, re-renders the form with errors and enqueues
  nothing. A submitted `contact_id` that no longer exists or whose email became
  nil between page-load and submit is silently dropped (not an error); if that
  leaves zero recipients, it fails the "≥ 1 recipient" validation.
- Reuses the existing contact scope/search/sort helpers from the property-share
  flow; only contacts with an email are selectable (`.where.not(email: nil)`).

### 3. `OutgoingEmailMailer` (new)

- `compose(outgoing_email, recipient_email, recipient_name)` — builds one
  plain-text email: `from` agency, `reply_to` Adrien, subject/body from the
  record, line breaks preserved; attaches the file when present.
- Uses a **text-only** mailer template (`compose.text.erb`, no HTML part). The
  body is rendered verbatim as plain text, so there is no HTML escaping or
  injection surface from Adrien's free-text input; the subject is passed straight
  to the mail header.

### 4. `SendOutgoingEmailJob` (new)

- `perform(outgoing_email_id, recipient_email, recipient_name)` — loads the
  record, calls the mailer (`deliver_now` inside the job), then calls
  `decrement_and_maybe_purge!`. Per-recipient isolation and self-cleanup live here.

### 5. `PurgeStaleOutgoingEmailsJob` (new, safety-net sweeper)

- Recurring job (Solid Queue `config/recurring.yml`, like the exchange-rate
  refresh) that purges any `OutgoingEmail` older than 24 hours. Cheap insurance
  against orphaned records/blobs left by a job that exhausts retries before
  decrementing.

### 6. Compose view + shared picker partial + sidebar link

- `app/views/admin/outgoing_emails/new.html.erb` — recipient picker + subject /
  body / attachment fields.
- **Refactor:** extract the property-share recipient table (currently inline in
  `property_shares/new.html.erb`: tabs-with-counts, search form, sortable headers,
  checkboxes) into a shared partial `app/views/admin/contacts/_picker.html.erb`
  rendered by both the property-share flow and this new compose page. This is a
  real refactor, not a trivial move: the partial must be parameterized (form
  action, hidden-field/checkbox names — property-share posts `contact_ids[]`), and
  the tab/filter logic (`filtered_scope`) is currently duplicated across
  `PropertySharesController` and `ContactsController`, so it should be extracted
  into a shared concern. The plan should budget for this. Both flows must keep
  working; the existing property-share tests gate the extraction.
- New sidebar entry in `app/views/layouts/admin.html.erb` ("Envoyer un email").

## Data flow

```
create
  → save OutgoingEmail (pending_count = N, attachment stored)
  → enqueue N × SendOutgoingEmailJob
  → flash + redirect (instant)

each SendOutgoingEmailJob
  → OutgoingEmailMailer.compose(...).deliver_now   (one recipient)
  → outgoing_email.decrement_and_maybe_purge!

last job (pending_count → 0)
  → purge attachment + destroy OutgoingEmail
```

## Edge cases & error handling

**Validation (before any send):**
- No recipients selected → re-render form with error; no jobs enqueued.
- Missing subject or body → model validations; re-render with errors.
- Attachment > 10 MB → model validation; inline error ("Le fichier dépasse 10 Mo").
- Contact with no email → already excluded by the picker.

**Mid-send failures (in the job):**
- One recipient's SMTP send fails → that job raises and Solid Queue retries it;
  other recipients are unaffected (separate jobs).
- **Purge safety:** `decrement_and_maybe_purge!` uses an atomic DB-level decrement
  inside a transaction; exactly one job (the last) purges.
- **Orphan case:** a job that exhausts retries before decrementing leaves
  `pending_count > 0` forever → handled by the 24-hour sweeper.

## Testing (TDD — tests written first)

**Model** (`test/models/outgoing_email_test.rb`)
- Presence validations for `subject`, `body`.
- Attachment size validation (valid ≤ 10 MB, invalid > 10 MB).
- `decrement_and_maybe_purge!`: decrements; purges + destroys only at 0; safe
  under concurrent calls (purges exactly once).

**Mailer** (`test/mailers/outgoing_email_mailer_test.rb`)
- `compose` sets correct `to`, `from` (agency), `reply_to` (Adrien), `subject`,
  plain-text body with line breaks preserved.
- Attaches the file when present; sends cleanly with no attachment.

**Job** (`test/jobs/send_outgoing_email_job_test.rb`)
- Delivers exactly one email to the right recipient.
- Calls `decrement_and_maybe_purge!` after sending.
- Last job purges the record/blob; non-last jobs leave it intact.

**Controller** (`test/controllers/admin/outgoing_emails_controller_test.rb`)
- Unauthenticated → redirect to login.
- `new` renders compose form + recipient picker.
- `create` (valid) enqueues N jobs (`assert_enqueued_jobs N`), flashes, redirects.
- `create` (no recipients / missing subject / missing body / oversized attachment)
  → re-renders with errors, enqueues nothing.
- Contacts without email are not selectable.

**Sweeper** (`test/jobs/purge_stale_outgoing_emails_job_test.rb`)
- Purges records older than 24h; leaves recent ones.

**Regression:** run the existing property-share tests to confirm the shared
`_picker` partial extraction doesn't break them.

## Affected / new files

- New: `app/models/outgoing_email.rb`
- New: `app/controllers/admin/outgoing_emails_controller.rb`
- New: `app/mailers/outgoing_email_mailer.rb` + views (`text` template)
- New: `app/jobs/send_outgoing_email_job.rb`
- New: `app/jobs/purge_stale_outgoing_emails_job.rb`
- New: `app/views/admin/outgoing_emails/new.html.erb`
- New: `app/views/admin/contacts/_picker.html.erb` (extracted; property-share view updated to render it)
- New migration: `outgoing_emails` table
- Edit: `config/routes.rb` (admin `resources :outgoing_emails, only: [:new, :create]`)
- Edit: `config/recurring.yml` (sweeper schedule)
- Edit: `app/views/layouts/admin.html.erb` (sidebar link)
- Edit: `config/locales/admin.fr.yml` (admin labels/flash)
- New tests as listed above.
