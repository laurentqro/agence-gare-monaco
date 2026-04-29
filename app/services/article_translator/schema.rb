class ArticleTranslator::Schema < RubyLLM::Schema
  ArticleTranslator::LOCALES.each do |locale|
    string :"title_#{locale}", description: "Article title translated to #{locale.upcase}"
    string :"body_#{locale}", description: "Article body (markdown) translated to #{locale.upcase}", required: false
  end
end
