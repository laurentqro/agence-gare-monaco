require "test_helper"

class PropertyTranslatorTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @district = District.create!(name: "Carré d'Or", city: "Monaco")
    @building = Building.create!(name: "Le Mirabeau", city: "Monaco")
    @property = Property.create!(
      reference: "MC-TR-001",
      title: { "fr" => "Penthouse vue mer" },
      description: { "fr" => "Superbe penthouse avec vue panoramique sur le port." },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      district: @district,
      building: @building,
      num_rooms: 5,
      published: true
    )
  end

  def canned_response
    fields = {}
    %w[en it de sv no da fi ru].each do |locale|
      fields["title_#{locale}"] = "Title in #{locale.upcase}"
      fields["description_#{locale}"] = "Description in #{locale.upcase}"
    end
    fields
  end

  class FakeChat
    def initialize(content); @content = content; end
    def with_instructions(_); self; end
    def with_schema(_); self; end
    def ask(_); Struct.new(:content).new(@content); end
  end

  def with_stubbed_chat(content:)
    fake = FakeChat.new(content)
    call_count = 0
    RubyLLM.singleton_class.alias_method(:chat_original, :chat)
    RubyLLM.singleton_class.define_method(:chat) { |**_kwargs| call_count += 1; fake }
    begin
      yield
    ensure
      RubyLLM.singleton_class.alias_method(:chat, :chat_original)
      RubyLLM.singleton_class.remove_method(:chat_original)
    end
    call_count
  end

  def with_failing_chat(&block)
    called = false
    RubyLLM.singleton_class.alias_method(:chat_original, :chat)
    RubyLLM.singleton_class.define_method(:chat) { |**_kwargs| called = true; raise "should not be called" }
    begin
      block.call
    ensure
      RubyLLM.singleton_class.alias_method(:chat, :chat_original)
      RubyLLM.singleton_class.remove_method(:chat_original)
    end
    called
  end

  test "populates 8 non-FR locales, preserves FR, updates hash and status, enqueues brochure job" do
    with_stubbed_chat(content: canned_response) do
      assert_enqueued_with(job: PropertyBrochureGenerationJob, args: [ @property.id ]) do
        PropertyTranslator.new(@property).translate!
      end
    end

    @property.reload
    %w[en it de sv no da fi ru].each do |locale|
      assert_equal "Title in #{locale.upcase}", @property.title[locale]
      assert_equal "Description in #{locale.upcase}", @property.description[locale]
      assert @property.translations_status[locale]["translated_at"].present?
    end
    assert_equal "Penthouse vue mer", @property.title["fr"]
    assert_equal "Superbe penthouse avec vue panoramique sur le port.", @property.description["fr"]
    assert @property.translation_source_hash.present?
  end

  test "returns early when content hash is unchanged" do
    fr_title = @property.title["fr"]
    fr_description = @property.description["fr"]
    expected_hash = Digest::SHA256.hexdigest("#{fr_title}\n#{fr_description}")
    @property.update_columns(translation_source_hash: expected_hash)

    called = with_failing_chat do
      PropertyTranslator.new(@property).translate!
    end
    refute called
  end

  test "blank title field raises BlankTranslation" do
    with_stubbed_chat(content: canned_response.merge("title_de" => "   ")) do
      assert_raises(PropertyTranslator::BlankTranslation) do
        PropertyTranslator.new(@property).translate!
      end
    end
  end

  test "empty FR description preserves existing descriptions and still translates titles" do
    @property.update_columns(
      description: { "fr" => "", "en" => "existing en description" }
    )
    with_stubbed_chat(content: canned_response) do
      PropertyTranslator.new(@property).translate!
    end

    @property.reload
    assert_equal "existing en description", @property.description["en"]
    assert_equal "Title in EN", @property.title["en"]
  end

  test "glossary includes district and building names" do
    builder = PropertyTranslator::PromptBuilder.new(@property)
    assert_includes builder.system_prompt, "Carré d'Or"
    assert_includes builder.system_prompt, "Le Mirabeau"
    assert_includes builder.system_prompt, "Monaco"
    assert_includes builder.system_prompt, "Monte-Carlo"
  end
end
