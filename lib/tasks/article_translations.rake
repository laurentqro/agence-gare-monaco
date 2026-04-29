namespace :articles do
  # Stagger window: each LLM call is ~20s and we make 8 per article. Leaving
  # 30s between enqueues spaces them so concurrent Solid Queue workers don't
  # all hammer the Anthropic API at once and trip rate limits.
  RETRANSLATE_STAGGER_SECONDS = 30

  desc "Re-translate all articles (nullifies translation_source_hash, enqueues a staggered job per article)"
  task retranslate_all: :environment do
    count = 0
    Article.find_each.with_index do |article, i|
      article.update_columns(translation_source_hash: nil)
      ArticleTranslationJob.set(wait: (i * RETRANSLATE_STAGGER_SECONDS).seconds).perform_later(article.id)
      count += 1
    end
    puts "Enqueued re-translation for #{count} article(s) (staggered every #{RETRANSLATE_STAGGER_SECONDS}s)"
  end

  desc "Re-translate one article by id"
  task :retranslate, [ :id ] => :environment do |_, args|
    abort "Usage: rake articles:retranslate[ID]" if args[:id].blank?
    article = Article.find_by(id: args[:id])
    abort "Article #{args[:id]} not found" unless article
    article.update_columns(translation_source_hash: nil)
    ArticleTranslationJob.perform_later(article.id)
    puts "Enqueued re-translation for article #{article.id}"
  end
end
