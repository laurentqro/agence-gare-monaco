namespace :articles do
  desc "Re-translate all articles (nullifies translation_source_hash, enqueues job per article)"
  task retranslate_all: :environment do
    count = 0
    Article.find_each do |article|
      article.update_columns(translation_source_hash: nil)
      ArticleTranslationJob.perform_later(article.id)
      count += 1
    end
    puts "Enqueued re-translation for #{count} article(s)"
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
