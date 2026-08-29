require "test_helper"
require "rake"

# SEO audit 0.2: localise article slugs. This task backfills the per-locale
# `slugs` hash from each article's translated titles, freezing the result so a
# later title edit never moves an indexed URL. FR always stays as the pinned
# canonical `slug` column and is never written into `slugs`.
class BackfillArticleSlugsTaskTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["articles:backfill_slugs"].reenable

    @category = Category.create!(slug: "actualites", name: { "fr" => "Actualités" })
  end

  def run_task
    Rake::Task["articles:backfill_slugs"].reenable
    Rake::Task["articles:backfill_slugs"].invoke
  end

  test "derives a per-locale slug from each translated title" do
    article = Article.create!(
      slug: "comment-vendre-son-bien-immobilier-a-monaco",
      category: @category, published: true,
      title: {
        "fr" => "Comment vendre son bien immobilier à Monaco",
        "en" => "How to sell your property in Monaco",
        "it" => "Come vendere il tuo immobile a Monaco"
      },
      body: { "fr" => "Corps" }
    )

    run_task
    slugs = article.reload.slugs
    assert_equal "how-to-sell-your-property-in-monaco", slugs["en"]
    assert_equal "come-vendere-il-tuo-immobile-a-monaco", slugs["it"]
  end

  test "never writes an fr key into slugs" do
    article = Article.create!(
      slug: "comment-vendre",
      category: @category, published: true,
      title: { "fr" => "Comment vendre", "en" => "How to sell" },
      body: { "fr" => "Corps" }
    )

    run_task
    assert_not_includes article.reload.slugs.keys, "fr"
  end

  test "leaves the canonical fr slug untouched" do
    article = Article.create!(
      slug: "comment-vendre",
      category: @category, published: true,
      title: { "fr" => "Comment vendre", "en" => "How to sell" },
      body: { "fr" => "Corps" }
    )

    run_task
    assert_equal "comment-vendre", article.reload.slug
  end

  test "skips locales without a translated title" do
    article = Article.create!(
      slug: "comment-vendre",
      category: @category, published: true,
      title: { "fr" => "Comment vendre", "en" => "How to sell" },
      body: { "fr" => "Corps" }
    )

    run_task
    slugs = article.reload.slugs
    assert_equal %w[en], slugs.keys
  end

  test "transliterates Russian titles with Russian rules" do
    article = Article.create!(
      slug: "comment-vendre",
      category: @category, published: true,
      title: { "fr" => "Comment vendre", "ru" => "Как продать недвижимость" },
      body: { "fr" => "Corps" }
    )

    run_task
    ru = article.reload.slugs["ru"]
    assert ru.present?, "expected a non-empty Russian slug"
    assert_match(/\A[a-z0-9-]+\z/, ru, "Russian slug must be ASCII-safe: #{ru}")
  end

  test "freezes existing slugs: does not overwrite a slug already set" do
    article = Article.create!(
      slug: "comment-vendre",
      category: @category, published: true,
      title: { "fr" => "Comment vendre", "en" => "How to sell" },
      slugs: { "en" => "hand-authored-en-slug" },
      body: { "fr" => "Corps" }
    )

    run_task
    assert_equal "hand-authored-en-slug", article.reload.slugs["en"]
  end

  test "does not store an empty slug when a title parameterizes to nothing" do
    article = Article.create!(
      slug: "comment-vendre",
      category: @category, published: true,
      title: { "fr" => "Comment vendre", "en" => "!!!???" },
      body: { "fr" => "Corps" }
    )

    run_task
    slugs = article.reload.slugs
    assert_not_includes slugs.keys, "en",
      "a punctuation-only title parameterizes to '' and must be skipped, not stored blank"
  end

  test "does not enqueue translation jobs" do
    article = Article.create!(
      slug: "comment-vendre",
      category: @category, published: true,
      title: { "fr" => "Comment vendre", "en" => "How to sell" },
      body: { "fr" => "Corps" }
    )
    article.update_columns(translation_source_hash: "pinned-hash")

    assert_no_enqueued_jobs { run_task }
    assert_equal "pinned-hash", article.reload.translation_source_hash
  end

  test "is idempotent" do
    article = Article.create!(
      slug: "comment-vendre",
      category: @category, published: true,
      title: { "fr" => "Comment vendre", "en" => "How to sell" },
      body: { "fr" => "Corps" }
    )

    run_task
    first = article.reload.slugs.dup
    run_task
    assert_equal first, article.reload.slugs
  end
end
