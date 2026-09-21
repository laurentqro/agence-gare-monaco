# Context: Agence Gare Monaco

Glossary of domain terms. This file is a glossary and nothing else — no
implementation details, no specs, no decisions (those live in `docs/adr/`).

## Sanctions Screening (Gel des Fonds)

The agency's AML control: screening clients against Monaco's national
asset-freeze list ("liste nationale des gels" / "gel des fonds").

- **Sanction Measure** — one entry on Monaco's official national asset-freeze
  list (a `mesure` in the gov API): a sanctioned person or entity the agency is
  legally required to screen against. The authoritative list is published by the
  Monaco government; the app mirrors it locally.

- **Withdrawal** — a Sanction Measure ceasing to be in force. Monaco sometimes
  marks this explicitly and sometimes simply stops publishing the measure, so
  withdrawal is inferred from observation as well as read from the list. A
  withdrawn measure is never removed from the mirror: it stops being screened
  against, but remains resolvable so that earlier decisions still explain
  themselves.

- **In Force** — the subset of mirrored Sanction Measures currently published by
  the government. Screening runs against measures in force; the mirror retains
  every measure ever published. "On the list" always means in force; "in the
  mirror" means we hold a record of it.

- **Roster** — the set of contacts the agency screens against the list. *Who* we
  check. Not every contact is necessarily on the roster; membership is a
  deliberate (if usually automatic) act.

- **Potential Match** — a machine-generated hit: a roster contact whose name
  resembles a Sanction Measure, awaiting human judgment. The matcher emits
  *potential matches*. A potential match is `pending` until a human reviews it,
  then `confirmed` or `dismissed` — though a dismissal can be reopened when the
  Evidence changes.

- **Dismissal** — a human judgment that a potential match is not a real hit. It
  is a judgment about a specific body of Evidence, not a permanent property of
  the contact/measure pair: when the Evidence is superseded, the dismissal no
  longer covers what is in front of us and the potential match reopens as
  `pending`. Reopening is not an override of the reviewer.

- **Evidence** — what a review decision rested on: the contact's screened name
  and birth date, the Sanction Measure it was matched against, and the Score.
  Recorded on the potential match so that a later screening run can tell whether
  the basis of an earlier judgment still holds.

- **Match** (bare word) — reserved for a *confirmed* potential match: a real hit
  where a human has judged the roster contact to genuinely be the sanctioned
  party. Never use "match" in prose or UI for an unreviewed hit — that is a
  *potential match*.

- **Screening** — the act of running the roster against the list to produce
  potential matches. ("A screening run.")

- **Publication** — a dated release of the national list by the Monaco
  government, issued on ministerial decision rather than on a fixed calendar. The
  agency screens in response to a publication, not on a schedule of its own: a
  new publication is what makes the roster stale.

- **Score** — the matcher's confidence, from 0 to 1, that a roster contact and a
  Sanction Measure are the same party. It ranks the review queue and is recorded
  on the potential match, but it never decides anything on its own: only a human
  turns a potential match into a confirmed one.

- **Notification** — an email prompting the reviewer that potential matches
  await review. It is a prompt, never the control: it carries a count and a link
  into the admin, never a finding. What a client is suspected of resembling is
  visible only behind an authenticated session.

- **Screened Identity** — one of the two name-identities a roster contact is
  screened under: its *person identity* (first + last name) or its *company
  identity* (company name). A single contact can have both, screened separately,
  and can therefore produce two distinct potential matches. Which identity fired
  is recorded on the potential match.

- **Unscreenable Contact** — a roster contact with neither a person identity nor
  a company identity (it is identified only by phone or email). It is a member of
  the roster like any other, but a screening run yields no potential matches for
  it. This is a data-quality gap, not an exemption: the agency has undertaken to
  screen the person and cannot, because it has not recorded who they are.

## Articles and Translations

The agency's blog. Every article is written once in French and published in
nine locales.

- **Source** — an article's French text: title, body and meta description. The
  only text the agency writes for every article, and the text every Translation
  is derived from.

- **Translation** — one locale's text produced by the translator from the
  Source. It follows the Source: when the Source changes, the Translation is
  regenerated. A Translation is never edited by hand.

- **SEO Override** — a per-locale title, meta description or slug written by a
  person for search results, shown in place of the Translation's value when
  present. It does not follow the Source and the translator never writes it;
  the body underneath stays a Translation.
  _Avoid_: authored version, locked locale, manual translation

- **Localized Slug** — one locale's URL slug for an article. Set once, either
  minted from the Translation's title or written by hand as an SEO Override,
  and never regenerated afterwards, so an indexed URL does not move. A locale
  without one is served under the French slug.
