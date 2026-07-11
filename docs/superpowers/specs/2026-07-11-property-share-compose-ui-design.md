# Property Share Page: Compose-Email UI + Message & PDF Attachment

**Date:** 2026-07-11
**Status:** Approved by Laurent (design conversation, 2026-07-11)
**Branch:** `property-share-compose-ui`

## Problem

The admin property share page (`/admin/biens/:id/share/new`) uses a different
recipient-selection UI than the admin compose-email page (`/admin/envoyer-email`):
a tabbed filter (all/contacts/peers) over one large sortable table with no height
limit. The compose page has a better pattern: two stacked, fixed-height,
scrollable recipient lists (peers and contacts) with per-list search, select-all,
and live "selected" chip panels.

The share email is also inflexible: the subject is auto-generated
(`"REF — Titre FR"`), there is no way to add a personal message, and the property
PDF brochure cannot be attached.

## Goals

1. The share page uses the same recipient-picker UI as the compose page,
   implemented by sharing code, not by copying it.
2. The admin can edit the subject, add an optional personal message, and
   optionally attach the property's French PDF brochure with or without the
   agency logo.
3. Sends happen in background jobs, one per recipient, like compose.

## Non-goals

- No locale picker for the attached PDF (French only; the share email itself is
  French only). Can be added later.
- No plain-text share mode: the email stays the branded HTML property card.
- The email preview iframe stays static; it does not live-update with the typed
  message or subject.
- No changes to the compose-email feature's behavior.

## Decisions made during design

| Question | Decision |
|---|---|
| Email format with subject/body | Keep the branded HTML card. Subject prefilled with `"REF — Titre FR"`, editable. Body renders as a personal note block inside the email, above the property card. Empty body means the email looks exactly like today. |
| Delivery | Background jobs, one per recipient, primitive job args. No `OutgoingEmail` record. |
| PDF locale | French only. Options: attach yes/no, logo yes/no. |
| Validation | Subject required (always prefilled so normally valid), body optional. |
| Reuse strategy | Extract a shared recipient-list partial and a controller concern used by both pages (Approach A). |

## Design

### 1. Shared recipient picker

- Move `app/views/admin/outgoing_emails/_recipient_list.html.erb` to
  `app/views/admin/shared/_recipient_list.html.erb`.
- Add two locals to the existing set (`audience`, `frame`, `heading`,
  `selected_target`, `selected_label`, `query`, `query_param`, `recipients`):
  - `url`: where the per-list search form submits
    (compose: `new_admin_outgoing_email_path`;
    share: `new_admin_property_share_path(@property)`).
  - `form_id`: the id of the empty compose/share form the row checkboxes attach
    to via the `form:` attribute (compose: `"compose_form"`;
    share: `"share_form"`). Checkboxes cannot be wrapped by that form because
    each list contains its own search `<form>` and forms may not nest.
- Move the generic labels the partial hardcodes from `admin.outgoing_emails.*`
  to a shared `admin.recipient_picker.*` namespace in `admin.fr.yml`:
  `search_placeholder`, `select_all`, `no_results`, `selected.none`,
  `selected.remove`, `selected.peers`, `selected.contacts`, and the section
  headings (`sections.peers`, `sections.contacts`). Both pages read from the
  shared namespace; page-specific strings stay in their own namespaces.
- The `recipient-selection` Stimulus controller
  (`app/javascript/controllers/recipient_selection_controller.js`) is reused
  unchanged. Frame ids on the share page: `share_peers`, `share_contacts`
  (compose keeps `compose_peers`, `compose_contacts`).

### 2. Controller concern

Extract from `Admin::OutgoingEmailsController` into
`app/controllers/concerns/admin/recipient_loading.rb`:

- `load_recipients`: sets `@peers_query`/`@contacts_query` from
  `params[:peers_q]`/`params[:contacts_q]` and loads `@peers` (peers scope) and
  `@contacts` (contacts-only scope), each `with_email`, searched by its own
  term, ordered by `last_name, first_name`.
- `resolve_recipient_contacts`: resolves submitted `contact_ids[]` to the
  existing, email-bearing contacts, `.distinct`, silently dropping blank or
  stale ids. Returns a relation of `Contact` records. Compose keeps its
  email-list behavior by plucking `:email` from this relation; share iterates
  the records.

Both controllers include the concern. `Admin::PropertySharesController` drops
`Sortable`, `SORT_COLUMNS`, the filter/counts logic, and its old
`filtered_scope`.

### 3. Share form and controller flow

- New non-persisted form object `PropertyShare`
  (`app/models/property_share.rb`): `ActiveModel::Model` +
  `ActiveModel::Attributes` with `subject` (string), `body` (string),
  `attach_pdf` (boolean, default false), `include_logo` (boolean, default
  true). Validates `subject` presence. Exists so the view renders
  `errors.full_messages` in the same red error box as compose.
- `Admin::PropertySharesController#new`: `load_recipients`; build
  `@property_share` with subject prefilled to
  `"#{@property.reference} — #{@property.title_for(:fr)}"`; keep
  `@email_preview` (unchanged `PropertyMailer.share_property(@property, nil)`).
- `#create`: build `@property_share` from params
  (`params.require(:property_share).permit(:subject, :body, :attach_pdf, :include_logo)`).
  - Zero resolved recipients: add a base error, re-render `:new` with 422
    (replaces today's redirect+alert).
  - Invalid form object (blank subject): re-render `:new` with 422.
  - Valid: for each contact, enqueue
    `SharePropertyEmailJob.perform_later(property.id, contact.id, subject, body, attach_pdf, include_logo)`;
    redirect to `admin_contacts_url` with the existing
    "shared with N contacts" notice.

### 4. Background job

`app/jobs/share_property_email_job.rb`:

```ruby
SharePropertyEmailJob.perform(property_id, contact_id, subject, body, attach_pdf, include_logo)
```

- `Property.find_by` / `Contact.find_by`; return silently if either record was
  deleted between enqueue and run.
- Calls the mailer with `deliver_now`.
- One job per recipient so a single failure never blocks other recipients
  (same rationale as `SendOutgoingEmailJob`).

### 5. Mailer and template

- `PropertyMailer.share_property(property, contact, subject: nil, body: nil,
  attach_pdf: false, include_logo: true)`:
  - `subject:` falls back to the current auto subject
    (`"#{property.reference} — #{property.title_for(:fr)}"`) when blank, so the
    preview call `share_property(@property, nil)` is unchanged.
  - When `attach_pdf` is true, attach
    `PropertyBrochureCache.fetch(property, locale: :fr, include_logo: include_logo)`
    as `property.brochure_filename` with mime type `application/pdf`. The cache
    already falls back to synchronous generation for uncached properties.
- `app/views/property_mailer/share_property.html.erb`: when
  `@personal_message` is present, render it between the agent block and the
  hero image as an HTML-escaped block with newlines preserved as `<br>`,
  inline-styled to match the email (Arial, ink color, email-client-safe table
  markup).

### 6. New share page layout (top to bottom)

1. Page title plus a one-line property context (reference and French title).
2. Empty `form_with url: admin_property_share_path(@property), id: "share_form"`
   (fields associate by `form:` attribute, same nested-form workaround as
   compose).
3. Error box (same markup/style as compose) when the form object has errors.
4. `div data-controller="recipient-selection"` wrapping two renders of the
   shared partial: Confrères section, then Contacts section. Each has its own
   Turbo Frame, search field, `max-h-80` scrollable name+email table with
   sticky header and select-all, and a chip panel. Tabs, counts, sort links,
   and the company/phone/city/country columns are removed.
5. White card: Objet text field (prefilled), Message textarea (optional),
   "Joindre la brochure PDF" checkbox, "Inclure le logo" checkbox (checked by
   default, only honored when attach is ticked; no JS to disable it).
6. Envoyer / Annuler buttons (cancel keeps pointing at `admin_contacts_path`).
7. Existing email preview iframe, unchanged.

### 7. i18n

In `config/locales/admin.fr.yml`:

- New `admin.recipient_picker.*` namespace (moved keys, see section 1);
  compose keys that moved are deleted from `admin.outgoing_emails.*`.
- New keys under `admin.property_shares.*`: field labels (subject, body,
  attach PDF, include logo), the no-recipients base error, property context
  label. Obsolete share-only keys (e.g. `select_column`) are removed if no
  longer referenced.

## Error handling

- Blank subject or zero recipients: 422 re-render of `:new` with the red error
  box; recipient lists and typed fields are re-rendered.
- Stale contact ids (deleted between page load and submit) are silently
  dropped; if that leaves zero, it is treated as "no recipients selected".
- Job-level: deleted property or contact makes the job a silent no-op; mailer
  errors follow default job retry behavior, isolated per recipient.

## Testing (TDD, red-green-refactor)

- **Share controller `#new`:** renders both stacked sections; `peers_q`
  narrows only the peers list and `contacts_q` only the contacts list; subject
  prefilled with reference and French title; preview still rendered.
- **Share controller `#create`:** enqueues one `SharePropertyEmailJob` per
  selected contact with the right args; duplicate/blank/stale ids handled;
  blank subject 422s; zero recipients 422s; success redirects with notice.
- **Mailer:** custom subject used; blank subject falls back to auto subject;
  personal note rendered, HTML-escaped, with line breaks; note absent when
  body blank; PDF attached with correct filename for both logo variants
  (stub `PropertyBrochureCache.fetch`); no attachment by default.
- **Job:** delivers the email; silent no-op when property or contact is gone.
- **Compose regression:** the existing outgoing-emails controller/system tests
  guard the partial and concern extraction; they are updated only where moved
  i18n keys are referenced.
- Existing share controller tests asserting tabs/sort/columns are rewritten to
  the new UI.
