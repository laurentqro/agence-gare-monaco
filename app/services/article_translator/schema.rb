class ArticleTranslator::Schema < RubyLLM::Schema
  string :title, description: "Article title translated into the requested target language"
  string :body, description: "Article body (markdown) translated into the requested target language", required: false
end
