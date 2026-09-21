# Per-locale SEO Overrides and the EN security article

Date: 2026-09-21
Status: approved design (revised after grilling; supersedes the first draft)

Terms used here are defined in `CONTEXT.md` under "Articles and Translations":
Source, Translation, SEO Override, Localized Slug.

## Problem

The English security article lost almost all of its search visibility in the
site migration. The legacy URL
`www.agencegaremonaco.com/en/article/15/everything-about-security-and-health-in-monaco`
earned 22.9k impressions over 16 months, ranking around position 8 for
"monaco police" and "is monaco safe". Its replacement,
`/en/articles/la-securite-et-la-sante-a-monaco`, is indexed with the correct
canonical, yet earns about 180 impressions a week across all locales and 3
impressions in total for "is monaco safe". The redirects are correct (audited
2026-09-18); the page no longer competes for the queries it used to own.

What holds the page back is what Google shows and links: the title "Safety and
Healthcare in Monaco" and the snippet do not target the queries, and the URL
carries the French slug under `/en/`.

The underlying need is general: the agency wants to override a translated
title (and snippet, and URL) for SEO in any locale, without the translator
overwriting it. The valuation article's hand-authored EN title and meta
(`articles:optimise_valuation_snippet`) were written straight into the
translated columns and will be overwritten on the next French edit.

Two constraints:

- The admin form is French-only and `ArticleTranslator` rewrites every
  non-French locale's title, body and meta description whenever the Source
  changes.
- PR 135 (`localise-article-slugs`) already implements Localized Slugs:
  `articles.slugs` JSON column, `Article#slug_for`,
  `Article.find_by_localized_slug`, collision-aware minting, a 301 from a
  non-canonical slug to the locale's canonical URL, and per-locale slugs in
  the canonical tag, hreflang alternates, locale switcher, sitemap, legacy
  redirects and internal links. Its backfill task would move every article's
  URL in every translated locale at once.

## Decisions taken with the owner

- The body stays a Translation. Content improvements (a police section, an
  FAQ) are made in the French Source through the admin and translated as
  usual. No hand-written English body, no translator lock.
- An SEO Override covers title, meta description and slug, per locale, stored
  separately from the translated values so the translator never touches it.
  The title override replaces both the tag title and the H1.
- The admin edit form gets override fields for all eight non-French locales.
- PR 135 is merged as the base. Its backfill task is not run in production,
  so only the security article's URL moves now. Its auto-minting stays:
  other articles gain Localized Slugs when the translator next writes a
  translation for a locale that has none.
- No rake task. After deploy, the owner enters the EN override (title
  "Is Monaco Safe? Police, Security and Healthcare in the Principality",
  meta description, slug `is-monaco-safe`) and the French body additions in
  the admin. The drafts are delivered with the finished work.
- Work happens on a feature branch (`seo-overrides`), one commit per task,
  merged to master at the end.

## Design

### 1. Merge PR 135 into the feature branch

`origin/localise-article-slugs` merges into master with two conflicts:

- `db/schema.rb`: both sides added columns; keep both and the later
  migration version.
- `app/controllers/legacy_redirects_controller.rb`: master has the
  single-hop FR redirect (commit 94f3997, identical patch to the branch's
  aeea1a6); the branch's later commit makes the target use
  `article.slug_for(locale)`. Keep the single hop and the per-locale slug.

The first two branch commits are the same patches as the two commits on
local master, so git treats them as already applied. Any further conflict is
resolved conservatively, preserving both sides' intent. The unused `slugs`
column in the development database came from this branch's migration and
lines up once merged. No production data changes at this step.

While here, `Article.find_by_localized_slug` scans every article with
`find_each` on each request; replace it with the `json_extract` lookup the
PR already uses in `localized_slug_taken?`, falling back to the French slug.

### 2. SEO Override storage and reads

New JSON columns on articles, default `{}`, not null:
`title_overrides` and `meta_description_overrides`, keyed by locale. The
slug override is PR 135's `slugs` column; no new column for it.

Model:

- `title_for(locale)` returns `title_overrides[locale]` when present, else
  the existing translated-then-French fallback. Same for
  `meta_description_for`. Once PR 135 is merged (step 1), every page title,
  H1, canonical, hreflang, sitemap and card goes through these readers or
  `slug_for`, so no view changes. (On pre-merge master several of them still
  read the raw `slug` column; PR 135 is what fixes that.)
- `seo_override?(locale)` is true when any of the three has a value for that
  locale (used by the form to show state, nothing else).
- Validation on `slugs`: every value matches
  `/\A[a-z0-9]+(?:-[a-z0-9]+)*\z/` and is not taken by another article in
  any locale (PR 135's `localized_slug_taken?`). Meta description overrides
  are at most 160 characters.

The translator is unchanged: it keeps writing `title`, `body`,
`meta_description` and minting `slugs` for locales that have none. It never
reads or writes the override columns. `translated_count` and
`translation_status` are unchanged.

### 3. Admin: "Surcharges SEO" section on the edit form

Shown only for a persisted article, inside a collapsed `<details>` block.
The "new" form stays French-only. One sub-block per non-French locale
(`Article::TARGET_LOCALES`), each with:

- `article[title_overrides][<locale>]` text input, placeholder showing the
  current translated title
- `article[meta_description_overrides][<locale>]` textarea, maxlength 160,
  placeholder showing the current translated meta description
- `article[slugs][<locale>]` text input, value = current Localized Slug if
  any, placeholder showing the French slug

Controller (`Admin::ArticlesController#article_params`):

- Permit `title_overrides`, `meta_description_overrides` and `slugs` for
  every target locale.
- Merge each into the stored hash through `MergesTranslatedColumns` (the
  merge-not-assign rule from the 2026-07-20 postmortem), then drop blank
  values from the merged hash, not from the submitted one: a field submitted
  empty overwrites the stored key and is then removed, so clearing a field
  removes that override and the page falls back to the Translation. A cleared slug field removes the
  Localized Slug, so the locale is served under the French slug again and
  PR 135's 301 handles the old URL.
- FR handling is unchanged.

Saving still calls `enqueue_post_save_jobs!`; the translator skips the
article when the French hash is unchanged.

### 4. Rollout

1. Merge the feature branch to master and deploy.
2. In the admin, on the security article: set the EN title override, EN meta
   description override (under 160 characters) and EN slug `is-monaco-safe`;
   append the French police section and FAQ to the body. The translator
   regenerates the eight body Translations.
3. Verify with curl that `/en/articles/la-securite-et-la-sante-a-monaco` and
   `/en/article/15/anything` each 301 in one hop to
   `/en/articles/is-monaco-safe`, and that the new URL returns 200 with a
   self canonical and the override title in both `<title>` and `<h1>`.
4. Request indexing of the new URL in Search Console. Re-pull the GSC
   comparison around 2026-10-20.

## Testing (test-first)

- Model: `title_for` and `meta_description_for` prefer the override and
  fall back when absent or blank; `slugs` format and cross-locale uniqueness
  validation; meta override length; `find_by_localized_slug` resolves a
  Localized Slug and a French slug without scanning.
- Translator: a French edit leaves `title_overrides`,
  `meta_description_overrides` and an existing `slugs` value untouched while
  rewriting the translated columns.
- Admin controller: edit form shows the section with a block per target
  locale, new form does not; update merges one locale's overrides without
  touching other locales' values; blank fields clear that locale's override
  only; invalid slug re-renders with an error.
- SEO helper and page: `<title>`, `<h1>`, canonical and hreflang use the
  override title and Localized Slug for that locale, and the translated
  values for the others.
- Full suite green after the merge and after each task.

## Out of scope

- Running the PR 135 backfill in production.
- Migrating the valuation article's EN title and meta into overrides (same
  mechanism; a follow-up with its own decision).
- Overriding the body, or any translator lock.
- An indicator that the Source changed after an override was written.
