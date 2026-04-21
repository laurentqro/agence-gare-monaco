class PropertyTranslator::Schema < RubyLLM::Schema
  LOCALES = %w[en it de sv no da fi ru].freeze

  LOCALES.each do |locale|
    string :"title_#{locale}", description: "Property title translated to #{locale.upcase}"
    string :"description_#{locale}", description: "Property description translated to #{locale.upcase}"
  end
end
