require "test_helper"

class ArticleTranslator::SchemaTest < ActiveSupport::TestCase
  setup do
    @properties = ArticleTranslator::Schema.properties
    @required = ArticleTranslator::Schema.required_properties
  end

  test "declares title_{locale} as required string for each target locale" do
    ArticleTranslator::LOCALES.each do |locale|
      key = :"title_#{locale}"
      assert @properties.key?(key), "schema missing #{key} property"
      assert @required.include?(key.to_s) || @required.include?(key),
             "schema does not mark #{key} as required (required: #{@required.inspect})"

      prop = @properties[key]
      assert_equal "string", prop[:type].to_s
    end
  end

  test "declares body_{locale} as optional string for each target locale" do
    ArticleTranslator::LOCALES.each do |locale|
      key = :"body_#{locale}"
      assert @properties.key?(key), "schema missing #{key} property"
      refute @required.include?(key.to_s) || @required.include?(key),
             "schema should NOT mark #{key} as required (body is optional)"

      prop = @properties[key]
      assert_equal "string", prop[:type].to_s
    end
  end
end
