require "test_helper"

class ArticleTranslatorTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    @article = Article.create!(
      title: { "fr" => "Cinq raisons de vivre à Monaco" },
      body: { "fr" => "Première raison : le climat. Deuxième raison : la sécurité." },
      slug: "cinq-raisons-de-vivre-a-monaco",
      category: @category
    )
  end

  def canned_response(overrides = {})
    fields = {}
    %w[en it de sv no da fi ru].each do |locale|
      fields["title_#{locale}"] = "Title in #{locale.upcase}"
      fields["body_#{locale}"] = "Body in #{locale.upcase}"
    end
    fields.merge(overrides)
  end

  class FakeChat
    def initialize(content, input_tokens: 200, output_tokens: 800)
      @content = content
      @input_tokens = input_tokens
      @output_tokens = output_tokens
    end
    def with_instructions(_); self; end
    def with_schema(_); self; end
    def ask(_)
      Struct.new(:content, :input_tokens, :output_tokens)
        .new(@content, @input_tokens, @output_tokens)
    end
  end

  def with_stubbed_chat(content:, &block)
    fake = FakeChat.new(content)
    call_count = 0
    SingletonStub.with(RubyLLM, :chat, ->(**_kwargs) { call_count += 1; fake }, &block)
    call_count
  end

  def with_failing_chat(&block)
    called = false
    SingletonStub.with(RubyLLM, :chat, ->(**_kwargs) { called = true; raise "should not be called" }, &block)
    called
  end

  test "LOCALES equals I18n.available_locales minus :fr" do
    expected = I18n.available_locales.map(&:to_s) - %w[fr]
    assert_equal expected.sort, ArticleTranslator::LOCALES.sort
  end

  test "LOCALE_NAMES plus FR covers exactly I18n.available_locales" do
    app_locales = I18n.available_locales.map(&:to_s).sort
    translator_locales = (ArticleTranslator::LOCALE_NAMES.keys + [ "fr" ]).sort
    assert_equal app_locales, translator_locales
  end

  test "skips API call when source hash matches current FR title+body" do
    fr_title = @article.title["fr"]
    fr_body = @article.body["fr"]
    expected_hash = Digest::SHA256.hexdigest("#{fr_title}\n#{fr_body}")
    @article.update_columns(translation_source_hash: expected_hash)

    called = with_failing_chat do
      ArticleTranslator.new(@article).translate!
    end
    refute called
  end

  test "writes all 8 target locales to title and body, preserves FR, sets timestamps" do
    with_stubbed_chat(content: canned_response) do
      ArticleTranslator.new(@article).translate!
    end

    @article.reload
    %w[en it de sv no da fi ru].each do |locale|
      assert_equal "Title in #{locale.upcase}", @article.title[locale]
      assert_equal "Body in #{locale.upcase}", @article.body[locale]
      assert @article.translations_status[locale]["translated_at"].present?
    end
    assert_equal "Cinq raisons de vivre à Monaco", @article.title["fr"]
    assert_equal "Première raison : le climat. Deuxième raison : la sécurité.", @article.body["fr"]
  end

  test "updates translation_source_hash to SHA256 of FR title+body" do
    with_stubbed_chat(content: canned_response) do
      ArticleTranslator.new(@article).translate!
    end
    @article.reload
    expected = Digest::SHA256.hexdigest("Cinq raisons de vivre à Monaco\nPremière raison : le climat. Deuxième raison : la sécurité.")
    assert_equal expected, @article.translation_source_hash
  end

  test "clears _error key on successful translation" do
    @article.update_columns(translations_status: { "_error" => { "class" => "RubyLLM::ContextLengthExceededError", "message" => "old" } })
    with_stubbed_chat(content: canned_response) do
      ArticleTranslator.new(@article).translate!
    end
    @article.reload
    refute @article.translations_status.key?("_error"), "_error should be cleared on success"
  end

  test "raises BlankTranslation when title field is empty string" do
    with_stubbed_chat(content: canned_response.merge("title_de" => "   ")) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
  end

  test "raises BlankTranslation when title field is missing" do
    response = canned_response
    response.delete("title_en")
    with_stubbed_chat(content: response) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
  end

  test "raises BlankTranslation when title field is non-string" do
    with_stubbed_chat(content: canned_response.merge("title_de" => { "text" => "Der Titel" })) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
  end

  test "raises BlankTranslation when body field is empty string for non-blank FR" do
    with_stubbed_chat(content: canned_response.merge("body_sv" => "")) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
  end

  test "BlankTranslation does not update translation_source_hash" do
    @article.update_columns(translation_source_hash: nil)
    with_stubbed_chat(content: canned_response.merge("title_en" => "")) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
    @article.reload
    assert_nil @article.translation_source_hash
  end

  test "skips body translation when FR body is blank (title-only article)" do
    @article.update_columns(body: { "fr" => "" })

    response = {}
    %w[en it de sv no da fi ru].each do |locale|
      response["title_#{locale}"] = "Title #{locale.upcase}"
    end

    with_stubbed_chat(content: response) do
      ArticleTranslator.new(@article).translate!
    end

    @article.reload
    %w[en it de sv no da fi ru].each do |locale|
      assert_equal "Title #{locale.upcase}", @article.title[locale]
      assert_nil @article.body[locale], "should not write body for #{locale} when FR body was blank"
    end
  end

  test "does not overwrite when another job updated the hash between load and write" do
    canonical_hash = Digest::SHA256.hexdigest("#{@article.title['fr']}\n#{@article.body['fr']}")
    @article.update_columns(translation_source_hash: "stale-from-old-load")
    translator = ArticleTranslator.new(@article)

    Article.where(id: @article.id).update_all(
      translation_source_hash: canonical_hash,
      title: { "fr" => @article.title["fr"], "en" => "From faster worker" }
    )

    with_stubbed_chat(content: canned_response) do
      translator.translate!
    end

    @article.reload
    assert_equal "From faster worker", @article.title["en"],
                 "slower job must not overwrite the faster job's result"
    assert_equal canonical_hash, @article.translation_source_hash
  end

  test "logs token usage at info level" do
    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    begin
      with_stubbed_chat(content: canned_response) do
        ArticleTranslator.new(@article).translate!
      end
    ensure
      Rails.logger = original_logger
    end
    log = io.string
    assert_match(/\[ArticleTranslator\]/, log)
    assert_match(/article=#{@article.id}/, log)
    assert_match(/in=200/, log)
    assert_match(/out=800/, log)
  end

  test "bumps updated_at on success" do
    @article.update_columns(updated_at: 2.days.ago)
    original = @article.updated_at
    with_stubbed_chat(content: canned_response) do
      ArticleTranslator.new(@article).translate!
    end
    @article.reload
    assert_operator @article.updated_at, :>, original
  end

  test "uses the model configured on Rails.configuration" do
    received_model = nil
    fake = FakeChat.new(canned_response)
    chat_builder = ->(**kwargs) {
      received_model = kwargs[:model]
      fake
    }

    previous = Rails.configuration.x.translator_model
    Rails.configuration.x.translator_model = "claude-haiku-4-5"
    begin
      SingletonStub.with(RubyLLM, :chat, chat_builder) do
        ArticleTranslator.new(@article).translate!
      end
    ensure
      Rails.configuration.x.translator_model = previous
    end

    assert_equal "claude-haiku-4-5", received_model
  end
end
