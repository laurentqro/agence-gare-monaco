require "test_helper"

class ArticleAutoTranslationTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

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

  setup do
    @user = User.create!(email_address: "ed@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "ed@agencegaremonaco.com", password: "securepassword123" }
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
  end

  def canned_response(title_prefix: "Title", body_prefix: "Body")
    fields = {}
    %w[en it de sv no da fi ru].each do |locale|
      fields["title_#{locale}"] = "#{title_prefix} #{locale.upcase}"
      fields["body_#{locale}"] = "#{body_prefix} #{locale.upcase}"
    end
    fields
  end

  def with_stubbed_chat(content:, &block)
    fake = FakeChat.new(content)
    SingletonStub.with(RubyLLM, :chat, ->(**_kwargs) { fake }, &block)
  end

  test "POST create then perform job populates all 9 locales and writes translations_status" do
    perform_enqueued_jobs do
      with_stubbed_chat(content: canned_response) do
        post admin_articles_url, params: {
          article: {
            title: { fr: "Cinq raisons de vivre à Monaco" },
            body: { fr: "Première raison." },
            slug: "cinq-raisons",
            category_id: @category.id
          }
        }
      end
    end

    article = Article.find_by(slug: "cinq-raisons")
    assert_not_nil article

    assert_equal "Cinq raisons de vivre à Monaco", article.title["fr"]
    %w[en it de sv no da fi ru].each do |locale|
      assert_equal "Title #{locale.upcase}", article.title[locale]
      assert_equal "Body #{locale.upcase}", article.body[locale]
      assert article.translations_status[locale]["translated_at"].present?
    end
    assert article.translation_source_hash.present?
  end

  test "markdown is preserved through translation: heading, bold, image with alt" do
    markdown_response = {}
    %w[en it de sv no da fi ru].each do |locale|
      markdown_response["title_#{locale}"] = "Heading #{locale.upcase}"
      markdown_response["body_#{locale}"] = <<~MD.strip
        # Heading #{locale.upcase}

        Some **bold** text in #{locale.upcase}.

        ![translated alt #{locale}](https://example.com/photo.jpg)
      MD
    end

    perform_enqueued_jobs do
      with_stubbed_chat(content: markdown_response) do
        post admin_articles_url, params: {
          article: {
            title: { fr: "Mon titre" },
            body: { fr: "# Titre\n\nDu texte **gras**.\n\n![alt fr](https://example.com/photo.jpg)" },
            slug: "markdown-preservation",
            category_id: @category.id
          }
        }
      end
    end

    article = Article.find_by(slug: "markdown-preservation")
    %w[en it].each do |locale|
      body = article.body[locale]
      assert_match(/^# /, body, "heading marker preserved for #{locale}")
      assert_includes body, "**", "bold markers preserved for #{locale}"
      assert_includes body, "https://example.com/photo.jpg", "image URL preserved for #{locale}"
      assert_match(/!\[.+?\]\(https:\/\/example\.com\/photo\.jpg\)/, body, "image syntax intact for #{locale}")
    end
  end

  test "re-saving without changing FR text does not re-translate" do
    article = Article.create!(
      title: { "fr" => "Stable title" },
      body: { "fr" => "Stable body." },
      slug: "stable",
      category: @category
    )
    # Initial translation
    perform_enqueued_jobs do
      with_stubbed_chat(content: canned_response) do
        ArticleTranslationJob.perform_later(article.id)
      end
    end
    article.reload
    original_hash = article.translation_source_hash
    original_translated_at = article.translations_status["en"]["translated_at"]

    # Save again with no FR change — featured toggle only
    call_count = 0
    SingletonStub.with(RubyLLM, :chat, ->(**_kwargs) { call_count += 1; FakeChat.new(canned_response) }) do
      perform_enqueued_jobs do
        patch admin_article_url(article), params: { article: { featured: "1" } }
      end
    end

    article.reload
    assert article.featured
    assert_equal original_hash, article.translation_source_hash
    assert_equal original_translated_at, article.translations_status["en"]["translated_at"]
    assert_equal 0, call_count, "RubyLLM.chat should not be called when FR text is unchanged"
  end

  test "saving with new FR text re-runs translation" do
    article = Article.create!(
      title: { "fr" => "Original FR" },
      body: { "fr" => "Original body" },
      slug: "evolving",
      category: @category
    )
    perform_enqueued_jobs do
      with_stubbed_chat(content: canned_response(title_prefix: "First")) do
        ArticleTranslationJob.perform_later(article.id)
      end
    end
    article.reload
    first_hash = article.translation_source_hash

    perform_enqueued_jobs do
      with_stubbed_chat(content: canned_response(title_prefix: "Second")) do
        patch admin_article_url(article), params: {
          article: { title: { fr: "Updated FR title" } }
        }
      end
    end

    article.reload
    refute_equal first_hash, article.translation_source_hash
    assert_equal "Second EN", article.title["en"]
  end
end
