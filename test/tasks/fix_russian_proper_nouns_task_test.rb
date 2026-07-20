require "test_helper"
require "rake"

class FixRussianProperNounsTaskTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["articles:fix_russian_proper_nouns"].reenable
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites-ru-fix")
  end

  teardown do
    ENV.delete("APPLY")
  end

  def create_article(ru_title:, ru_body: "текст", hash: "source-hash-1")
    Article.create!(
      slug: "ru-fix-#{SecureRandom.hex(4)}",
      category: @category,
      title: { "fr" => "Titre", "ru" => ru_title },
      body: { "fr" => "Corps", "ru" => ru_body },
      translation_source_hash: hash,
      translations_status: { "ru" => { "translated_at" => "2026-07-20T10:00:00Z", "source_hash" => hash } }
    )
  end

  def run_task
    Rake::Task["articles:fix_russian_proper_nouns"].reenable
    capture_io { Rake::Task["articles:fix_russian_proper_nouns"].invoke }
  end

  test "dry run reports changes without writing" do
    article = create_article(ru_title: "Налоги Monaco")

    out, = run_task

    assert_includes out, "DRY RUN"
    assert_equal "Налоги Monaco", article.reload.title["ru"],
      "dry run must not modify the record"
  end

  test "APPLY=1 transliterates the Russian title" do
    article = create_article(ru_title: "Налоги Monaco")
    ENV["APPLY"] = "1"

    run_task

    assert_equal "Налоги Монако", article.reload.title["ru"]
  end

  test "leaves other locales untouched" do
    article = create_article(ru_title: "Налоги Monaco")
    ENV["APPLY"] = "1"

    run_task

    assert_equal "Titre", article.reload.title["fr"],
      "the French source must never be rewritten"
  end

  test "does not mark the article stale or clear its translation status" do
    article = create_article(ru_title: "Налоги Monaco")
    ENV["APPLY"] = "1"

    run_task
    article.reload

    assert_equal "source-hash-1", article.translation_source_hash,
      "correcting text must not invalidate the source hash"
    assert_equal "2026-07-20T10:00:00Z", article.translations_status.dig("ru", "translated_at")
  end

  test "does not enqueue translation jobs" do
    create_article(ru_title: "Налоги Monaco")
    ENV["APPLY"] = "1"

    assert_no_enqueued_jobs only: ArticleTranslationJob do
      run_task
    end
  end

  test "skips articles that need no correction" do
    article = create_article(ru_title: "Налоги Монако")
    ENV["APPLY"] = "1"

    run_task

    assert_equal "Налоги Монако", article.reload.title["ru"]
  end

  test "preserves Latin proper nouns that contain Monaco" do
    article = create_article(ru_title: "Событие", ru_body: "мероприятие Monaco Yacht Show прошло")
    ENV["APPLY"] = "1"

    run_task

    assert_equal "мероприятие Monaco Yacht Show прошло", article.reload.body["ru"]
  end
end
