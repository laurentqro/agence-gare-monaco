require "test_helper"
require "rake"

class ArticleTranslationsRakeTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
  end

  teardown do
    Rake::Task["articles:retranslate_all"].reenable
    Rake::Task["articles:retranslate"].reenable
  end

  def silence_stdout
    original = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original
  end

  test "articles:retranslate_all nullifies translation_source_hash on every article" do
    a1 = Article.create!(title: { "fr" => "A1" }, body: { "fr" => "B" }, slug: "a1", category: @category)
    a2 = Article.create!(title: { "fr" => "A2" }, body: { "fr" => "B" }, slug: "a2", category: @category)
    a1.update_columns(translation_source_hash: "hash1")
    a2.update_columns(translation_source_hash: "hash2")

    silence_stdout { Rake::Task["articles:retranslate_all"].invoke }

    assert_nil a1.reload.translation_source_hash
    assert_nil a2.reload.translation_source_hash
  end

  test "articles:retranslate_all enqueues exactly one job per article (no double-enqueue)" do
    Article.create!(title: { "fr" => "A1" }, body: { "fr" => "B" }, slug: "a1", category: @category)
    Article.create!(title: { "fr" => "A2" }, body: { "fr" => "B" }, slug: "a2", category: @category)

    assert_enqueued_jobs 2, only: ArticleTranslationJob do
      silence_stdout { Rake::Task["articles:retranslate_all"].invoke }
    end
  end

  test "articles:retranslate_all reports count to stdout" do
    Article.create!(title: { "fr" => "A1" }, body: { "fr" => "B" }, slug: "a1", category: @category)
    Article.create!(title: { "fr" => "A2" }, body: { "fr" => "B" }, slug: "a2", category: @category)

    output = silence_stdout { Rake::Task["articles:retranslate_all"].invoke }
    assert_match(/2 article/, output)
  end

  test "articles:retranslate[ID] enqueues one job for the matching article" do
    article = Article.create!(title: { "fr" => "A" }, body: { "fr" => "B" }, slug: "a", category: @category)
    article.update_columns(translation_source_hash: "old")

    assert_enqueued_with(job: ArticleTranslationJob, args: [ article.id ]) do
      silence_stdout { Rake::Task["articles:retranslate"].invoke(article.id.to_s) }
    end

    assert_nil article.reload.translation_source_hash
  end

  test "articles:retranslate aborts when no id is supplied" do
    assert_raises(SystemExit) do
      silence_stdout { Rake::Task["articles:retranslate"].invoke }
    end
  end

  test "articles:retranslate aborts when no article matches the id" do
    assert_raises(SystemExit) do
      silence_stdout { Rake::Task["articles:retranslate"].invoke("999999") }
    end
  end
end
