require "test_helper"

class ArticleTranslator::SchemaTest < ActiveSupport::TestCase
  setup do
    @properties = ArticleTranslator::Schema.properties
    @required = ArticleTranslator::Schema.required_properties
  end

  test "declares title as a required string" do
    assert @properties.key?(:title), "schema missing :title"
    assert(@required.include?("title") || @required.include?(:title),
           "schema does not mark :title as required (required: #{@required.inspect})")
    assert_equal "string", @properties[:title][:type].to_s
  end

  test "declares body as an optional string" do
    assert @properties.key?(:body), "schema missing :body"
    refute(@required.include?("body") || @required.include?(:body),
           "schema should NOT mark :body as required (body is optional for title-only articles)")
    assert_equal "string", @properties[:body][:type].to_s
  end

  test "schema has no per-locale fields" do
    ArticleTranslator::LOCALES.each do |locale|
      refute @properties.key?(:"title_#{locale}"), "schema should not have title_#{locale}"
      refute @properties.key?(:"body_#{locale}"), "schema should not have body_#{locale}"
    end
  end
end
