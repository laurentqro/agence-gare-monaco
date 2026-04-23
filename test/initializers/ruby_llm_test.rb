require "test_helper"

class RubyLlmInitializerTest < ActiveSupport::TestCase
  test "opts into the new acts_as API so ruby_llm does not log a deprecation warning on boot" do
    assert RubyLLM.config.use_new_acts_as,
           "RubyLLM.config.use_new_acts_as must be true (set in config/initializers/ruby_llm.rb)"
  end
end
