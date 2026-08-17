require "test_helper"
require "rake"

# 0.1 of the 2026-07 SEO audit: the valuation article ranks at position 3-5 on
# commercial queries ("estimation immobilière monaco", "property valuation
# monaco") but takes 0 clicks — a snippet problem. This task rewrites its FR/EN
# title and meta_description to match those queries and add a free-valuation CTA,
# without re-running the translator (other locales are left untouched on purpose).
class ValuationSnippetTaskTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  SLUG = "comment-estimer-la-valeur-de-votre-bien-immobilier-a-monaco".freeze

  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["articles:optimise_valuation_snippet"].reenable

    @category = Category.create!(slug: "marche-immobilier", name: { "fr" => "Marché immobilier" })
    @article = Article.create!(
      slug: SLUG,
      category: @category,
      published: true,
      title: {
        "fr" => "Comment estimer la valeur de votre bien immobilier à Monaco ?",
        "en" => "How to estimate the value of your property in Monaco?",
        "it" => "Come stimare il valore del vostro immobile a Monaco?"
      },
      body: { "fr" => "Corps FR", "en" => "EN body", "it" => "Corpo IT" },
      meta_description: {
        "fr" => "Quartier, étage, état, vue, comparables récents : les critères qui déterminent le prix de votre bien à Monaco, et comment obtenir une estimation fiable."
      }
    )
    @article.update_columns(translation_source_hash: "pinned-hash")
  end

  test "leads the FR title with the top commercial query" do
    Rake::Task["articles:optimise_valuation_snippet"].invoke
    fr = @article.reload.title["fr"]
    assert_match(/\AEstimation immobilière à Monaco/, fr)
  end

  test "leads the EN title with the property-valuation query" do
    Rake::Task["articles:optimise_valuation_snippet"].invoke
    en = @article.reload.title["en"]
    assert_match(/\AProperty valuation in Monaco/i, en)
  end

  test "adds a free-valuation CTA to both meta descriptions" do
    Rake::Task["articles:optimise_valuation_snippet"].invoke
    article = @article.reload
    assert_match(/estimation gratuite/i, article.meta_description["fr"])
    assert_match(/free .*valuation/i, article.meta_description["en"])
  end

  test "keeps every meta description within the 160-char snippet budget" do
    Rake::Task["articles:optimise_valuation_snippet"].invoke
    %w[fr en].each do |loc|
      value = @article.reload.meta_description[loc]
      assert value.length <= 160, "#{loc} meta is #{value.length} chars: #{value}"
    end
  end

  test "leaves other locales untouched and does not re-enqueue translation" do
    original_it_title = @article.title["it"]

    assert_no_enqueued_jobs do
      Rake::Task["articles:optimise_valuation_snippet"].invoke
    end

    article = @article.reload
    assert_equal original_it_title, article.title["it"], "IT title must not change"
    assert_equal "pinned-hash", article.translation_source_hash, "hash must stay pinned so no re-translation"
    assert_nil article.meta_description["it"], "IT meta must stay absent"
  end

  test "is idempotent" do
    Rake::Task["articles:optimise_valuation_snippet"].invoke
    first = @article.reload.title["fr"]
    Rake::Task["articles:optimise_valuation_snippet"].reenable
    Rake::Task["articles:optimise_valuation_snippet"].invoke
    assert_equal first, @article.reload.title["fr"]
  end

  test "aborts if the valuation article is missing" do
    @article.destroy
    error = assert_raises(SystemExit) do
      Rake::Task["articles:optimise_valuation_snippet"].invoke
    end
    assert_not error.success?
  end
end
