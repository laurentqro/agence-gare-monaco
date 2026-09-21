# EN security article rewrite with a localized slug and a translator lock

Date: 2026-09-21
Status: approved design

## Problem

The English security article lost almost all of its search visibility in the
site migration. The legacy URL
`www.agencegaremonaco.com/en/article/15/everything-about-security-and-health-in-monaco`
earned 22.9k impressions over 16 months, ranking around position 8 for
"monaco police" and "is monaco safe". Its replacement,
`/en/articles/la-securite-et-la-sante-a-monaco`, is indexed with the correct
canonical, yet earns about 180 impressions a week across all locales and 3
impressions in total for "is monaco safe". The redirects are correct (audited
2026-09-18); the page itself no longer competes for the queries it used to own.

Two things hold the page back:

1. The English text is a machine translation of the French article, titled
   "Safety and Healthcare in Monaco", and does not target the queries.
2. The URL carries the French slug under `/en/`.

Two constraints shape the fix:

- The admin form is French-only, and `ArticleTranslator` rewrites every
  non-French locale whenever the French title, body or meta description
  changes. Any hand-written English would be silently overwritten on the next
  French edit. The valuation article's hand-authored EN title and meta
  (`articles:optimise_valuation_snippet`) already live with this risk.
- PR 135 (`localise-article-slugs`) already implements per-locale slugs:
  `articles.slugs` JSON column, `Article#slug_for`,
  `Article.find_by_localized_slug`, collision-aware minting, a 301 from a
  non-canonical slug to the locale's canonical URL, and per-locale slugs in
  the canonical tag, hreflang alternates, locale switcher, sitemap, legacy
  redirects and internal links. Its backfill task would move every article's
  URL in every translated locale, which is more churn than wanted during the
  current dip.

## Decisions taken with the owner

- Only the EN security article's URL moves now (`/en/articles/is-monaco-safe`).
- PR 135 is merged as the base. Its backfill task is not run in production.
  Its auto-minting stays: other articles gain localized slugs gradually, when
  the translator next writes a translation for a locale that has no slug yet.
- The hand-written English is edited in the admin, protected by a per-locale
  lock that the translator respects.
- Title: "Is Monaco Safe? Police, Security and Healthcare in the Principality".
  Slug: `is-monaco-safe`.

## Design

### 1. Merge PR 135 into master

`origin/localise-article-slugs` merges into local master with two conflicts:

- `db/schema.rb`: both sides added columns; keep both and the later
  migration version.
- `app/controllers/legacy_redirects_controller.rb`: master has the
  single-hop FR redirect (commit 94f3997, identical patch to the branch's
  aeea1a6); the branch's later commit makes the target use
  `article.slug_for(locale)`. The merged result keeps the single hop and the
  per-locale slug.

The first two branch commits are the same patches as the two commits on
local master, so git treats them as already applied. The unused `slugs`
column currently in the development database came from this branch's
migration and lines up once merged. No production data changes at this step.

### 2. Locked locales

New column `articles.locked_locales`, JSON array, default `[]`, not null.

Model:

- `Article#locked_locale?(locale)` returns true when the locale string is in
  the array.
- `translated_count` counts a locked locale as complete, so
  `translation_status` reports `:complete` for an article whose only missing
  translation is a locked, hand-written locale.

Translator: `translate_locale!` returns before any LLM call when the locale
is locked, and leaves that locale's title, body, meta description, slug and
`translations_status` entry untouched. Unlocked locales behave exactly as
today. `finalize!` still pins the source hash, so a locked article does not
re-run on every save.

### 3. Admin: English section on the edit form

Shown only for a persisted article, inside a collapsed `<details>` block
labelled in French ("Version anglaise"). The "new" form stays French-only.

Fields:

- `article[title][en]` text input
- `article[body][en]` plain markdown textarea (no second markdown editor
  instance; the editor's single-instance tests stay valid)
- `article[meta_description][en]` textarea, maxlength 160
- `article[slugs][en]` text input
- `article[locked_locales][]` checkbox with value `en`, labelled "Texte
  rédigé à la main, ne pas retraduire", using the multiple-checkbox pattern so
  an unchecked box submits an empty array and unlocks.

Controller (`Admin::ArticlesController#article_params`):

- Permit `title: [:fr, :en]`, `body: [:fr, :en]`, `meta_description:
  [:fr, :en]`, `slugs: [:en]`, `locked_locales: []`.
- Drop blank submitted EN values before merging, so an empty EN box never
  wipes an existing machine translation. FR handling is unchanged.
- Merge `title`, `body`, `meta_description` and `slugs` into the stored
  hashes through `MergesTranslatedColumns` (`slugs` joins
  `TRANSLATED_COLUMNS`). This is the merge-not-assign rule from the
  2026-07-20 data-loss postmortem.
- `locked_locales` is assigned after rejecting blanks.

Model validation on `slugs`: every value matches
`/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/` and is not taken by another article in any
locale (reuse the PR's `localized_slug_taken?`). Errors render on the form
like existing ones.

Saving the form still calls `enqueue_post_save_jobs!`; the translator then
skips EN because it is locked, and skips the whole article when the French
hash is unchanged.

### 4. Content: rake task `articles:rewrite_security_article_en`

Follows `articles:optimise_valuation_snippet`. Finds the article by
`legacy_id: 15`, aborts if missing. Writes, via `update_columns` so no
callback fires:

- `title["en"]` = "Is Monaco Safe? Police, Security and Healthcare in the
  Principality"
- `body["en"]` = a new markdown article of roughly 900 words: a short direct
  answer; police and the Carabiniers du Prince (one officer per hundred
  residents, as the French text states); video surveillance and building
  security; rules of conduct; the healthcare system (Caisses Sociales de
  Monaco, public and private sectors) and facilities (Princess Grace
  Hospital, Cardio-Thoracic Centre, Haemodialysis Centre, IM2S, pharmacies,
  general practitioners); an FAQ answering "Does Monaco have its own police
  force?", "Is healthcare free in Monaco?", "Is Monte Carlo safe at night?"
  and "How safe is Monaco compared with France?". Facts stay within what the
  French article claims plus established public figures; no invented
  statistics.
- `meta_description["en"]`, at most 160 characters.
- `slugs["en"]` = `is-monaco-safe`.
- `locked_locales` gains `"en"`.

Other locales are untouched. The task is idempotent: unchanged data prints
"unchanged" and writes nothing. If `slugs["en"]` already holds a different
value, the task keeps that value, prints a warning naming it, and still
writes the title, body, meta description and lock.

### 5. Rollout

1. Deploy master.
2. Run the task once in production.
3. Verify with curl that
   `/en/articles/la-securite-et-la-sante-a-monaco` and
   `/en/article/15/anything` each 301 in one hop to
   `/en/articles/is-monaco-safe`, and that the new URL returns 200 with a
   self canonical and the EN title.
4. Request indexing of the new URL in Search Console. Re-pull the GSC
   comparison around 2026-10-20.

## Testing (test-first)

- Model: `locked_locale?`; `translated_count` and `translation_status` treat
  a locked locale as complete; `slugs` format and cross-locale uniqueness
  validation.
- Translator: a locked locale is skipped without an LLM call and its fields
  survive a French edit; unlocked locales are still translated; the source
  hash is pinned afterwards.
- Admin controller: edit form shows the EN section, new form does not; update
  merges EN title, body, meta and slug without touching other locales; blank
  EN fields leave existing values alone; lock checkbox sets and clears
  `locked_locales`; invalid EN slug re-renders with an error.
- Rake task: sets title, body, meta, slug and lock; meta within 160 chars;
  other locales unchanged; idempotent; does not overwrite a hand-set EN slug;
  no translation job enqueued.
- Full suite green after the merge and after each step.

## Out of scope

- Running the PR 135 backfill in production.
- Locking the valuation article's EN copy (same mechanism, separate decision).
- A second markdown editor instance for the EN body.
- Localized slugs or hand-written copy for other locales.
