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

  # ---- helpers ----

  class FakeChat
    def initialize(content_per_locale, input_tokens: 100, output_tokens: 200)
      @content_per_locale = content_per_locale # Hash[locale_string => content_hash] OR a Proc(locale) -> content_hash
      @input_tokens = input_tokens
      @output_tokens = output_tokens
      @last_locale = nil
    end

    def with_instructions(prompt)
      # remember the locale-mention so #ask can route to the right canned response
      ArticleTranslator::LOCALE_NAMES.each do |code, name|
        if prompt.include?(name)
          @last_locale = code
          break
        end
      end
      self
    end

    def with_schema(_); self; end

    def ask(_user_prompt)
      content = if @content_per_locale.respond_to?(:call)
        @content_per_locale.call(@last_locale)
      else
        @content_per_locale.fetch(@last_locale)
      end
      Struct.new(:content, :input_tokens, :output_tokens)
        .new(content, @input_tokens, @output_tokens)
    end
  end

  # Builds {locale => {"title"=>..., "body"=>...}} for all 8 target locales.
  def canned_responses(title_prefix: "Title", body_prefix: "Body")
    %w[en it de sv no da fi ru].each_with_object({}) do |loc, h|
      h[loc] = { "title" => "#{title_prefix} #{loc.upcase}", "body" => "#{body_prefix} #{loc.upcase}" }
    end
  end

  def with_stubbed_chat(content_per_locale:, &block)
    fake = FakeChat.new(content_per_locale)
    call_count = 0
    SingletonStub.with(RubyLLM, :chat, ->(**_kwargs) { call_count += 1; fake }, &block)
    call_count
  end

  def with_failing_chat(&block)
    called = false
    SingletonStub.with(RubyLLM, :chat, ->(**_kwargs) { called = true; raise "should not be called" }, &block)
    called
  end

  # ---- constants ----

  test "LOCALES equals I18n.available_locales minus :fr" do
    expected = I18n.available_locales.map(&:to_s) - %w[fr]
    assert_equal expected.sort, ArticleTranslator::LOCALES.sort
  end

  test "LOCALE_NAMES plus FR covers exactly I18n.available_locales" do
    app_locales = I18n.available_locales.map(&:to_s).sort
    translator_locales = (ArticleTranslator::LOCALE_NAMES.keys + [ "fr" ]).sort
    assert_equal app_locales, translator_locales
  end

  # ---- skip-when-fully-translated ----

  test "skips API call entirely when source hash matches current FR title+body" do
    fr_title = @article.title["fr"]
    fr_body = @article.body["fr"]
    expected_hash = Digest::SHA256.hexdigest("#{fr_title}\n#{fr_body}")
    @article.update_columns(translation_source_hash: expected_hash)

    called = with_failing_chat do
      ArticleTranslator.new(@article).translate!
    end
    refute called
  end

  # ---- happy path ----

  test "writes all 8 target locales to title and body, preserves FR, sets timestamps" do
    with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end

    @article.reload
    %w[en it de sv no da fi ru].each do |locale|
      assert_equal "Title #{locale.upcase}", @article.title[locale]
      assert_equal "Body #{locale.upcase}", @article.body[locale]
      assert @article.translations_status[locale]["translated_at"].present?
    end
    assert_equal "Cinq raisons de vivre à Monaco", @article.title["fr"]
    assert_equal "Première raison : le climat. Deuxième raison : la sécurité.", @article.body["fr"]
  end

  # ---- per-locale slugs (SEO audit 0.2) ----

  test "mints a per-locale slug from each translated title" do
    with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end

    @article.reload
    %w[en it de sv no da fi ru].each do |locale|
      assert_equal "title-#{locale}", @article.slugs[locale],
        "expected a localised slug derived from the #{locale} title"
    end
  end

  test "never writes an fr slug into the slugs hash" do
    with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end

    assert_not_includes @article.reload.slugs.keys, "fr"
    assert_equal "cinq-raisons-de-vivre-a-monaco", @article.slug
  end

  test "freezes an existing per-locale slug across a re-translation after an FR edit" do
    with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end
    assert_equal "title-en", @article.reload.slugs["en"]

    # FR title changes -> hash goes stale -> the whole article re-translates with
    # NEW titles. The slug must NOT move (the old URL is already indexed).
    @article.update!(title: @article.title.merge("fr" => "Titre modifié"))
    new_responses = %w[en it de sv no da fi ru].each_with_object({}) do |loc, h|
      h[loc] = { "title" => "Completely New #{loc.upcase}", "body" => "Body #{loc.upcase}" }
    end
    # A fresh instance, as each web request / job loads one (current_fr_hash is
    # memoized per-instance, so the job always runs on a freshly-loaded record).
    with_stubbed_chat(content_per_locale: new_responses) do
      ArticleTranslator.new(Article.find(@article.id)).translate!
    end

    @article.reload
    assert_equal "Completely New EN", @article.title["en"], "title should update"
    assert_equal "title-en", @article.slugs["en"], "slug should stay frozen"
  end

  test "the minted Russian slug is ASCII-safe" do
    responses = canned_responses
    responses["ru"] = { "title" => "Как продать недвижимость в Монако", "body" => "Body RU" }

    with_stubbed_chat(content_per_locale: responses) do
      ArticleTranslator.new(@article).translate!
    end

    ru = @article.reload.slugs["ru"]
    assert ru.present?, "expected a Russian slug"
    assert_match(/\A[a-z0-9-]+\z/, ru, "Russian slug must be ASCII-safe: #{ru}")
  end

  test "writes meta_description for all target locales when FR meta description present" do
    @article.update!(meta_description: { "fr" => "Résumé FR." })
    responses = %w[en it de sv no da fi ru].each_with_object({}) do |loc, h|
      h[loc] = { "title" => "Title #{loc.upcase}", "body" => "Body #{loc.upcase}", "meta_description" => "Meta #{loc.upcase}" }
    end

    with_stubbed_chat(content_per_locale: responses) do
      ArticleTranslator.new(@article).translate!
    end

    @article.reload
    %w[en it de sv no da fi ru].each do |locale|
      assert_equal "Meta #{locale.upcase}", @article.meta_description[locale]
    end
    assert_equal "Résumé FR.", @article.meta_description["fr"]
  end

  test "raises BlankTranslation when meta_description is required but blank in the response" do
    @article.update!(meta_description: { "fr" => "Résumé FR." })
    bad = ->(loc) { { "title" => "T #{loc}", "body" => "B #{loc}", "meta_description" => "  " } }

    assert_raises ArticleTranslator::BlankTranslation do
      with_stubbed_chat(content_per_locale: bad) do
        ArticleTranslator.new(@article).translate!
      end
    end
  end

  test "calls the LLM exactly once per target locale" do
    count = with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end
    assert_equal 8, count
  end

  test "updates translation_source_hash to SHA256 of FR title+body once all locales land" do
    with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end
    @article.reload
    expected = Digest::SHA256.hexdigest("Cinq raisons de vivre à Monaco\nPremière raison : le climat. Deuxième raison : la sécurité.")
    assert_equal expected, @article.translation_source_hash
  end

  test "stores per-locale source_hash so we can skip on retry" do
    with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end
    @article.reload
    expected = Digest::SHA256.hexdigest("Cinq raisons de vivre à Monaco\nPremière raison : le climat. Deuxième raison : la sécurité.")
    %w[en it de sv no da fi ru].each do |locale|
      assert_equal expected, @article.translations_status[locale]["source_hash"],
                   "expected per-locale source_hash for #{locale}"
    end
  end

  test "clears _error key on successful translation" do
    @article.update_columns(translations_status: { "_error" => { "class" => "RubyLLM::ContextLengthExceededError", "message" => "old" } })
    with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end
    @article.reload
    refute @article.translations_status.key?("_error"), "_error should be cleared on success"
  end

  # ---- per-locale skip on retry ----

  test "skips locales whose stored source_hash already matches current FR" do
    fr_hash = Digest::SHA256.hexdigest("Cinq raisons de vivre à Monaco\nPremière raison : le climat. Deuxième raison : la sécurité.")
    # Simulate a prior partial run: en+it+de already translated for current FR.
    @article.update_columns(
      title: @article.title.merge("en" => "Already EN", "it" => "Already IT", "de" => "Already DE"),
      translations_status: {
        "en" => { "translated_at" => "2026-04-29T10:00:00Z", "source_hash" => fr_hash },
        "it" => { "translated_at" => "2026-04-29T10:00:00Z", "source_hash" => fr_hash },
        "de" => { "translated_at" => "2026-04-29T10:00:00Z", "source_hash" => fr_hash }
      }
    )

    count = with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end

    @article.reload
    assert_equal 5, count, "should only call LLM for the 5 missing locales (sv, no, da, fi, ru)"
    assert_equal "Already EN", @article.title["en"], "existing translation should not be overwritten"
    assert_equal "Title SV", @article.title["sv"], "missing locale should now be translated"
  end

  test "re-translates locales whose stored source_hash does not match current FR" do
    stale_hash = "stale-from-previous-fr-version"
    @article.update_columns(
      title: @article.title.merge("en" => "Outdated EN"),
      translations_status: {
        "en" => { "translated_at" => "2026-01-01T00:00:00Z", "source_hash" => stale_hash }
      }
    )

    with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end

    @article.reload
    assert_equal "Title EN", @article.title["en"], "stale locale should be re-translated"
  end

  # ---- partial failure: write-as-you-go ----

  test "preserves locales translated before a mid-loop LLM failure" do
    failing = ->(loc) {
      raise "boom on swedish" if loc == "sv"
      { "title" => "Title #{loc.upcase}", "body" => "Body #{loc.upcase}" }
    }
    SingletonStub.with(RubyLLM, :chat, ->(**_kwargs) { FakeChat.new(failing) }) do
      assert_raises(RuntimeError, "boom on swedish") do
        ArticleTranslator.new(@article).translate!
      end
    end

    @article.reload
    # The locales translated before sv (in iteration order) should be persisted.
    locales_before_sv = %w[en it de] # whatever ArticleTranslator::LOCALES happens to be, sv comes after these
    locales_before_sv.each do |loc|
      assert_equal "Title #{loc.upcase}", @article.title[loc],
                   "expected #{loc} to be persisted before sv failure"
      assert @article.translations_status[loc]["translated_at"].present?
    end
    assert_nil @article.title["sv"], "failed locale should not be persisted"
  end

  test "does not finalize translation_source_hash when a locale fails" do
    failing = ->(loc) {
      raise "boom" if loc == "sv"
      { "title" => "T", "body" => "B" }
    }
    SingletonStub.with(RubyLLM, :chat, ->(**_kwargs) { FakeChat.new(failing) }) do
      assert_raises(RuntimeError) { ArticleTranslator.new(@article).translate! }
    end
    @article.reload
    assert_nil @article.translation_source_hash,
               "source hash must only be set when ALL 8 locales are present"
  end

  # ---- BlankTranslation guards ----

  test "raises BlankTranslation when title field is empty string" do
    bad = canned_responses
    bad["de"] = { "title" => "   ", "body" => "Body DE" }
    with_stubbed_chat(content_per_locale: bad) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
  end

  test "raises BlankTranslation when title field is missing" do
    bad = canned_responses
    bad["en"] = { "body" => "no title here" }
    with_stubbed_chat(content_per_locale: bad) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
  end

  test "raises BlankTranslation when title field is non-string" do
    bad = canned_responses
    bad["de"] = { "title" => { "text" => "der titel" }, "body" => "ok" }
    with_stubbed_chat(content_per_locale: bad) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
  end

  test "raises BlankTranslation when body field is empty string for non-blank FR" do
    bad = canned_responses
    bad["sv"] = { "title" => "Title SV", "body" => "" }
    with_stubbed_chat(content_per_locale: bad) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
  end

  test "raises BlankTranslation when body field is nil for non-blank FR" do
    bad = canned_responses
    bad["sv"] = { "title" => "Title SV", "body" => nil }
    with_stubbed_chat(content_per_locale: bad) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
  end

  test "BlankTranslation does not finalize translation_source_hash" do
    @article.update_columns(translation_source_hash: nil)
    bad = canned_responses
    bad["en"] = { "title" => "", "body" => "x" }
    with_stubbed_chat(content_per_locale: bad) do
      assert_raises(ArticleTranslator::BlankTranslation) do
        ArticleTranslator.new(@article).translate!
      end
    end
    @article.reload
    assert_nil @article.translation_source_hash
  end

  # ---- title-only article ----

  test "skips body translation when FR body is blank (title-only article)" do
    @article.update_columns(body: { "fr" => "" })

    titles_only = %w[en it de sv no da fi ru].each_with_object({}) do |loc, h|
      h[loc] = { "title" => "Title #{loc.upcase}" }
    end

    with_stubbed_chat(content_per_locale: titles_only) do
      ArticleTranslator.new(@article).translate!
    end

    @article.reload
    %w[en it de sv no da fi ru].each do |locale|
      assert_equal "Title #{locale.upcase}", @article.title[locale]
      assert_nil @article.body[locale], "should not write body for #{locale} when FR body was blank"
    end
  end

  # ---- logging ----

  test "logs token usage at info level for each locale" do
    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    begin
      with_stubbed_chat(content_per_locale: canned_responses) do
        ArticleTranslator.new(@article).translate!
      end
    ensure
      Rails.logger = original_logger
    end
    log = io.string
    assert_match(/\[ArticleTranslator\]/, log)
    assert_match(/article=#{@article.id}/, log)
    assert_match(/llm_response/, log)
    assert_match(/locale=en/, log)
    assert_match(/locale=ru/, log)
  end

  test "logs start, completion, and skip events" do
    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    begin
      with_stubbed_chat(content_per_locale: canned_responses) do
        ArticleTranslator.new(@article).translate!
      end
    ensure
      Rails.logger = original_logger
    end
    log = io.string
    assert_match(/\[ArticleTranslator\] article=#{@article.id} starting/, log)
    assert_match(/\[ArticleTranslator\] article=#{@article.id} completed/, log)
  end

  test "logs when source hash matches and translation is skipped" do
    fr_title = @article.title["fr"]
    fr_body = @article.body["fr"]
    expected_hash = Digest::SHA256.hexdigest("#{fr_title}\n#{fr_body}")
    @article.update_columns(translation_source_hash: expected_hash)

    io = StringIO.new
    original_logger = Rails.logger
    Rails.logger = ActiveSupport::Logger.new(io)
    begin
      with_failing_chat do
        ArticleTranslator.new(@article).translate!
      end
    ensure
      Rails.logger = original_logger
    end
    assert_match(/\[ArticleTranslator\] article=#{@article.id} skipped \(source unchanged\)/, io.string)
  end

  test "bumps updated_at on success" do
    @article.update_columns(updated_at: 2.days.ago)
    original = @article.updated_at
    with_stubbed_chat(content_per_locale: canned_responses) do
      ArticleTranslator.new(@article).translate!
    end
    @article.reload
    assert_operator @article.updated_at, :>, original
  end

  test "uses the model configured on Rails.configuration" do
    received_model = nil
    canned = canned_responses
    chat_builder = ->(**kwargs) {
      received_model ||= kwargs[:model]
      FakeChat.new(canned)
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
