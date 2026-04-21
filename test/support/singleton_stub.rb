module SingletonStub
  # Temporarily replaces a singleton method on `receiver` with the given
  # `replacement` proc, runs the block, and restores the original on ensure —
  # even if the block raises. Used to stub module-level methods like
  # RubyLLM.chat or PropertyTranslator.new without pulling in a mocking
  # library.
  #
  # Example:
  #   SingletonStub.with(RubyLLM, :chat, ->(**_kwargs) { fake_chat }) do
  #     PropertyTranslator.new(property).translate!
  #   end
  def self.with(receiver, method_name, replacement)
    backup = :"#{method_name}_singleton_stub_original"
    receiver.singleton_class.alias_method(backup, method_name)
    receiver.singleton_class.define_method(method_name, &replacement)
    begin
      yield
    ensure
      receiver.singleton_class.alias_method(method_name, backup)
      receiver.singleton_class.remove_method(backup)
    end
  end
end
