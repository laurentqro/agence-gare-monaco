require "test_helper"

class RubyLlmInitializerTest < ActiveSupport::TestCase
  test "opts into the new acts_as API so ruby_llm does not log a deprecation warning on boot" do
    # The initializer must set use_new_acts_as = true. We don't actually use
    # acts_as anywhere in the app, but ruby_llm's Railtie loads the legacy
    # module and warns on every Rails boot unless the flag is set.
    assert RubyLLM.config.use_new_acts_as,
           "RubyLLM.config.use_new_acts_as must be true (set in config/initializers/ruby_llm.rb)"
  end
end
