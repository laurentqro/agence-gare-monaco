require "test_helper"

class Admin::ArticlesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "adrien@agencegaremonaco.com", password: "securepassword123")
    post session_url, params: { email_address: "adrien@agencegaremonaco.com", password: "securepassword123" }
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
  end

  # Authentication
  test "redirects unauthenticated users to login" do
    delete session_url # log out
    get admin_articles_url
    assert_redirected_to new_session_url
  end

  # INDEX
  test "GET index lists all articles" do
    Article.create!(title: { "fr" => "Article 1" }, body: { "fr" => "Body 1" }, slug: "article-1", category: @category)
    Article.create!(title: { "fr" => "Article 2" }, body: { "fr" => "Body 2" }, slug: "article-2", category: @category)
    get admin_articles_url
    assert_response :success
    assert_select "h1", /Articles/
    assert_select "table tbody tr", 2
  end

  test "GET index shows article details" do
    Article.create!(title: { "fr" => "Mon article" }, body: { "fr" => "Contenu" }, slug: "mon-article", category: @category, published: true)
    get admin_articles_url
    assert_response :success
    assert_select "td", /Mon article/
    assert_select "td", /Actualités/
  end

  test "GET index orders by most recent first" do
    Article.create!(title: { "fr" => "Old" }, body: { "fr" => "C" }, slug: "old", category: @category, created_at: 2.days.ago)
    Article.create!(title: { "fr" => "New" }, body: { "fr" => "C" }, slug: "new", category: @category, created_at: 1.hour.ago)
    get admin_articles_url
    assert_response :success
    assert_select "table tbody tr:first-child td", /New/
  end

  # NEW
  test "GET new renders article form" do
    get new_admin_article_url
    assert_response :success
    assert_select "form"
    assert_select "input[name='article[slug]']"
    assert_select "select[name='article[category_id]']"
  end

  test "GET new shows only FR title field" do
    get new_admin_article_url
    assert_response :success
    assert_select "input[name='article[title][fr]']"
    assert_select "input[name='article[title][en]']", false
  end

  test "GET new shows only FR body field" do
    get new_admin_article_url
    assert_response :success
    assert_select "textarea[name='article[body][fr]']"
    assert_select "textarea[name='article[body][en]']", false
  end

  # CREATE
  test "POST create creates article and redirects" do
    assert_difference "Article.count", 1 do
      post admin_articles_url, params: {
        article: {
          title: { fr: "Nouveau titre" },
          body: { fr: "Contenu" },
          slug: "nouveau-titre",
          category_id: @category.id,
          published: "1"
        }
      }
    end
    article = Article.last
    assert_equal "Nouveau titre", article.title["fr"]
    assert_nil article.title["en"]
    assert_equal "nouveau-titre", article.slug
    assert article.published
    assert_redirected_to admin_articles_url
  end

  test "POST create sets published_at when publishing" do
    freeze_time do
      post admin_articles_url, params: {
        article: {
          title: { fr: "Test" },
          body: { fr: "Content" },
          slug: "test",
          category_id: @category.id,
          published: "1"
        }
      }
      assert_equal Time.current, Article.last.published_at
    end
  end

  test "POST create does not set published_at when not publishing" do
    post admin_articles_url, params: {
      article: {
        title: { fr: "Draft" },
        body: { fr: "Content" },
        slug: "draft",
        category_id: @category.id,
        published: "0"
      }
    }
    assert_nil Article.last.published_at
  end

  test "POST create with invalid data re-renders form" do
    Article.create!(title: { "fr" => "Existing" }, body: { "fr" => "C" }, slug: "taken-slug", category: @category)
    assert_no_difference "Article.count" do
      post admin_articles_url, params: {
        article: {
          title: { fr: "Test" },
          body: { fr: "Content" },
          slug: "taken-slug",
          category_id: @category.id
        }
      }
    end
    assert_response :unprocessable_entity
  end

  test "POST create auto-generates slug from French title when slug is blank" do
    post admin_articles_url, params: {
      article: {
        title: { fr: "Le marché immobilier à Monaco" },
        body: { fr: "Content" },
        slug: "",
        category_id: @category.id
      }
    }
    assert_equal "le-marche-immobilier-a-monaco", Article.last.slug
  end

  # EDIT
  test "GET edit renders form with existing data" do
    article = Article.create!(
      title: { "fr" => "Titre existant", "en" => "Existing title" },
      body: { "fr" => "Contenu", "en" => "Content" },
      slug: "titre-existant",
      category: @category
    )
    get edit_admin_article_url(article)
    assert_response :success
    assert_select "input[name='article[title][fr]'][value='Titre existant']"
    assert_select "input[name='article[title][en]']", false
  end

  # UPDATE
  test "PATCH update updates article and redirects" do
    article = Article.create!(
      title: { "fr" => "Old title" },
      body: { "fr" => "Old body" },
      slug: "old-title",
      category: @category
    )
    patch admin_article_url(article), params: {
      article: {
        title: { fr: "Updated title" },
        body: { fr: "Updated body" },
        slug: "updated-title"
      }
    }
    assert_redirected_to admin_articles_url
    article.reload
    assert_equal "Updated title", article.title["fr"]
    assert_equal "updated-title", article.slug
  end

  test "PATCH update sets published_at when first published" do
    article = Article.create!(
      title: { "fr" => "Draft" },
      body: { "fr" => "Content" },
      slug: "draft",
      category: @category,
      published: false,
      published_at: nil
    )
    freeze_time do
      patch admin_article_url(article), params: {
        article: { published: "1" }
      }
      article.reload
      assert_equal Time.current, article.published_at
    end
  end

  test "PATCH update preserves published_at when already published" do
    original_time = 3.days.ago
    article = Article.create!(
      title: { "fr" => "Published" },
      body: { "fr" => "Content" },
      slug: "published",
      category: @category,
      published: true,
      published_at: original_time
    )
    patch admin_article_url(article), params: {
      article: { title: { fr: "Updated" } }
    }
    article.reload
    assert_in_delta original_time, article.published_at, 1
  end

  test "PATCH update with invalid data re-renders form" do
    article = Article.create!(
      title: { "fr" => "Test" },
      body: { "fr" => "Content" },
      slug: "test",
      category: @category
    )
    # Create another article with slug "taken"
    Article.create!(title: { "fr" => "Other" }, body: { "fr" => "C" }, slug: "taken", category: @category)
    patch admin_article_url(article), params: {
      article: { slug: "taken" }
    }
    assert_response :unprocessable_entity
  end

  # DESTROY
  test "DELETE destroy deletes article and redirects" do
    article = Article.create!(
      title: { "fr" => "To delete" },
      body: { "fr" => "Content" },
      slug: "to-delete",
      category: @category
    )
    assert_difference "Article.count", -1 do
      delete admin_article_url(article)
    end
    assert_redirected_to admin_articles_url
  end

  # MARKDOWN EDITOR
  test "GET new shows markdown editor toolbar for FR body field" do
    get new_admin_article_url
    assert_response :success
    assert_select "[data-controller='markdown-editor']"
    assert_select "button[data-action*='markdown-editor#bold']"
    assert_select "button[data-action*='markdown-editor#italic']"
    assert_select "button[data-action*='markdown-editor#heading2']"
    assert_select "button[data-action*='markdown-editor#heading3']"
    assert_select "button[data-action*='markdown-editor#link']"
    assert_select "button[data-action*='markdown-editor#bulletList']"
    assert_select "button[data-action*='markdown-editor#numberedList']"
    assert_select "button[data-action*='markdown-editor#quote']"
    assert_select "button[data-action*='markdown-editor#image']"
  end

  test "GET new shows Write/Preview tabs for FR body field" do
    get new_admin_article_url
    assert_response :success
    assert_select "[data-controller='markdown-editor']" do
      assert_select "[data-markdown-editor-target='writeTab']"
      assert_select "[data-markdown-editor-target='previewTab']"
      assert_select "[data-markdown-editor-target='preview']"
    end
  end

  test "GET new shows only FR body field with markdown editor" do
    get new_admin_article_url
    assert_response :success
    assert_select "textarea[name='article[body][fr]']"
    assert_select "textarea[name='article[body][en]']", false
    assert_select "[data-controller='markdown-editor']", 1
  end

  test "GET edit shows markdown editor toolbar for FR body field" do
    article = Article.create!(
      title: { "fr" => "Test" },
      body: { "fr" => "**bold content**" },
      slug: "test-editor",
      category: @category
    )
    get edit_admin_article_url(article)
    assert_response :success
    assert_select "[data-controller='markdown-editor']"
    assert_select "button[data-action*='markdown-editor#bold']"
  end

  test "GET edit shows Write/Preview tabs for FR body field" do
    article = Article.create!(
      title: { "fr" => "Test" },
      body: { "fr" => "Content" },
      slug: "test-preview",
      category: @category
    )
    get edit_admin_article_url(article)
    assert_response :success
    assert_select "[data-controller='markdown-editor']" do
      assert_select "[data-markdown-editor-target='writeTab']"
      assert_select "[data-markdown-editor-target='previewTab']"
    end
  end

  test "GET edit has only one markdown editor instance" do
    article = Article.create!(
      title: { "fr" => "Test" },
      body: { "fr" => "Content", "en" => "English content" },
      slug: "test-single-editor",
      category: @category
    )
    get edit_admin_article_url(article)
    assert_response :success
    assert_select "[data-controller='markdown-editor']", 1
  end

  test "GET new editor has preview endpoint URL as data attribute" do
    get new_admin_article_url
    assert_response :success
    assert_select "[data-markdown-editor-preview-url-value]"
  end

  test "GET new toolbar buttons have aria-label attributes" do
    get new_admin_article_url
    assert_response :success
    assert_select "button[data-action*='markdown-editor#bold'][aria-label]"
    assert_select "button[data-action*='markdown-editor#italic'][aria-label]"
    assert_select "button[data-action*='markdown-editor#link'][aria-label]"
  end

  # IMAGE UPLOAD
  test "GET new editor has direct upload URL as data attribute" do
    get new_admin_article_url
    assert_response :success
    assert_select "[data-markdown-editor-direct-upload-url-value]"
  end

  test "GET new file input accepts images" do
    get new_admin_article_url
    assert_response :success
    assert_select "input[type='file'][accept='image/*'][data-markdown-editor-target='fileInput']"
  end

  test "GET edit editor has direct upload URL as data attribute" do
    article = Article.create!(
      title: { "fr" => "Test" },
      body: { "fr" => "Content" },
      slug: "test-upload",
      category: @category
    )
    get edit_admin_article_url(article)
    assert_response :success
    assert_select "[data-markdown-editor-direct-upload-url-value]"
  end

  # COVER IMAGE URL
  test "POST create saves cover_image_url" do
    post admin_articles_url, params: {
      article: {
        title: { fr: "Cover Test" },
        body: { fr: "![Photo](https://example.com/photo.jpg)\n\nContent" },
        slug: "cover-test",
        category_id: @category.id,
        cover_image_url: "https://example.com/photo.jpg"
      }
    }
    article = Article.find_by(slug: "cover-test")
    assert_equal "https://example.com/photo.jpg", article.cover_image_url
  end

  test "PATCH update saves cover_image_url" do
    article = Article.create!(
      title: { "fr" => "Test" },
      body: { "fr" => "![Photo](https://example.com/photo.jpg)" },
      slug: "cover-update",
      category: @category
    )
    patch admin_article_url(article), params: {
      article: { cover_image_url: "https://example.com/photo.jpg" }
    }
    article.reload
    assert_equal "https://example.com/photo.jpg", article.cover_image_url
  end

  test "PATCH update clears cover_image_url when set to blank" do
    article = Article.create!(
      title: { "fr" => "Test" },
      body: { "fr" => "Content" },
      slug: "cover-clear",
      category: @category,
      cover_image_url: "https://example.com/old.jpg"
    )
    patch admin_article_url(article), params: {
      article: { cover_image_url: "" }
    }
    article.reload
    assert article.cover_image_url.blank?
  end

  test "GET edit shows cover image selector when body has images" do
    article = Article.create!(
      title: { "fr" => "Test" },
      body: { "fr" => "![Photo](https://example.com/photo.jpg)\n\n![Other](https://example.com/other.jpg)" },
      slug: "cover-selector",
      category: @category
    )
    get edit_admin_article_url(article)
    assert_response :success
    assert_select ".cover-image-selector"
    assert_select "input[type='radio'][name='article[cover_image_url]']", 2
  end

  # FEATURED toggle
  test "PATCH update can toggle featured flag" do
    article = Article.create!(
      title: { "fr" => "Test" },
      body: { "fr" => "Content" },
      slug: "test",
      category: @category,
      featured: false
    )
    patch admin_article_url(article), params: {
      article: { featured: "1" }
    }
    article.reload
    assert article.featured
  end

  # AUTO-TRANSLATION
  test "POST create enqueues ArticleTranslationJob after successful save" do
    assert_enqueued_with(job: ArticleTranslationJob) do
      post admin_articles_url, params: {
        article: {
          title: { fr: "Nouveau titre" },
          body: { fr: "Contenu" },
          slug: "nouveau-titre-trans",
          category_id: @category.id
        }
      }
    end
  end

  test "POST create with invalid data does NOT enqueue ArticleTranslationJob" do
    Article.create!(title: { "fr" => "Existing" }, body: { "fr" => "C" }, slug: "dup-slug", category: @category)
    assert_no_enqueued_jobs only: ArticleTranslationJob do
      post admin_articles_url, params: {
        article: {
          title: { fr: "Test" },
          body: { fr: "Content" },
          slug: "dup-slug",
          category_id: @category.id
        }
      }
    end
  end

  test "PATCH update enqueues ArticleTranslationJob after successful save" do
    article = Article.create!(
      title: { "fr" => "Old" },
      body: { "fr" => "Old body" },
      slug: "old-art",
      category: @category
    )
    assert_enqueued_with(job: ArticleTranslationJob, args: [ article.id ]) do
      patch admin_article_url(article), params: {
        article: { title: { fr: "Updated" } }
      }
    end
  end

  test "POST create silently drops non-FR title and body params" do
    post admin_articles_url, params: {
      article: {
        title: { fr: "Titre français", en: "Smuggled English" },
        body: { fr: "Corps français", en: "Smuggled body" },
        slug: "drop-non-fr",
        category_id: @category.id
      }
    }
    article = Article.last
    assert_equal "Titre français", article.title["fr"]
    assert_nil article.title["en"], "non-FR title locales should be silently dropped"
    assert_equal "Corps français", article.body["fr"]
    assert_nil article.body["en"], "non-FR body locales should be silently dropped"
  end
end
