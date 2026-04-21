require "ruby_llm/schema"

RubyLLM.configure do |config|
  config.anthropic_api_key = Rails.application.credentials.dig(:anthropic, :api_token)
  # Opt into the new ActiveRecord acts_as API. We don't use acts_as at all,
  # but the Railtie logs a deprecation warning on every Rails boot unless
  # this is set. Flag becomes the default in RubyLLM 2.0.
  config.use_new_acts_as = true
end
