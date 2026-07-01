# Admin "Compose Email" feature — Design

**Date:** 2026-06-25
**Status:** Approved (design phase)

> **Amendment (2026-07-01) — mixed-audience redesign.** The original single-audience
> constraint below was **reversed** at Adrien's request. The compose page now sends
> to a **mixed audience**: peers **and** contacts together, in one email. The tabbed
> / audience-toggle recipient picker was replaced by **two always-visible stacked
> lists** (peers on top, contacts below), each with its own search box, its own
> select-all, and its own live "selected recipients" chip panel (removable ✕ chips).
> The server no longer cross-filters by a single `audience`; `create` resolves every
> submitted `contact_id` that still exists and has an email (`.distinct`), spanning
> both peers and contacts. There is no `audience` param, no audience marker, and no
> `set_audience`. Everything else in this doc (per-recipient send loop, `OutgoingEmail`
> lifecycle, mailer, jobs, attachment handling, async delivery, purge sweeper) is
> unchanged and audience-agnostic. Sections below that describe the audience toggle /
> single-audience behavior are **superseded** by this amendment.

## Summary

Give the admin user (Adrien) a standalone page to compose and send an email to
one or more recipients from the address book. A single email targets **one
audience** — peers **or** contacts, never a mix (Adrien emails groups of peers,
or groups of contacts, but not both at once). The email has free-text subject
and body and one optional attachment. Each selected recipient receives their own
separate email; recipients never see each other. Sends run in the background; the
attachment is stored briefly, used for the sends, then purged.

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
- **No mixed-audience sends.** A single email goes to peers or to contacts, not
  both — so no "Tous" tab and no cross-tab/cross-audience selection.
- **No reuse of the property-share *persisted-selection UI*.** The compose page
  has its own simpler recipient list; the existing `share_selection_controller.js`
  picker is left untouched (no shared-partial extraction, no controller rename).
  Backend logic IS reused — see "Code reuse" below.

## Code reuse

Maximize reuse of the **audience-agnostic** pieces the property-share flow already
established; build new only the parts that differ because compose is single-audience
and free-text. Explicitly:

**Reuse (do not rebuild):**
- `Contact` scopes `.peers`, `.contacts_only`, `.search(q)` — already shared model
  API; the compose list is built as `audience_scope(Contact.where.not(email: nil)).search(q)`
  (audience filter then search, composing scopes), mirroring
  `PropertySharesController#new` (lines 14-15: `filtered_scope(shareable).search(@query)`).
- The **email-only filter** `.where.not(email: nil)` (recipients must have an email).
- The **per-recipient send loop** shape from `PropertySharesController#create`
  (lines 37-40: `contacts.each { |c| Mailer....deliver }`), swapping `PropertyMailer` →
  `OutgoingEmailMailer`, and the synchronous `deliver_now` → `SendOutgoingEmailJob.perform_later`.
- The **Turbo-Frame list-refresh-on-filter** pattern — copy it from
  **`property_shares/new.html.erb`**, whose filter tabs and search form both target
  the `share_contacts_table` frame for an *in-frame* swap. Do NOT model it on the
  contacts *index*: that uses `data: { turbo_frame: "_top" }` for filter/search
  (full-page navigation), which is the wrong behavior here. The recipient-checkbox +
  email-only + in-frame markup variant lives in `property_shares/new`, so copy from
  there rather than the contacts index.
- The **Active Storage `has_one_attached` convention** — established across the app
  (`PropertyDocument#has_one_attached :file` is the closest precedent, same `:file`
  name; also Article, PropertyImage, Property). Mirror its service config; only the
  ≤ 10 MB byte-size validation is genuinely new (no existing model validates size).
- The **mailer From/Reply-To precedent** from `PropertyMailer` (Reply-To
  `adrien@agencegaremonaco.com`, From inherited from `ApplicationMailer`).
- `Admin::BaseController` (admin layout + French locale), the admin form styling,
  and the flash conventions.

**Reuse opportunistically (implementer's call, don't over-extract):**
- `filtered_scope` (the tiny peers/contacts/all `case` in both
  `PropertySharesController` and `ContactsController`). Compose needs only the
  peers-or-contacts subset, so either extract it into a small shared concern and
  use it, or reimplement as a two-line audience scope — whichever is cleaner. Do
  NOT force a heavyweight refactor of the property-share flow for this.

**Build new (intentionally not reused):**
- The compose view (audience toggle + searchable list + subject/body/attachment).
- `select_all_controller.js` — a *stateless* select-all (toggle currently-listed
  rows), NOT the persisted `share_selection_controller.js`. Single-audience means
  no cross-tab selection to persist, so its persistence behavior is unwanted here.

**Leave untouched (no regression risk):**
- `share_selection_controller.js`, `app/views/admin/property_shares/*`, and
  `PropertySharesController` — the property-share flow is in production and this
  feature changes none of it.

## Design decisions

| Decision | Choice | Rationale |
|---|---|---|
| Recipient handling | Separate email per contact | Discretion among peers; matches existing property-share loop |
| Audience | Single audience per email — toggle Peers / Contacts (default Peers) | Adrien never mixes peers and contacts in one send; removes cross-audience ambiguity |
| Recipient list | Own list on the compose page: audience toggle + search + checkboxes + select-all, ordered by name. No sortable columns. Does NOT reuse the property-share picker | Simpler, fit-for-purpose, and avoids coupling to / changing the existing persisted-selection picker |
| Entry point | Standalone "Envoyer un email" page + sidebar link | Discoverable, self-contained, not tied to a property |
| Body format | Plain text, no branding | Reads like a personal email, not a marketing template |
| From / Reply-To | From agency (`info@agencegaremonaco.com`, display name "Agence Immobilière de la Gare"), Reply-To `adrien@agencegaremonaco.com` | Keeps verified Brevo sender + DKIM; replies reach Adrien. Matches `PropertyMailer` and `ApplicationMailer` default. Display name kept (not personalized to Adrien) for deliverability; the personal tone comes from the plain-text body and the Reply-To |
| Attachment | One optional file, any type, ≤ 10 MB | Covers the stated need; size cap keeps within email limits |
| Delivery | Async via Solid Queue (`deliver_later`-style jobs), no stored history | Instant UX; one failed recipient doesn't block the rest |
| Attachment lifecycle | Active Storage (local disk), auto-purged after last send | Survives the request for background jobs; no disk accumulation |

## User flow

1. Adrien clicks **"Envoyer un email"** in the admin sidebar.
2. The compose page shows an **audience toggle** (Peers / Contacts, default
   Peers), a **search** field, a checkbox list of that audience ordered by name,
   and a **"select all"** checkbox that ticks every row currently listed (i.e.
   the current audience filtered by the current search). Plus **Subject**,
   **Body**, and **Attachment** fields.
3. Adrien picks the audience, optionally searches, selects recipients (or "select
   all"), writes subject + body, and optionally attaches a file.
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
- `new` — renders the compose page (audience toggle + searchable recipient list +
  form). The audience param (`peers` / `contacts`, default `peers`) and search
  term scope the list via the `Contact` `.peers` / `.contacts_only` and `.search`
  scopes; only contacts with an email are listed (`.where.not(email: nil)`),
  ordered by name (`.order(:last_name, :first_name)`). The list re-renders on
  audience/search change (Turbo Frame, like the in-frame refresh in
  `property_shares/new` — NOT the contacts index, which navigates `_top` on
  filter/search). Note: this view deliberately drops sortable columns, so it must
  NOT include the `Sortable` concern (no `sort_scope` / `sort_link`) — just name
  ordering.
- `create` — receives `contact_ids[]` plus the `audience`. Resolves recipients at
  enqueue time: loads the submitted contacts, keeps only those that still exist,
  belong to the submitted audience, and have a non-nil email, then maps each to a
  `(recipient_email, recipient_name)` pair. This is why the model has no Contact
  association — recipients are snapshotted into the jobs. Validates (≥ 1 resolvable
  recipient, subject + body present, attachment within size cap); builds the
  `OutgoingEmail` (`pending_count` = number of resolved recipients); enqueues one
  `SendOutgoingEmailJob` per recipient; flashes and redirects. On validation
  failure, re-renders the form with errors and enqueues nothing. A submitted
  `contact_id` that no longer exists, is out of audience, or whose email became
  nil between page-load and submit is silently dropped (not an error); if that
  leaves zero recipients, it fails the "≥ 1 recipient" validation.

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

### 6. Compose view + select-all controller + sidebar link

- `app/views/admin/outgoing_emails/new.html.erb` — the compose form: audience
  toggle (Peers / Contacts), search field, recipient checkbox list, select-all
  checkbox, and Subject / Body / Attachment fields.
- **Own recipient list, not the property-share picker.** Because a send never
  mixes audiences, the compose page does NOT reuse or extract the property-share
  picker. It renders its own simpler list of one audience at a time (ordered by
  name, `contact_ids[]` checkboxes, only contacts with email). No "Tous" tab, no
  sortable columns, no cross-audience persistence. The existing
  `share_selection_controller.js` and `property_shares/new.html.erb` are left
  **untouched** — this design avoids the rename/coordination risk of sharing that
  controller.
- **Select-all checkbox:** a small Stimulus controller (`select_all_controller.js`)
  whose header checkbox toggles every currently-listed `contact_ids[]` checkbox on
  or off, and reflects an indeterminate/checked state as individual rows are
  toggled. Because the list shows a single audience filtered by search, "select
  all" unambiguously means "everyone currently shown" — there is no hidden
  cross-audience selection to reason about. When the list re-renders (audience or
  search change via Turbo Frame), the controller resyncs the header state to the
  rows then present.
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
- `new` (default) renders the compose form with the Peers audience selected.
- `new?audience=contacts` lists contacts (not peers); search narrows the list.
- The list shows only contacts with an email; peers and contacts don't intermix.
- `new` renders a "select all" checkbox (assert markup / data-attributes in a
  Minitest integration test — no system tests exist: no `test/system/`, no
  `application_system_test_case.rb`, no `driven_by` usage, so select-all's
  client-side toggling is verified via markup, not a browser/JS test).
- `create` (valid, audience=peers) enqueues N jobs (`assert_enqueued_jobs N`),
  flashes, redirects; emails only the resolved peers.
- `create` drops submitted ids that are out of audience / no longer exist / have a
  nil email; if that leaves zero, it fails the "≥ 1 recipient" validation.
- `create` (no recipients / missing subject / missing body / oversized attachment)
  → re-renders with errors, enqueues nothing.

**Sweeper** (`test/jobs/purge_stale_outgoing_emails_job_test.rb`)
- Purges records older than 24h; leaves recent ones.

**No regression to property-share:** this design does not touch the property-share
picker, controller, or `share_selection_controller.js`. Still run the existing
property-share tests as a sanity check, but no changes to them are expected.

## Affected / new files

- New: `app/models/outgoing_email.rb`
- New: `app/controllers/admin/outgoing_emails_controller.rb`
- New: `app/mailers/outgoing_email_mailer.rb` + views (`text` template)
- New: `app/jobs/send_outgoing_email_job.rb`
- New: `app/jobs/purge_stale_outgoing_emails_job.rb`
- New: `app/views/admin/outgoing_emails/new.html.erb` (audience toggle + searchable list + form)
- New: `app/views/admin/outgoing_emails/_recipient_list.html.erb` (Turbo Frame partial re-rendered on audience/search change)
- New: `app/javascript/controllers/select_all_controller.js` (compose-page select-all; property-share controller untouched)
- New migration: `outgoing_emails` table
- Edit: `config/routes.rb` (admin `resources :outgoing_emails, only: [:new, :create]`)
- Edit: `config/recurring.yml` (sweeper schedule)
- Edit: `app/views/layouts/admin.html.erb` (sidebar link)
- Edit: `config/locales/admin.fr.yml` (admin labels/flash)
- New tests as listed above.
