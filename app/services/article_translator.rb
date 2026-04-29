class ArticleTranslator
  DEFAULT_MODEL = "claude-sonnet-4-6".freeze

  LOCALE_NAMES = {
    "en" => "English",
    "it" => "Italian",
    "de" => "German",
    "sv" => "Swedish",
    "no" => "Norwegian (Bokmål)",
    "da" => "Danish",
    "fi" => "Finnish",
    "ru" => "Russian"
  }.freeze

  LOCALES = LOCALE_NAMES.keys.freeze

  def self.model
    Rails.configuration.x.translator_model.presence || DEFAULT_MODEL
  end

  class BlankTranslation < StandardError; end
end
