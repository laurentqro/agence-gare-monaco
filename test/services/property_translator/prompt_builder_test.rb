require "test_helper"

class PropertyTranslator::PromptBuilderTest < ActiveSupport::TestCase
  def make_property(district: nil, building: nil, **overrides)
    Property.new({
      reference: "MC-PB-001",
      title: { "fr" => "Penthouse vue mer" },
      description: { "fr" => "Superbe penthouse." },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      num_rooms: 5,
      published: true,
      district: district,
      building: building
    }.merge(overrides))
  end

  test "system prompt includes every entry in MonacoGlossary::ALL" do
    builder = PropertyTranslator::PromptBuilder.new(make_property)
    prompt = builder.system_prompt

    MonacoGlossary::ALL.each do |term|
      assert_includes prompt, term, "system prompt missing glossary term #{term.inspect}"
    end
  end

  test "system prompt still includes per-property district and building names" do
    district = District.create!(name: "Mareterra", city: "Monaco")
    building = Building.create!(name: "Tour Z", city: "Monaco")
    builder = PropertyTranslator::PromptBuilder.new(make_property(district: district, building: building))

    prompt = builder.system_prompt

    assert_includes prompt, "Mareterra"
    assert_includes prompt, "Tour Z"
  end

  test "system prompt does not duplicate names that overlap with the constant" do
    district = District.create!(name: "Carré d'Or", city: "Monaco")
    builder = PropertyTranslator::PromptBuilder.new(make_property(district: district))

    occurrences = builder.system_prompt.scan(/^- Carré d'Or$/).length

    assert_equal 1, occurrences, "Carré d'Or should appear exactly once in the glossary list"
  end

  test "system prompt mentions all 8 target language names" do
    builder = PropertyTranslator::PromptBuilder.new(make_property)
    prompt = builder.system_prompt

    %w[English Italian German Swedish Norwegian Danish Finnish Russian].each do |lang|
      assert_includes prompt, lang, "system prompt missing language name #{lang}"
    end
  end

  test "user prompt wraps FR title and description in tags" do
    builder = PropertyTranslator::PromptBuilder.new(make_property)
    prompt = builder.user_prompt

    assert_match %r{<french_title>.*Penthouse vue mer.*</french_title>}m, prompt
    assert_match %r{<french_description>.*Superbe penthouse\..*</french_description>}m, prompt
  end
end
