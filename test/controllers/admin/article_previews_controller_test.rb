require "test_helper"

class Admin::ArticlePreviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
  end

  # Authentication
  test "redirects unauthenticated users to login" do
    delete session_url # log out
    post admin_article_preview_url, params: { body: "# Hello" }
    assert_redirected_to new_session_url
  end

  # Preview rendering
  test "POST create returns Turbo Stream response with rendered markdown" do
    post admin_article_preview_url, params: { body: "**bold text**" }, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
    assert_includes response.body, "<strong>bold text</strong>"
  end

  test "POST create renders headings" do
    post admin_article_preview_url, params: { body: "## Section Title" }, as: :turbo_stream
    assert_response :success
    assert_includes response.body, "Section Title</h2>"
  end

  test "POST create renders links" do
    post admin_article_preview_url, params: { body: "[Monaco](https://monaco.mc)" }, as: :turbo_stream
    assert_response :success
    assert_includes response.body, '<a href="https://monaco.mc">Monaco</a>'
  end

  test "POST create renders lists" do
    post admin_article_preview_url, params: { body: "- item one\n- item two" }, as: :turbo_stream
    assert_response :success
    assert_includes response.body, "<ul>"
    assert_includes response.body, "<li>item one</li>"
  end

  test "POST create handles blank body gracefully" do
    post admin_article_preview_url, params: { body: "" }, as: :turbo_stream
    assert_response :success
    assert_equal "text/vnd.turbo-stream.html; charset=utf-8", response.content_type
  end

  test "POST create handles nil body gracefully" do
    post admin_article_preview_url, params: {}, as: :turbo_stream
    assert_response :success
  end

  test "POST create wraps rendered HTML in a turbo-stream tag targeting preview" do
    post admin_article_preview_url, params: { body: "hello" }, as: :turbo_stream
    assert_response :success
    assert_includes response.body, 'turbo-stream action="update" target="preview"'
  end
end
