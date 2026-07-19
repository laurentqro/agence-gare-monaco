class ArticleTranslator::Schema < RubyLLM::Schema
  string :title, description: "Article title translated into the requested target language"
  string :body, description: "Article body (markdown) translated into the requested target language", required: false
  string :meta_description, description: "SEO meta description translated into the requested target language (only when a French meta description is provided)", required: false
end
