# Per-locale SEO Overrides Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let the agency override an article's translated title, meta description and URL slug per locale from the admin, so the EN security article can target "is monaco safe" without the translator undoing it.

**Architecture:** PR 135 (`origin/localise-article-slugs`) is merged first as the base; it brings the `slugs` JSON column, `Article#slug_for`, and per-locale URLs everywhere. Two new JSON columns, `title_overrides` and `meta_description_overrides`, sit beside the translated `title` / `meta_description` hashes. `title_for` and `meta_description_for` read the override first, so every page title, H1, snippet, canonical, hreflang and sitemap entry picks it up with no view changes. The translator never reads or writes the override columns. The admin edit form gets a collapsed "Surcharges SEO" section with three fields per non-French locale; the controller merges each submitted hash into the stored one and drops blank values, so clearing a field removes that override.

**Tech Stack:** Rails 8.1, SQLite (JSON columns via `json_extract`), Minitest, ERB admin views, French-only admin (`admin.fr.yml`).

**Spec:** `docs/superpowers/specs/2026-09-21-en-security-article-rewrite-design.md`. Terms (Source, Translation, SEO Override, Localized Slug) are defined in `CONTEXT.md` under "Articles and Translations".

**Working rules for every task:**
- TDD: write the failing test, run it and see it fail, implement, run it and see it pass, then commit. Never skip the red step.
- One commit per task on the `seo-overrides` branch. No `Co-Authored-By` lines. No em dashes in commit messages or comments.
- Run a single test file with `bin/rails test <file>`; a single test with `bin/rails test <file> -n "/part of the test name/"`.
- The working tree has two unrelated uncommitted files (`lib/kamal_docker_config.rb`, `test/lib/kamal_docker_config_test.rb`). Leave them alone; do not stage them, do not commit them.

---

## File structure

| File | Responsibility |
|---|---|
| `db/migrate/20260921100000_add_seo_overrides_to_articles.rb` (create) | Adds `title_overrides` and `meta_description_overrides` JSON columns |
| `db/schema.rb` (modify) | Merge from PR 135 (`slugs`), then the two new columns |
| `app/models/article.rb` (modify) | Override-aware readers, `seo_override?`, override validations, indexed `find_by_localized_slug` |
| `app/controllers/admin/articles_controller.rb` (modify) | Permit, merge and blank-drop the three override hashes |
| `app/views/admin/articles/_form.html.erb` (modify) | Collapsed "Surcharges SEO" section on the edit form |
| `config/locales/admin.fr.yml` (modify) | French labels for the section and French validation messages |
| `app/controllers/legacy_redirects_controller.rb` (merge conflict) | Keep single-hop FR redirect and `slug_for(locale)` |
| `test/models/article_test.rb` | Reader, validation, defaults and lookup tests |
| `test/services/article_translator_test.rb` | Translator leaves overrides untouched |
| `test/controllers/admin/articles_controller_test.rb` | Form section, merge, blank-drop, invalid slug |
| `test/controllers/articles_controller_test.rb` | Page shows override title/meta and localized slug |

---

### Task 1: Create the feature branch and merge PR 135

**Files:**
- Modify: `db/schema.rb` (conflict on the version line only)
- Modify: `app/controllers/legacy_redirects_controller.rb` (conflict in `#article`)
- Everything else auto-merges (verified on 2026-09-21 in a scratch worktree: 1926 runs, 0 failures after resolution).

- [ ] **Step 1: Drop the stray local schema change, then branch**

`db/schema.rb` in the working tree carries an uncommitted `t.json "slugs"` line left by running PR 135's migration locally. The merge below brings exactly that line, so discard the local copy:

```bash
cd /Users/laurentcurau/projects/agence_gare_monaco
git diff --stat db/schema.rb          # expect: 1 file changed, 1 insertion
git checkout -- db/schema.rb
git status --short                    # expect only the two kamal files + untracked docs
git checkout -b seo-overrides master
```

- [ ] **Step 2: Merge PR 135**

```bash
git fetch origin localise-article-slugs
git merge --no-ff origin/localise-article-slugs
```

Expected: `CONFLICT (content): Merge conflict in db/schema.rb` and `CONFLICT (content): Merge conflict in app/controllers/legacy_redirects_controller.rb`. `git status --short` shows `UU` for those two files and `M`/`A` for about twenty others.

- [ ] **Step 3: Resolve `db/schema.rb`**

The only conflict is the version line near the top. Replace the whole conflict block:

```ruby
<<<<<<< HEAD
ActiveRecord::Schema[8.1].define(version: 2026_09_18_111352) do
=======
ActiveRecord::Schema[8.1].define(version: 2026_08_17_120000) do
>>>>>>> origin/localise-article-slugs
```

with the later version (master's):

```ruby
ActiveRecord::Schema[8.1].define(version: 2026_09_18_111352) do
```

Confirm the merged `articles` table contains both `t.json "slugs", default: {}, null: false` (from the branch) and nothing else conflicting:

```bash
grep -c '<<<<<<<\|>>>>>>>' db/schema.rb      # expect 0
grep -n 't.json "slugs"' db/schema.rb        # expect one line inside create_table "articles"
```

- [ ] **Step 4: Resolve `app/controllers/legacy_redirects_controller.rb`**

Inside `def article`, replace the conflict block:

```ruby
<<<<<<< HEAD
      redirect_to "#{prefix}/#{articles_segment}/#{article.slug}", status: :moved_permanently
=======
      redirect_to "#{prefix}/#{articles_segment}/#{article.slug_for(locale)}", status: :moved_permanently
>>>>>>> origin/localise-article-slugs
```

with the branch side, which keeps master's single hop (`prefix` is `""` for FR) and adds the per-locale slug:

```ruby
      redirect_to "#{prefix}/#{articles_segment}/#{article.slug_for(locale)}", status: :moved_permanently
```

The resolved action must read exactly:

```ruby
  def article
    locale = params[:locale]
    article = Article.published.find_by(legacy_id: params[:id])
    if article
      prefix = locale == "fr" ? "" : "/#{locale}"
      articles_segment = I18n.t("routes.articles", locale: locale)
      redirect_to "#{prefix}/#{articles_segment}/#{article.slug_for(locale)}", status: :moved_permanently
    else
      head :gone
    end
  end
```

```bash
grep -c '<<<<<<<\|>>>>>>>' app/controllers/legacy_redirects_controller.rb   # expect 0
```

- [ ] **Step 5: Bring the databases up to date and run the full suite**

```bash
bin/rails db:migrate            # no-op for development if the slugs migration already ran; still re-dumps schema.rb
git diff db/schema.rb           # expect no change beyond the resolution above; if the dump reordered nothing, fine
bin/rails db:test:prepare
bin/rails test
```

Expected: `1926 runs, ... 0 failures, 0 errors, 0 skips` (count may differ by a few if master moved; failures must be 0).

- [ ] **Step 6: Commit the merge**

```bash
git add db/schema.rb app/controllers/legacy_redirects_controller.rb
git status --short              # the two kamal files must still show as unstaged " M"; do not add them
git commit -m "Merge origin/localise-article-slugs into seo-overrides

Per-locale article slugs (PR 135) become the base for SEO overrides.
Conflicts: keep master's schema version; keep the single-hop FR legacy
redirect and target the per-locale slug."
```

---

### Task 2: Replace the `find_by_localized_slug` table scan with indexed lookups

**Files:**
- Modify: `app/models/article.rb` (`self.find_by_localized_slug`, around line 71)
- Test: `test/models/article_test.rb`

- [ ] **Step 1: Write the failing test**

Add after the existing test `"find_by_localized_slug scopes to the relation it is called on"` in `test/models/article_test.rb`:

```ruby
  test "find_by_localized_slug looks the slug up with a WHERE clause instead of scanning every article" do
    3.times do |i|
      Article.create!(
        title: { "fr" => "Titre #{i}", "en" => "Title #{i}" }, body: { "fr" => "Corps" },
        slug: "titre-#{i}", slugs: { "en" => "title-#{i}" },
        category: @category, published: true
      )
    end

    selects = []
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      selects << payload[:sql] if payload[:sql].start_with?("SELECT") && payload[:name] != "SCHEMA"
    end
    found = Article.find_by_localized_slug("title-1", :en)
    ActiveSupport::Notifications.unsubscribe(subscriber)

    assert_equal "titre-1", found.slug
    assert_equal 1, selects.size, selects.join("\n")
    assert_match(/WHERE/, selects.first, "expected an indexed lookup, got a table scan")
  end
```

- [ ] **Step 2: Run it and watch it fail**

```bash
bin/rails test test/models/article_test.rb -n "/WHERE clause instead of scanning/"
```

Expected: FAIL. The current `find_each` scan issues `SELECT "articles".* FROM "articles" ORDER BY "articles"."id" ASC LIMIT ?` with no `WHERE`, so the `assert_match(/WHERE/...)` fails.

- [ ] **Step 3: Implement the lookup**

In `app/models/article.rb`, replace the whole `self.find_by_localized_slug` method (comment included) with:

```ruby
  # Resolve a URL slug back to its article for the given locale. Matches the
  # locale's own slug first, then the canonical FR slug so previously-indexed
  # shared-slug URLs (one slug across all locales) still resolve. At most two
  # indexed lookups; never a table scan. Respects the relation it is called on
  # (e.g. Article.published).
  def self.find_by_localized_slug(slug_param, locale = I18n.locale)
    unless locale.to_s == I18n.default_locale.to_s
      match = find_by("json_extract(slugs, ?) = ?", "$.#{locale}", slug_param)
      return match if match
    end
    find_by(slug: slug_param)
  end
```

- [ ] **Step 4: Run the model tests**

```bash
bin/rails test test/models/article_test.rb -n "/find_by_localized_slug/"
```

Expected: 5 runs, 0 failures (the four PR 135 tests still pass, plus the new one).

- [ ] **Step 5: Commit**

```bash
git add app/models/article.rb test/models/article_test.rb
git commit -m "Look up localized article slugs with json_extract instead of a scan"
```

---

### Task 3: Add the `title_overrides` and `meta_description_overrides` columns

**Files:**
- Create: `db/migrate/20260921100000_add_seo_overrides_to_articles.rb`
- Modify: `db/schema.rb` (generated)
- Test: `test/models/article_test.rb`

- [ ] **Step 1: Write the failing test**

Add after the existing test `"slugs defaults to an empty hash"` in `test/models/article_test.rb`:

```ruby
  test "title_overrides and meta_description_overrides default to empty hashes" do
    article = Article.create!(
      title: { "fr" => "Titre" }, body: { "fr" => "Corps" },
      slug: "titre-defaults", category: @category
    )
    article.reload
    assert_equal({}, article.title_overrides)
    assert_equal({}, article.meta_description_overrides)
  end
```

- [ ] **Step 2: Run it and watch it fail**

```bash
bin/rails test test/models/article_test.rb -n "/default to empty hashes/"
```

Expected: ERROR `NoMethodError: undefined method 'title_overrides'`.

- [ ] **Step 3: Write the migration**

Create `db/migrate/20260921100000_add_seo_overrides_to_articles.rb`:

```ruby
class AddSeoOverridesToArticles < ActiveRecord::Migration[8.1]
  # Per-locale SEO Overrides. The agency can pin a title and a meta description
  # for one locale without the translator overwriting them on the next French
  # edit. Keyed by locale like the translated `title` / `meta_description`
  # hashes; the slug override lives in the existing `slugs` column.
  def change
    add_column :articles, :title_overrides, :json, default: {}, null: false
    add_column :articles, :meta_description_overrides, :json, default: {}, null: false
  end
end
```

- [ ] **Step 4: Migrate and check the schema dump**

```bash
bin/rails db:migrate
grep -n 'title_overrides\|meta_description_overrides\|define(version' db/schema.rb
```

Expected: version `2026_09_21_100000`, and inside `create_table "articles"`:

```ruby
    t.json "meta_description_overrides", default: {}, null: false
    ...
    t.json "title_overrides", default: {}, null: false
```

- [ ] **Step 5: Run the test**

```bash
bin/rails test test/models/article_test.rb -n "/default to empty hashes/"
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
git add db/migrate/20260921100000_add_seo_overrides_to_articles.rb db/schema.rb test/models/article_test.rb
git commit -m "Add title_overrides and meta_description_overrides to articles"
```

---

### Task 4: `title_for` and `meta_description_for` prefer the SEO Override

**Files:**
- Modify: `app/models/article.rb` (`title_for` line 15, `meta_description_for` line 25, new private helper)
- Test: `test/models/article_test.rb`
- Test: `test/controllers/articles_controller_test.rb`

- [ ] **Step 1: Write the failing model tests**

Add after the defaults test from Task 3 in `test/models/article_test.rb`:

```ruby
  # SEO Overrides: a per-locale title / meta description the translator never touches.
  test "title_for prefers the SEO override for that locale" do
    article = Article.new(
      title: { "fr" => "La sécurité à Monaco", "en" => "Safety in Monaco" },
      title_overrides: { "en" => "Is Monaco Safe?" },
      category: @category
    )
    assert_equal "Is Monaco Safe?", article.title_for(:en)
    assert_equal "Is Monaco Safe?", article.title_for("en")
    assert_equal "La sécurité à Monaco", article.title_for(:fr)
    assert_equal "La sécurité à Monaco", article.title_for(:de), "locales without an override keep the translated-then-FR fallback"
  end

  test "title_for ignores a blank SEO override" do
    article = Article.new(
      title: { "fr" => "Titre", "en" => "Title" },
      title_overrides: { "en" => "   " },
      category: @category
    )
    assert_equal "Title", article.title_for(:en)
  end

  test "meta_description_for prefers the SEO override for that locale" do
    article = Article.new(
      title: { "fr" => "Titre" },
      meta_description: { "fr" => "Résumé FR", "en" => "Translated summary" },
      meta_description_overrides: { "en" => "Is Monaco safe? Police, CCTV and healthcare explained." },
      category: @category
    )
    assert_equal "Is Monaco safe? Police, CCTV and healthcare explained.", article.meta_description_for(:en)
    assert_equal "Résumé FR", article.meta_description_for(:fr)
    assert_equal "Résumé FR", article.meta_description_for(:it)
  end

  test "meta_description_for ignores a blank SEO override" do
    article = Article.new(
      title: { "fr" => "Titre" },
      meta_description: { "fr" => "Résumé FR", "en" => "Translated summary" },
      meta_description_overrides: { "en" => "" },
      category: @category
    )
    assert_equal "Translated summary", article.meta_description_for(:en)
  end

  test "current_fr_hash ignores SEO overrides" do
    article = Article.new(title: { "fr" => "Titre" }, body: { "fr" => "Corps" }, category: @category)
    before = article.current_fr_hash
    other = Article.new(
      title: { "fr" => "Titre" }, body: { "fr" => "Corps" },
      title_overrides: { "en" => "Overridden" }, meta_description_overrides: { "en" => "Overridden meta" },
      category: @category
    )
    assert_equal before, other.current_fr_hash, "an override must not make the translator think the French source changed"
  end
```

- [ ] **Step 2: Write the failing page test**

Add at the end of `test/controllers/articles_controller_test.rb` (before the final `end`):

```ruby
  # SEO Overrides: the override title/meta replaces the translated one on the page.
  test "article show renders the EN SEO override in the title tag, h1 and meta description" do
    Article.create!(
      title: { "fr" => "La sécurité à Monaco", "en" => "Safety and Healthcare in Monaco", "de" => "Sicherheit in Monaco" },
      body: { "fr" => "Corps", "en" => "Body", "de" => "Text" },
      meta_description: { "fr" => "Résumé FR", "en" => "Translated summary", "de" => "Deutsche Zusammenfassung" },
      title_overrides: { "en" => "Is Monaco Safe? Police, Security and Healthcare" },
      meta_description_overrides: { "en" => "Is Monaco safe? Police, CCTV and healthcare explained." },
      slug: "la-securite-a-monaco",
      slugs: { "en" => "is-monaco-safe" },
      category: @category, published: true, published_at: Time.current
    )

    get "/en/articles/is-monaco-safe"
    assert_response :success
    assert_select "title", text: "Is Monaco Safe? Police, Security and Healthcare | Agence Immobilière de la Gare"
    assert_select "h1", text: "Is Monaco Safe? Police, Security and Healthcare"
    assert_select "meta[name='description'][content='Is Monaco safe? Police, CCTV and healthcare explained.']"
    assert_select "link[rel='canonical'][href='https://agencegaremonaco.com/en/articles/is-monaco-safe']"

    # A locale without an override keeps its Translation and the FR slug.
    get "/de/artikel/la-securite-a-monaco"
    assert_response :success
    assert_select "h1", text: "Sicherheit in Monaco"
    assert_select "meta[name='description'][content='Deutsche Zusammenfassung']"
  end
```

- [ ] **Step 3: Run both and watch them fail**

```bash
bin/rails test test/models/article_test.rb -n "/SEO override|ignores SEO overrides/"
bin/rails test test/controllers/articles_controller_test.rb -n "/EN SEO override/"
```

Expected: the four reader tests FAIL (translated value returned instead of the override); `current_fr_hash ignores SEO overrides` PASSES already (it pins the invariant); the page test FAILS on the `title` assertion.

- [ ] **Step 4: Implement the readers**

In `app/models/article.rb`, replace `title_for` and `meta_description_for`:

```ruby
  # Public readers. An SEO Override for the locale wins; otherwise the
  # Translation, then the French Source. FR never has an override (the admin
  # only offers the target locales), so current_fr_hash is unaffected.
  def title_for(locale = I18n.locale)
    override = seo_override_value(title_overrides, locale)
    return override if override
    return "" unless title.is_a?(Hash)
    title[locale.to_s].presence || title[I18n.default_locale.to_s].presence || title.values.first || ""
  end
```

```ruby
  def meta_description_for(locale = I18n.locale)
    override = seo_override_value(meta_description_overrides, locale)
    return override if override
    return "" unless meta_description.is_a?(Hash)
    meta_description[locale.to_s].presence || meta_description[I18n.default_locale.to_s].presence || ""
  end
```

Add to the `private` section, before `generate_slug`:

```ruby
  def seo_override_value(overrides, locale)
    return nil unless overrides.is_a?(Hash)
    overrides[locale.to_s].presence
  end
```

- [ ] **Step 5: Run the tests**

```bash
bin/rails test test/models/article_test.rb -n "/SEO override|ignores SEO overrides/"
bin/rails test test/controllers/articles_controller_test.rb -n "/EN SEO override/"
```

Expected: PASS (5 runs and 1 run, 0 failures).

- [ ] **Step 6: Commit**

```bash
git add app/models/article.rb test/models/article_test.rb test/controllers/articles_controller_test.rb
git commit -m "Prefer per-locale SEO overrides in title_for and meta_description_for"
```

---

### Task 5: `seo_override?(locale)`

**Files:**
- Modify: `app/models/article.rb`
- Test: `test/models/article_test.rb`

- [ ] **Step 1: Write the failing test**

Add after `"current_fr_hash ignores SEO overrides"` in `test/models/article_test.rb`:

```ruby
  test "seo_override? is true when the locale has a title, meta description or slug override" do
    article = Article.new(
      title: { "fr" => "Titre" },
      title_overrides: { "en" => "Title EN" },
      meta_description_overrides: { "it" => "Meta IT" },
      slugs: { "de" => "titel-de" },
      category: @category
    )
    assert article.seo_override?(:en)
    assert article.seo_override?("it")
    assert article.seo_override?(:de)
    assert_not article.seo_override?(:sv)
    assert_not article.seo_override?(:fr), "FR is the Source, never an override"
  end

  test "seo_override? treats blank values as absent" do
    article = Article.new(
      title: { "fr" => "Titre" },
      title_overrides: { "en" => "" }, meta_description_overrides: { "en" => " " }, slugs: { "en" => "" },
      category: @category
    )
    assert_not article.seo_override?(:en)
  end
```

- [ ] **Step 2: Run it and watch it fail**

```bash
bin/rails test test/models/article_test.rb -n "/seo_override\?/"
```

Expected: ERROR `NoMethodError: undefined method 'seo_override?'`.

- [ ] **Step 3: Implement**

In `app/models/article.rb`, add after `meta_description_for`:

```ruby
  # True when the locale has any SEO Override (title, meta description or
  # Localized Slug). Used by the admin form to show state; nothing else.
  def seo_override?(locale)
    return false if locale.to_s == I18n.default_locale.to_s
    seo_override_value(title_overrides, locale).present? ||
      seo_override_value(meta_description_overrides, locale).present? ||
      seo_override_value(slugs, locale).present?
  end
```

- [ ] **Step 4: Run the test**

```bash
bin/rails test test/models/article_test.rb -n "/seo_override\?/"
```

Expected: PASS (2 runs).

- [ ] **Step 5: Commit**

```bash
git add app/models/article.rb test/models/article_test.rb
git commit -m "Add Article#seo_override? for the admin form"
```

---

### Task 6: Validate slug overrides and meta description length

**Files:**
- Modify: `app/models/article.rb` (validations)
- Modify: `config/locales/admin.fr.yml` (French messages under `fr.activerecord`)
- Test: `test/models/article_test.rb`

- [ ] **Step 1: Write the failing tests**

Add after the `seo_override?` tests in `test/models/article_test.rb`:

```ruby
  # SEO Override validations
  test "slugs values must be lowercase letters, digits and single hyphens" do
    article = Article.new(title: { "fr" => "Titre" }, body: { "fr" => "Corps" }, slug: "titre", category: @category)

    %w[is-monaco-safe monaco2026 a].each do |ok|
      article.slugs = { "en" => ok }
      assert article.valid?, "#{ok.inspect} should be a valid slug: #{article.errors.full_messages}"
    end

    [ "Is Monaco Safe", "monaco_safe", "-leading", "trailing-", "double--hyphen", "accént", "with/slash" ].each do |bad|
      article.slugs = { "en" => bad }
      assert_not article.valid?, "#{bad.inspect} should be rejected"
      assert article.errors.added?(:slugs, :invalid_format, lang: "en"), article.errors.details.inspect
    end
  end

  test "slugs values may be blank (no override for that locale)" do
    article = Article.new(
      title: { "fr" => "Titre" }, body: { "fr" => "Corps" }, slug: "titre",
      slugs: { "en" => "", "it" => nil }, category: @category
    )
    assert article.valid?, article.errors.full_messages.inspect
  end

  test "a slug override may not collide with another article's slug in any locale" do
    Article.create!(
      title: { "fr" => "Autre" }, body: { "fr" => "Corps" },
      slug: "autre-fr", slugs: { "en" => "other-en" }, category: @category
    )
    article = Article.new(title: { "fr" => "Titre" }, body: { "fr" => "Corps" }, slug: "titre", category: @category)

    article.slugs = { "en" => "other-en" }
    assert_not article.valid?
    assert article.errors.added?(:slugs, :taken, lang: "en"), article.errors.details.inspect

    article.slugs = { "de" => "autre-fr" }
    assert_not article.valid?, "another article's FR slug is taken too"
    assert article.errors.added?(:slugs, :taken, lang: "de")
  end

  test "a slug override does not collide with the same article's own slugs" do
    article = Article.create!(
      title: { "fr" => "Titre" }, body: { "fr" => "Corps" },
      slug: "titre-fr", slugs: { "en" => "title-en" }, category: @category
    )
    article.slugs = { "en" => "title-en", "it" => "titolo-it" }
    assert article.valid?, article.errors.full_messages.inspect
  end

  test "meta description overrides are at most 160 characters" do
    article = Article.new(title: { "fr" => "Titre" }, body: { "fr" => "Corps" }, slug: "titre", category: @category)

    article.meta_description_overrides = { "en" => "x" * 160 }
    assert article.valid?, article.errors.full_messages.inspect

    article.meta_description_overrides = { "en" => "x" * 161 }
    assert_not article.valid?
    assert article.errors.added?(:meta_description_overrides, :too_long, lang: "en"), article.errors.details.inspect
  end

  test "override validation messages are in French" do
    article = Article.new(
      title: { "fr" => "Titre" }, body: { "fr" => "Corps" }, slug: "titre",
      slugs: { "en" => "Bad Slug" }, meta_description_overrides: { "it" => "x" * 161 },
      category: @category
    )
    article.valid?
    messages = article.errors.full_messages.join(" | ")
    assert_match(/Slugs par langue.*\(en\).*minuscules, chiffres et tirets/, messages)
    assert_match(/Meta descriptions par langue.*\(it\).*160 caractères/, messages)
  end
```

- [ ] **Step 2: Run them and watch them fail**

```bash
bin/rails test test/models/article_test.rb -n "/slugs values|slug override|meta description overrides are at most|messages are in French/"
```

Expected: 6 runs; `slugs values may be blank` PASSES (nothing validates yet), the other five FAIL (`assert_not article.valid?` fails because no validation exists).

- [ ] **Step 3: Add the validations**

In `app/models/article.rb`, below `validates :slug, presence: true, uniqueness: true`, add:

```ruby
  # SEO Override validations. Slug overrides must be URL-safe and unique across
  # every article's FR slug and per-locale slugs. Meta overrides respect the
  # same 160-character limit as the French meta description field.
  LOCALIZED_SLUG_FORMAT = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/

  validate :localized_slugs_are_well_formed_and_free
  validate :meta_description_overrides_fit
```

In the `private` section, before `seo_override_value`, add:

```ruby
  def localized_slugs_are_well_formed_and_free
    return unless slugs.is_a?(Hash)

    slugs.each do |locale, value|
      next if value.blank?
      unless value.match?(LOCALIZED_SLUG_FORMAT)
        errors.add(:slugs, :invalid_format, lang: locale)
        next
      end
      if self.class.localized_slug_taken?(value, locale, except_id: id)
        errors.add(:slugs, :taken, lang: locale)
      end
    end
  end

  def meta_description_overrides_fit
    return unless meta_description_overrides.is_a?(Hash)

    meta_description_overrides.each do |locale, value|
      errors.add(:meta_description_overrides, :too_long, lang: locale) if value.to_s.length > 160
    end
  end
```

Note: `localized_slug_taken?` (from PR 135) already excludes the current article through `except_id: id`; for a new record `id` is nil and nothing is excluded, which is correct.

The interpolation key is `lang`, not `locale`: ActiveModel forwards error options to `I18n.translate`, and a `locale:` option would switch the lookup to that locale and break the French message.

- [ ] **Step 4: Add the French messages**

In `config/locales/admin.fr.yml`, the file starts with:

```yaml
fr:
  activerecord:
    attributes:
      property_share:
        subject: "Sujet"
        body: "Message"
```

Change that block to:

```yaml
fr:
  activerecord:
    attributes:
      property_share:
        subject: "Sujet"
        body: "Message"
      article:
        slugs: "Slugs par langue"
        meta_description_overrides: "Meta descriptions par langue"
    errors:
      models:
        article:
          attributes:
            slugs:
              invalid_format: "(%{lang}) doit contenir uniquement des minuscules, chiffres et tirets"
              taken: "(%{lang}) est déjà utilisé par un autre article"
            meta_description_overrides:
              too_long: "(%{lang}) doit faire 160 caractères maximum"
```

(Indentation: `errors:` sits at the same level as `attributes:`, four spaces in.)

- [ ] **Step 5: Run the tests**

```bash
bin/rails test test/models/article_test.rb -n "/slugs values|slug override|meta description overrides are at most|messages are in French/"
bin/rails test test/models/article_test.rb test/services/article_translator_test.rb
```

Expected: 6 runs PASS; then the whole model and translator files still green (the translator's minted slugs are already collision-free and well-formed, so no existing test breaks).

- [ ] **Step 6: Commit**

```bash
git add app/models/article.rb config/locales/admin.fr.yml test/models/article_test.rb
git commit -m "Validate per-locale slug overrides and meta description length"
```

---

### Task 7: Pin that the translator leaves SEO Overrides alone

**Files:**
- Test: `test/services/article_translator_test.rb`

No production change is expected: `ArticleTranslator#apply_locale!` writes only `title`, `body`, `meta_description`, `slugs` (when the locale has none) and `translations_status` through `update_columns`. This test guards that invariant so a later refactor cannot silently start rewriting overrides.

- [ ] **Step 1: Write the test**

Add after `"freezes an existing per-locale slug across a re-translation after an FR edit"` in `test/services/article_translator_test.rb`:

```ruby
  test "a French edit rewrites the translations but leaves SEO overrides and existing slugs untouched" do
    @article.update_columns(
      title_overrides: { "en" => "Is Monaco Safe?" },
      meta_description_overrides: { "en" => "Pinned EN meta" },
      slugs: { "en" => "is-monaco-safe" }
    )

    with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(Article.find(@article.id)).translate!
    end

    @article.reload
    assert_equal "Title EN", @article.title["en"], "translated title is rewritten"
    assert_equal({ "en" => "Is Monaco Safe?" }, @article.title_overrides)
    assert_equal({ "en" => "Pinned EN meta" }, @article.meta_description_overrides)
    assert_equal "is-monaco-safe", @article.slugs["en"], "existing slug override is frozen"
    assert_equal "title-it", @article.slugs["it"], "locales without a slug still get one minted"
    assert_equal "Is Monaco Safe?", @article.title_for(:en), "the page keeps showing the override"
  end
```

- [ ] **Step 2: Run it**

```bash
bin/rails test test/services/article_translator_test.rb -n "/leaves SEO overrides/"
```

Expected: PASS on the first run. If it fails, the translator is touching override columns and must be fixed before continuing; do not weaken the test.

- [ ] **Step 3: Commit**

```bash
git add test/services/article_translator_test.rb
git commit -m "Pin that the translator never rewrites SEO overrides"
```

---

### Task 8: "Surcharges SEO" section on the admin edit form

**Files:**
- Modify: `app/views/admin/articles/_form.html.erb` (insert after the body fieldset, inside the main column, before the `</div>` that closes `lg:col-span-2`)
- Modify: `config/locales/admin.fr.yml` (`admin.articles.form.*`)
- Test: `test/controllers/admin/articles_controller_test.rb`

- [ ] **Step 1: Write the failing tests**

Add at the end of `test/controllers/admin/articles_controller_test.rb` (before the final `end`):

```ruby
  # SEO Overrides ("Surcharges SEO"): per-locale title / meta / slug fields on the edit form.
  test "GET edit shows a collapsed Surcharges SEO section with fields for every target locale" do
    article = Article.create!(
      title: { "fr" => "La sécurité", "en" => "Safety in Monaco" },
      body: { "fr" => "Corps" },
      meta_description: { "fr" => "Résumé", "en" => "Translated summary" },
      title_overrides: { "en" => "Is Monaco Safe?" },
      slugs: { "en" => "is-monaco-safe" },
      slug: "la-securite",
      category: @category
    )
    get edit_admin_article_url(article)
    assert_response :success

    assert_select "details.seo-overrides:not([open])" do
      assert_select "summary", text: /Surcharges SEO/
    end
    Article::TARGET_LOCALES.each do |locale|
      assert_select "input[name='article[title_overrides][#{locale}]']", 1
      assert_select "textarea[name='article[meta_description_overrides][#{locale}]'][maxlength='160']", 1
      assert_select "input[name='article[slugs][#{locale}]']", 1
    end

    # Values show the override; placeholders show what the page falls back to.
    assert_select "input[name='article[title_overrides][en]'][value='Is Monaco Safe?'][placeholder='Safety in Monaco']"
    assert_select "textarea[name='article[meta_description_overrides][en]'][placeholder='Translated summary']", text: ""
    assert_select "input[name='article[slugs][en]'][value='is-monaco-safe'][placeholder='la-securite']"
    assert_select "input[name='article[slugs][it]'][placeholder='la-securite']:not([value])"
    assert_select "input[name='article[title_overrides][it]']:not([value])"
  end

  test "GET edit marks locales that have an SEO override" do
    article = Article.create!(
      title: { "fr" => "La sécurité" }, body: { "fr" => "Corps" },
      title_overrides: { "en" => "Is Monaco Safe?" },
      slug: "la-securite", category: @category
    )
    get edit_admin_article_url(article)
    assert_select "details.seo-overrides [data-locale='en'] .seo-override-active", 1
    assert_select "details.seo-overrides [data-locale='it'] .seo-override-active", 0
  end

  test "GET new does not show the Surcharges SEO section" do
    get new_admin_article_url
    assert_response :success
    assert_select "details.seo-overrides", 0
    assert_select "input[name^='article[title_overrides]']", 0
    assert_select "input[name^='article[slugs]']", 0
  end
```

- [ ] **Step 2: Run them and watch them fail**

```bash
bin/rails test test/controllers/admin/articles_controller_test.rb -n "/Surcharges SEO|marks locales that have an SEO override/"
```

Expected: the two `GET edit` tests FAIL (`details.seo-overrides` not found); `GET new does not show` PASSES already.

- [ ] **Step 3: Add the French strings**

In `config/locales/admin.fr.yml`, under `admin.articles.form`, after `cover_image: "Image de couverture"`, add:

```yaml
        seo_overrides_legend: "Surcharges SEO"
        seo_overrides_hint: "Remplace, pour une langue donnée, le titre, la meta description ou le slug traduits automatiquement. Laisser vide pour conserver la traduction. Un champ vidé supprime la surcharge."
        seo_override_active: "surcharge active"
        seo_override_title: "Titre"
        seo_override_meta_description: "Meta description"
        seo_override_slug: "Slug"
        seo_override_slug_hint: "Minuscules, chiffres et tirets. L'ancienne URL redirige (301) vers la nouvelle."
```

- [ ] **Step 4: Add the section to the form**

In `app/views/admin/articles/_form.html.erb`, immediately after the body `</fieldset>` (the line that currently reads `      </fieldset>` followed by `    </div>` closing the `lg:col-span-2` column, around line 73), insert:

```erb
      <%# SEO Overrides per locale: edit-only, collapsed by default %>
      <% if article.persisted? %>
        <details class="seo-overrides bg-white rounded shadow p-6">
          <summary class="heading-section cursor-pointer select-none"><%= t("admin.articles.form.seo_overrides_legend") %></summary>
          <p class="mt-2 text-xs text-gray-500"><%= t("admin.articles.form.seo_overrides_hint") %></p>

          <div class="mt-4 space-y-6">
            <% Article::TARGET_LOCALES.each do |locale| %>
              <div data-locale="<%= locale %>" class="border-t border-gray-200 pt-4">
                <h3 class="text-sm font-semibold text-gray-800 mb-3 flex items-center gap-2">
                  <span><%= locale.upcase %></span>
                  <% if article.seo_override?(locale) %>
                    <span class="seo-override-active text-xs font-normal text-navy bg-navy/10 rounded px-2 py-0.5"><%= t("admin.articles.form.seo_override_active") %></span>
                  <% end %>
                </h3>

                <div class="space-y-3">
                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1"><%= t("admin.articles.form.seo_override_title") %></label>
                    <input type="text" name="article[title_overrides][<%= locale %>]"
                           <% if article.title_overrides&.dig(locale).present? %>value="<%= article.title_overrides[locale] %>"<% end %>
                           placeholder="<%= article.title&.dig(locale) %>"
                           class="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:ring-navy focus:border-navy">
                  </div>

                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1"><%= t("admin.articles.form.seo_override_meta_description") %></label>
                    <textarea name="article[meta_description_overrides][<%= locale %>]" rows="2" maxlength="160"
                              placeholder="<%= article.meta_description&.dig(locale) %>"
                              class="w-full border border-gray-300 rounded px-3 py-2 text-sm focus:ring-navy focus:border-navy"><%= article.meta_description_overrides&.dig(locale) %></textarea>
                  </div>

                  <div>
                    <label class="block text-xs font-medium text-gray-700 mb-1"><%= t("admin.articles.form.seo_override_slug") %></label>
                    <input type="text" name="article[slugs][<%= locale %>]"
                           <% if article.slugs&.dig(locale).present? %>value="<%= article.slugs[locale] %>"<% end %>
                           placeholder="<%= article.slug %>"
                           class="w-full border border-gray-300 rounded px-3 py-2 text-sm font-mono focus:ring-navy focus:border-navy">
                    <p class="mt-1 text-xs text-gray-500"><%= t("admin.articles.form.seo_override_slug_hint") %></p>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </details>
      <% end %>
```

The `value` attributes are omitted entirely when blank (rather than rendered as `value=""`) so the tests can assert `:not([value])` and so an untouched locale round-trips as an empty string the controller then drops.

- [ ] **Step 5: Run the tests**

```bash
bin/rails test test/controllers/admin/articles_controller_test.rb -n "/Surcharges SEO|marks locales that have an SEO override/"
bin/rails test test/controllers/admin/articles_controller_test.rb
```

Expected: 3 runs PASS; then the whole admin articles file green (the existing `GET edit` tests that assert `input[name='article[title][en]']` is absent still hold, because the new inputs are named `title_overrides`).

- [ ] **Step 6: Commit**

```bash
git add app/views/admin/articles/_form.html.erb config/locales/admin.fr.yml test/controllers/admin/articles_controller_test.rb
git commit -m "Add the Surcharges SEO section to the admin article edit form"
```

---

### Task 9: Controller: permit, merge and blank-drop the override hashes

**Files:**
- Modify: `app/controllers/admin/articles_controller.rb` (`article_params`, new constant, new private method)
- Test: `test/controllers/admin/articles_controller_test.rb`

- [ ] **Step 1: Write the failing tests**

Add at the end of `test/controllers/admin/articles_controller_test.rb` (before the final `end`):

```ruby
  test "PATCH update saves one locale's SEO overrides and leaves the other locales' overrides alone" do
    article = Article.create!(
      title: { "fr" => "La sécurité", "en" => "Safety", "it" => "Sicurezza" },
      body: { "fr" => "Corps" },
      title_overrides: { "it" => "Monaco è sicura?" },
      meta_description_overrides: { "it" => "Meta IT" },
      slugs: { "it" => "monaco-e-sicura" },
      slug: "la-securite", category: @category
    )

    patch admin_article_url(article), params: { article: {
      title_overrides: { en: "Is Monaco Safe?" },
      meta_description_overrides: { en: "Is Monaco safe? Police, CCTV and healthcare explained." },
      slugs: { en: "is-monaco-safe" }
    } }
    assert_redirected_to admin_articles_url

    article.reload
    assert_equal({ "it" => "Monaco è sicura?", "en" => "Is Monaco Safe?" }, article.title_overrides)
    assert_equal({ "it" => "Meta IT", "en" => "Is Monaco safe? Police, CCTV and healthcare explained." }, article.meta_description_overrides)
    assert_equal({ "it" => "monaco-e-sicura", "en" => "is-monaco-safe" }, article.slugs)
    assert_equal "Safety", article.title["en"], "the Translation itself is untouched"
  end

  test "PATCH update with blank override fields removes only that locale's overrides" do
    article = Article.create!(
      title: { "fr" => "La sécurité", "en" => "Safety" }, body: { "fr" => "Corps" },
      title_overrides: { "en" => "Is Monaco Safe?", "it" => "Monaco è sicura?" },
      meta_description_overrides: { "en" => "Meta EN", "it" => "Meta IT" },
      slugs: { "en" => "is-monaco-safe", "it" => "monaco-e-sicura" },
      slug: "la-securite", category: @category
    )

    # The form always submits every locale's field; the ones the owner did not
    # fill in arrive as "". Clearing EN must not disturb IT.
    patch admin_article_url(article), params: { article: {
      title_overrides: { en: "", it: "Monaco è sicura?" },
      meta_description_overrides: { en: "   ", it: "Meta IT" },
      slugs: { en: "", it: "monaco-e-sicura" }
    } }
    assert_redirected_to admin_articles_url

    article.reload
    assert_equal({ "it" => "Monaco è sicura?" }, article.title_overrides)
    assert_equal({ "it" => "Meta IT" }, article.meta_description_overrides)
    assert_equal({ "it" => "monaco-e-sicura" }, article.slugs)
    assert_equal "Safety", article.title_for(:en), "EN falls back to the Translation"
    assert_equal "la-securite", article.slug_for(:en), "EN falls back to the FR slug"
  end

  test "PATCH update does not enqueue a translation when only SEO overrides change" do
    article = Article.create!(
      title: { "fr" => "La sécurité" }, body: { "fr" => "Corps" },
      slug: "la-securite", category: @category
    )
    article.update_columns(translation_source_hash: article.current_fr_hash)

    assert_no_enqueued_jobs only: ArticleTranslationJob do
      patch admin_article_url(article), params: { article: { title_overrides: { en: "Is Monaco Safe?" } } }
    end
  end

  test "PATCH update with an invalid slug override re-renders the form with a French error" do
    article = Article.create!(
      title: { "fr" => "La sécurité" }, body: { "fr" => "Corps" },
      slug: "la-securite", category: @category
    )

    patch admin_article_url(article), params: { article: { slugs: { en: "Is Monaco Safe" } } }
    assert_response :unprocessable_entity
    assert_select "li", /Slugs par langue \(en\) doit contenir uniquement des minuscules, chiffres et tirets/
    assert_select "input[name='article[slugs][en]'][value='Is Monaco Safe']", 1, "the rejected value stays in the field"
    assert_equal({}, article.reload.slugs)
  end

  test "PATCH update with a slug override taken by another article re-renders with a French error" do
    Article.create!(title: { "fr" => "Autre" }, body: { "fr" => "C" }, slug: "autre", slugs: { "en" => "other" }, category: @category)
    article = Article.create!(title: { "fr" => "Titre" }, body: { "fr" => "C" }, slug: "titre", category: @category)

    patch admin_article_url(article), params: { article: { slugs: { en: "other" } } }
    assert_response :unprocessable_entity
    assert_select "li", /Slugs par langue \(en\) est déjà utilisé par un autre article/
  end

  test "PATCH update ignores SEO overrides for FR or unknown locales" do
    article = Article.create!(title: { "fr" => "Titre" }, body: { "fr" => "C" }, slug: "titre", category: @category)

    patch admin_article_url(article), params: { article: {
      title_overrides: { fr: "Nope", xx: "Nope", en: "Yes" }
    } }
    assert_redirected_to admin_articles_url
    assert_equal({ "en" => "Yes" }, article.reload.title_overrides)
  end
```

Check the test file already has `include ActiveJob::TestHelper` (the existing `enqueues ArticleTranslationJob` tests need it); if not, add it under the class line.

- [ ] **Step 2: Run them and watch them fail**

```bash
bin/rails test test/controllers/admin/articles_controller_test.rb -n "/SEO overrides|slug override/"
```

Expected: 6 runs. The four `saves`, `blank`, `invalid slug`, `taken` tests FAIL (the params are unpermitted, so nothing is saved and no error renders). `does not enqueue` and `ignores FR or unknown` may pass by accident (nothing saved); that is fine, they pin behaviour once the permit is in.

- [ ] **Step 3: Implement**

Replace `app/controllers/admin/articles_controller.rb` lines 5-6 (the `TRANSLATED_COLUMNS` constant and its comment) with:

```ruby
    # JSON columns holding every locale. The admin edits FR only.
    TRANSLATED_COLUMNS = %w[title body meta_description].freeze

    # Per-locale SEO Overrides (title, meta description, Localized Slug). The
    # admin edits every target locale; a blank field removes that override.
    OVERRIDE_COLUMNS = %w[title_overrides meta_description_overrides slugs].freeze
```

Replace `article_params`:

```ruby
    def article_params
      permitted = params.require(:article).permit(
        :slug, :category_id, :published, :featured, :cover_image_url,
        title: [ :fr ],
        body: [ :fr ],
        meta_description: [ :fr ],
        title_overrides: Article::TARGET_LOCALES,
        meta_description_overrides: Article::TARGET_LOCALES,
        slugs: Article::TARGET_LOCALES
      )

      merge_translated_columns(permitted, @article, TRANSLATED_COLUMNS)
      merge_translated_columns(permitted, @article, OVERRIDE_COLUMNS)
      drop_blank_overrides(permitted)
    end

    # Merging keeps every stored locale; a field the owner emptied is now a
    # blank value in the MERGED hash, so removing blanks here is what clears
    # that one override. Nothing else in the hash is touched.
    def drop_blank_overrides(permitted)
      OVERRIDE_COLUMNS.each do |column|
        next if permitted[column].nil?
        permitted[column] = permitted[column].to_h.reject { |_locale, value| value.blank? }
      end
      permitted
    end
```

`Article::TARGET_LOCALES` is an array of strings (`%w[en it de sv no da fi ru]`); `permit` accepts string keys in nested filters. `fr` and unknown keys are dropped by `permit`.

- [ ] **Step 4: Run the tests**

```bash
bin/rails test test/controllers/admin/articles_controller_test.rb -n "/SEO overrides|slug override/"
bin/rails test test/controllers/admin/articles_controller_test.rb
```

Expected: 6 runs PASS; whole file green, including `PATCH update preserves translated title locales when editing French` and `POST create silently drops non-FR title and body params`.

- [ ] **Step 5: Commit**

```bash
git add app/controllers/admin/articles_controller.rb test/controllers/admin/articles_controller_test.rb
git commit -m "Save per-locale SEO overrides from the admin, clearing on blank"
```

---

### Task 10: Commit the glossary, run everything, merge to master, push

**Files:**
- `CONTEXT.md` (untracked; the "Articles and Translations" glossary the spec refers to)

- [ ] **Step 1: Commit the glossary on the feature branch**

```bash
git add CONTEXT.md
git commit -m "Document the Articles and Translations glossary in CONTEXT.md"
```

- [ ] **Step 2: Full suite and lint**

```bash
bin/rails test
bin/rubocop app/models/article.rb app/controllers/admin/articles_controller.rb db/migrate/20260921100000_add_seo_overrides_to_articles.rb test/models/article_test.rb test/controllers/admin/articles_controller_test.rb test/controllers/articles_controller_test.rb test/services/article_translator_test.rb
```

Expected: `0 failures, 0 errors`; rubocop `no offenses detected`. Fix any offense in place and amend the relevant task's commit only if the offense is in that task's files; otherwise add a small "Style fixes" commit.

- [ ] **Step 3: Merge to master and push**

```bash
git checkout master
git merge --no-ff seo-overrides -m "Merge branch 'seo-overrides'

Per-locale SEO overrides (title, meta description, slug) on top of
localised article slugs (PR 135)."
bin/rails test
git push origin master
git push origin seo-overrides
```

Expected: fast merge, suite green on master, both pushes accepted. PR 135 on GitHub can then be closed as merged via `seo-overrides` (say so in the completion message; do not close it without the owner).

- [ ] **Step 4: Report**

In the completion message give the owner:
1. The deploy command (`bin/kamal deploy`); the migration runs on boot.
2. The rollout drafts from the appendix below, ready to paste into the admin.
3. The curl checks from the spec's Rollout section:

```bash
curl -sI https://agencegaremonaco.com/en/articles/la-securite-et-la-sante-a-monaco | grep -i '^HTTP\|^location'
curl -sI https://agencegaremonaco.com/en/article/15/anything | grep -i '^HTTP\|^location'
curl -s https://agencegaremonaco.com/en/articles/is-monaco-safe | grep -o '<title>[^<]*</title>\|<h1[^>]*>[^<]*</h1>\|rel="canonical" href="[^"]*"'
```

Expected after the owner saves the EN override: both redirects answer `HTTP/2 301` with `location: https://agencegaremonaco.com/en/articles/is-monaco-safe`; the new URL shows the override title in `<title>` and `<h1>` and a self canonical.

---

## Appendix: rollout drafts for the owner

Paste these into the admin after deploy. The French body additions go through the translator; the EN fields go into the "Surcharges SEO" section under EN.

### EN SEO Override (article "La sécurité et la santé à Monaco")

- **Titre (EN):** `Is Monaco Safe? Police, Security and Healthcare in the Principality`
- **Slug (EN):** `is-monaco-safe`
- **Meta description (EN), 147 characters:**

```
Is Monaco safe? How the Principality's police, round-the-clock CCTV and hospitals make it one of the safest places to live. A local agency's guide.
```

### French body additions

Insert this section after the list that ends with "La possibilité de bloquer tous les accès à la principauté en quelques minutes." and its following paragraph, before "#### Des règles strictes pour une vie harmonieuse". Figures marked (à vérifier) should be checked against the Gouvernement Princier's current published numbers before publishing.

```markdown
#### La police à Monaco : une présence visible et permanente

La sécurité de la Principauté repose sur la Direction de la Sûreté Publique, la police nationale monégasque, qui compte plus de 500 agents pour environ 39 000 habitants (à vérifier), soit l'un des ratios policiers/habitants les plus élevés du monde. Elle est complétée par la Compagnie des Carabiniers du Prince, chargée de la protection du Palais et des cérémonies officielles, et par les Sapeurs-Pompiers de Monaco.

Concrètement, cela se traduit au quotidien par :

- Des patrouilles à pied et en véhicule dans tous les quartiers, de jour comme de nuit ;
- Un réseau de vidéosurveillance couvrant l'ensemble du territoire, relié en direct à un centre de commandement ;
- Des postes de police de proximité, dont le siège de la Sûreté Publique rue Louis Notari, à la Condamine ;
- Des délais d'intervention très courts, le territoire faisant à peine plus de deux kilomètres carrés.

En cas d'urgence, la police répond au 17 et les pompiers au 18 ; le 112 fonctionne également depuis un téléphone portable. Les agents parlent français et, dans la plupart des cas, anglais et italien.

Cette présence explique le très faible taux de criminalité de la Principauté : les vols à la tire et les cambriolages restent rares, et les agressions exceptionnelles. C'est l'une des raisons pour lesquelles de nombreuses familles choisissent de s'installer à Monaco, et l'un des premiers points que nos clients internationaux nous demandent de confirmer.
```

Append this FAQ at the very end of the body, after the healthcare section:

```markdown
### Questions fréquentes sur la sécurité à Monaco

#### Monaco est-il un pays sûr ?

Oui. Monaco est régulièrement cité parmi les endroits les plus sûrs du monde. La combinaison d'une police très présente, d'une vidéosurveillance couvrant tout le territoire et de contrôles aux accès de la Principauté en fait un lieu où les résidents se déplacent sans crainte à toute heure.

#### Peut-on se promener seul le soir à Monaco ?

Oui, y compris pour une femme seule ou avec des enfants. Les rues, les jardins et le bord de mer sont éclairés, surveillés et fréquentés tard le soir, surtout autour du Port Hercule, de Monte-Carlo et du Larvotto.

#### Combien de policiers compte Monaco ?

La Sûreté Publique compte plus de 500 agents pour environ 39 000 habitants (à vérifier), soit environ un policier pour 75 habitants. À titre de comparaison, la moyenne en Europe se situe autour d'un policier pour 300 habitants.

#### Quel numéro appeler en cas d'urgence à Monaco ?

Le 17 pour la police, le 18 pour les pompiers et le 112 depuis un mobile. Le Centre Hospitalier Princesse Grace assure les urgences médicales 24 heures sur 24.

#### La sécurité influence-t-elle le prix de l'immobilier à Monaco ?

Oui. La sécurité fait partie, avec la fiscalité et la qualité de vie, des trois raisons principales pour lesquelles nos clients choisissent d'acheter ou de louer à Monaco. Elle soutient la demande et donc la valeur des biens sur le long terme. Notre agence, installée près de la gare depuis plus de 40 ans, vous accompagne dans votre recherche.
```

The FAQ reuses the "1 pour 100" ratio already in the article only if the owner keeps it; the draft above uses "1 pour 75", which matches the 500+ agents figure. Pick one and make the two consistent.
