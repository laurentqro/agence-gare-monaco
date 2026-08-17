require "test_helper"

class SeoHelperTest < ActionView::TestCase
  include SeoHelper
  include ApplicationHelper

  setup do
    @district = District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    @property = Property.create!(
      reference: "SEO-001",
      title: { "en" => "Beautiful Studio", "fr" => "Beau Studio" },
      description: { "en" => "A lovely studio in the heart of Monaco with amazing views.", "fr" => "Un beau studio au coeur de Monaco avec des vues magnifiques." },
      price: 1_290_000,
      transaction_type: "sale",
      property_type: "studio",
      country: "MC",
      city: "Monaco",
      district: @district,
      published: true,
      off_market: false,
      num_rooms: 2,
      num_bedrooms: 1,
      num_bathrooms: 1,
      living_area: 45.0,
      latitude: 43.738,
      longitude: 7.427
    )
    @image = @property.property_images.create!(
      remote_url: "https://cdn.example.com/photo1.jpg",
      large_url: "https://cdn.example.com/photo1_large.jpg",
      position: 1
    )
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")
    @article = Article.create!(
      title: { "en" => "Monaco Market Update", "fr" => "Mise à jour du marché monégasque" },
      body: { "en" => "The Monaco real estate market continues to grow strongly in 2025.", "fr" => "Le marché immobilier monégasque continue de croître fortement en 2025." },
      slug: "monaco-market-update",
      category: @category,
      published: true,
      featured: false,
      published_at: Time.zone.parse("2025-03-15 10:00:00")
    )
  end

  # --- Canonical URL ---

  test "canonical_url for homepage" do
    I18n.with_locale(:fr) do
      result = canonical_url(page_type: :homepage)
      assert_equal "https://agencegaremonaco.com/", result
    end
  end

  test "canonical_url for homepage in English" do
    I18n.with_locale(:en) do
      result = canonical_url(page_type: :homepage)
      assert_equal "https://agencegaremonaco.com/en", result
    end
  end

  test "canonical_url for property listing" do
    I18n.with_locale(:fr) do
      result = canonical_url(page_type: :listings, transaction_type: "sale")
      assert_equal "https://agencegaremonaco.com/ventes", result
    end
  end

  test "canonical_url for property listing in English" do
    I18n.with_locale(:en) do
      result = canonical_url(page_type: :listings, transaction_type: "sale")
      assert_equal "https://agencegaremonaco.com/en/sales", result
    end
  end

  test "canonical_url for property detail" do
    I18n.with_locale(:en) do
      result = canonical_url(page_type: :property, property: @property)
      assert_equal "https://agencegaremonaco.com/en/properties/#{@property.id}-beautiful-studio", result
    end
  end

  test "canonical_url for articles index" do
    I18n.with_locale(:fr) do
      result = canonical_url(page_type: :articles)
      assert_equal "https://agencegaremonaco.com/articles", result
    end
  end

  test "canonical_url for category page appends the localized category slug" do
    category = Category.new(name: { "fr" => "Actualités", "en" => "News" }, slug: "actualites")
    I18n.with_locale(:en) do
      result = canonical_url(page_type: :articles, category: category)
      assert_equal "https://agencegaremonaco.com/en/articles/news", result
    end
  end

  test "hreflang_tags for category page localize the slug per locale" do
    category = Category.new(name: { "fr" => "Actualités", "de" => "Aktuelles", "ru" => "Новости" }, slug: "actualites")
    I18n.with_locale(:en) do
      tags = hreflang_tags(page_type: :articles, category: category)
      assert_includes tags, 'href="https://agencegaremonaco.com/de/artikel/aktuelles"'
      assert_includes tags, 'href="https://agencegaremonaco.com/ru/stati/novosti"'
      # Locales without a name fall back to the base slug
      assert_includes tags, 'href="https://agencegaremonaco.com/it/articoli/actualites"'
      # x-default points to the French category page
      assert_includes tags, 'hreflang="x-default" href="https://agencegaremonaco.com/articles/actualites"'
    end
  end

  test "canonical_url for article show" do
    I18n.with_locale(:en) do
      result = canonical_url(page_type: :article, article: @article)
      assert_equal "https://agencegaremonaco.com/en/articles/monaco-market-update", result
    end
  end

  test "canonical_url for article show uses the per-locale slug" do
    article = Article.create!(
      title: { "fr" => "Comment vendre", "en" => "How to sell your property" },
      body: { "fr" => "Corps", "en" => "Body" },
      slug: "comment-vendre",
      slugs: { "en" => "how-to-sell-your-property" },
      category: @category, published: true, published_at: Time.current
    )
    I18n.with_locale(:en) do
      result = canonical_url(page_type: :article, article: article)
      assert_equal "https://agencegaremonaco.com/en/articles/how-to-sell-your-property", result
    end
  end

  test "hreflang_tags for article show localize the slug per locale" do
    article = Article.create!(
      title: { "fr" => "Comment vendre", "en" => "How to sell", "it" => "Come vendere" },
      body: { "fr" => "Corps", "en" => "Body", "it" => "Corpo" },
      slug: "comment-vendre",
      slugs: { "en" => "how-to-sell", "it" => "come-vendere" },
      category: @category, published: true, published_at: Time.current
    )
    I18n.with_locale(:en) do
      tags = hreflang_tags(page_type: :article, article: article)
      assert_includes tags, 'href="https://agencegaremonaco.com/en/articles/how-to-sell"'
      assert_includes tags, 'href="https://agencegaremonaco.com/it/articoli/come-vendere"'
      # A locale without its own slug falls back to the canonical FR slug.
      assert_includes tags, 'href="https://agencegaremonaco.com/de/artikel/comment-vendre"'
      # x-default points to the French (unprefixed) article using the FR slug.
      assert_includes tags, 'hreflang="x-default" href="https://agencegaremonaco.com/articles/comment-vendre"'
    end
  end

  test "canonical_url for contact" do
    I18n.with_locale(:de) do
      result = canonical_url(page_type: :contact)
      assert_equal "https://agencegaremonaco.com/de/kontakt", result
    end
  end

  test "canonical_url for privacy" do
    I18n.with_locale(:fr) do
      result = canonical_url(page_type: :privacy)
      assert_equal "https://agencegaremonaco.com/confidentialite", result
    end
  end

  # --- Hreflang tags ---

  test "hreflang_tags for homepage includes all 9 locales plus x-default" do
    I18n.with_locale(:en) do
      tags = hreflang_tags(page_type: :homepage)
      assert_includes tags, 'hreflang="fr"'
      assert_includes tags, 'hreflang="en"'
      assert_includes tags, 'hreflang="de"'
      assert_includes tags, 'hreflang="it"'
      assert_includes tags, 'hreflang="sv"'
      assert_includes tags, 'hreflang="nb"'
      assert_includes tags, 'hreflang="da"'
      assert_includes tags, 'hreflang="fi"'
      assert_includes tags, 'hreflang="ru"'
      assert_includes tags, 'hreflang="x-default"'
    end
  end

  test "hreflang_tags x-default points to French version" do
    I18n.with_locale(:en) do
      tags = hreflang_tags(page_type: :homepage)
      assert_includes tags, 'hreflang="x-default" href="https://agencegaremonaco.com/"'
    end
  end

  test "hreflang_tags for property uses locale-specific slugs" do
    I18n.with_locale(:en) do
      tags = hreflang_tags(page_type: :property, property: @property)
      assert_includes tags, "href=\"https://agencegaremonaco.com/biens/#{@property.id}-beau-studio\""
      assert_includes tags, "href=\"https://agencegaremonaco.com/en/properties/#{@property.id}-beautiful-studio\""
    end
  end

  test "hreflang_tags property URLs use each target locale's transliteration regardless of current locale" do
    @property.update!(title: @property.title.merge("da" => "Dejlig studio i høj etage"))
    I18n.with_locale(:fr) do
      tags = hreflang_tags(page_type: :property, property: @property)
      assert_includes tags, "href=\"https://agencegaremonaco.com/da/ejendomme/#{@property.id}-dejlig-studio-i-hoej-etage\""
    end
    I18n.with_locale(:da) do
      tags = hreflang_tags(page_type: :property, property: @property)
      assert_includes tags, "href=\"https://agencegaremonaco.com/da/ejendomme/#{@property.id}-dejlig-studio-i-hoej-etage\""
    end
  end

  test "hreflang_tags uses nb for Norwegian" do
    I18n.with_locale(:en) do
      tags = hreflang_tags(page_type: :homepage)
      assert_includes tags, 'hreflang="nb" href="https://agencegaremonaco.com/no"'
    end
  end

  # --- Meta description ---

  test "seo_meta_description for homepage" do
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :homepage)
      assert result.present?
      assert result.length <= 160
    end
  end

  test "seo_meta_description for homepage includes specific data points" do
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :homepage)
      assert_includes result, "1942", "Homepage description should mention founding year"
      assert_includes result, "Monaco", "Homepage description should mention Monaco"
    end
  end

  test "seo_meta_description for gestion includes specific data points" do
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :gestion)
      assert_includes result, "1942", "Gestion description should mention founding year"
    end
  end

  test "seo_meta_description for property truncates to 160 chars" do
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :property, property: @property)
      assert result.present?
      assert result.length <= 160
    end
  end


  test "seo_meta_description for property strips HTML tags and entities" do
    @property.update!(description: { "en" => "Located&nbsp;in the heart&nbsp;of <b>Monaco</b>, near the port." })
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :property, property: @property)
      assert_not_includes result, "&nbsp;"
      assert_not_includes result, "<b>"
      assert_includes result, "Located in the heart of Monaco, near the port."
    end
  end

  test "seo_meta_description for article strips HTML tags and entities" do
    @article.update!(body: { "en" => "Great&nbsp;article about <em>real estate</em> in Monaco." })
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :article, article: @article)
      assert_not_includes result, "&nbsp;"
      assert_not_includes result, "<em>"
      assert_includes result, "Great article about real estate in Monaco."
    end
  end

  test "seo_meta_description for article uses body text" do
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :article, article: @article)
      assert result.present?
      assert result.length <= 160
    end
  end

  test "seo_meta_description for article prefers the handwritten meta description" do
    @article.update!(meta_description: { "en" => "Handwritten summary for search engines." })
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :article, article: @article)
      assert_equal "Handwritten summary for search engines.", result
    end
  end

  test "seo_meta_description for article falls back to body excerpt when meta description blank" do
    @article.update!(meta_description: { "en" => "" })
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :article, article: @article)
      assert_includes result, "The Monaco real estate market"
    end
  end

  test "seo_meta_description for article strips markdown syntax" do
    @article.update!(body: { "en" => "### How does the tax system work?\n\nThe Monegasque tax system is **unique** and *simple*." })
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :article, article: @article)
      assert_not_includes result, "###"
      assert_not_includes result, "**"
      assert_includes result, "The Monegasque tax system is unique and simple."
    end
  end

  test "seo_meta_description for article skips headings and starts with paragraph text" do
    @article.update!(body: { "en" => "### How does the tax system work?\n\nResidents pay no income tax in Monaco." })
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :article, article: @article)
      assert result.start_with?("Residents pay no income tax in Monaco."), "expected paragraph text first, got: #{result}"
    end
  end

  test "seo_meta_description for article falls back to heading text when body has only headings" do
    @article.update!(body: { "en" => "### How does the tax system work?" })
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :article, article: @article)
      assert_equal "How does the tax system work?", result
    end
  end

  test "seo_meta_description for article truncates at a sentence boundary" do
    first = "Monaco offers residents an exceptional quality of life."
    second = "The Principality combines security, sunshine and a central European location."
    third = "This third sentence pushes the total text well beyond the maximum length allowed for a meta description tag."
    @article.update!(body: { "en" => "#{first} #{second} #{third}" })
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :article, article: @article)
      assert_equal "#{first} #{second}", result
    end
  end

  test "seo_meta_description for article truncates on a word when the first sentence is too long" do
    long_sentence = "Monaco is a sovereign city-state on the French Riviera whose residents benefit from an absence of income tax, a remarkably low crime rate, a mild Mediterranean climate and direct access to the wider European market."
    @article.update!(body: { "en" => long_sentence })
    I18n.with_locale(:en) do
      result = seo_meta_description(page_type: :article, article: @article)
      assert result.length <= 160
      assert result.end_with?("…"), "expected ellipsis, got: #{result}"
      assert_not result[..-2].end_with?(" "), "expected no trailing space before ellipsis"
      words = long_sentence.split(" ")
      assert words.include?(result.delete_suffix("…").split(" ").last), "expected truncation on a word boundary"
    end
  end

  # --- Page title ---

  test "seo_title for gestion is descriptive in every locale" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        title = seo_title(page_type: :gestion)
        assert_not_includes title, "translation missing"
        assert_not title.start_with?("Gestion |"), "generic title in #{locale}: #{title}"
        assert_includes title, "Agence Immobilière de la Gare"
      end
    end
  end

  test "seo_title for gestion targets rental management queries in French" do
    I18n.with_locale(:fr) do
      assert seo_title(page_type: :gestion).start_with?("Gestion locative à Monaco")
    end
  end

  test "seo_title for offmarket is descriptive in every locale" do
    I18n.available_locales.each do |locale|
      I18n.with_locale(locale) do
        title = seo_title(page_type: :offmarket)
        assert_not_includes title, "translation missing"
        assert_not title.start_with?("Off-market |"), "generic title in #{locale}: #{title}"
        assert_includes title, "Agence Immobilière de la Gare"
      end
    end
  end

  test "seo_title for offmarket targets off-market property queries in English" do
    I18n.with_locale(:en) do
      assert seo_title(page_type: :offmarket).start_with?("Off-Market Properties in Monaco")
    end
  end

  test "seo_title for homepage" do
    I18n.with_locale(:en) do
      result = seo_title(page_type: :homepage)
      assert_includes result, "Agence Immobili"
      assert_includes result, "1942"
    end
  end

  test "seo_title for property with price" do
    I18n.with_locale(:en) do
      result = seo_title(page_type: :property, property: @property)
      assert_includes result, "Beautiful Studio"
      assert_includes result, "1.290.000"
    end
  end

  test "seo_title for property without price omits price" do
    @property.update!(price: nil)
    I18n.with_locale(:en) do
      result = seo_title(page_type: :property, property: @property)
      assert_includes result, "Beautiful Studio"
      assert_equal "Beautiful Studio | Agence Immobilière de la Gare", result
      refute_includes result, "\u20AC"  # no euro sign when price is nil
    end
  end

  test "seo_title for article" do
    I18n.with_locale(:en) do
      result = seo_title(page_type: :article, article: @article)
      assert_includes result, "Monaco Market Update"
      assert_includes result, "Agence Immobilière de la Gare"
    end
  end

  test "seo_title for category page uses the category name" do
    category = Category.new(name: { "fr" => "Actualités", "en" => "News" }, slug: "actualites")
    I18n.with_locale(:en) do
      result = seo_title(page_type: :articles, category: category)
      assert_includes result, "News"
      assert_includes result, "Agence Immobilière de la Gare"
    end
  end

  test "seo_title for listings" do
    I18n.with_locale(:en) do
      result = seo_title(page_type: :listings, transaction_type: "sale")
      assert_includes result, "Sales"
    end
  end

  test "seo_title for rentals listings" do
    I18n.with_locale(:en) do
      result = seo_title(page_type: :listings, transaction_type: "rental")
      assert_includes result, "Rentals"
    end
  end

  # --- Open Graph tags ---

  test "og_tags for homepage" do
    I18n.with_locale(:en) do
      tags = og_tags(page_type: :homepage)
      assert_includes tags, 'property="og:type" content="website"'
      assert_includes tags, 'property="og:site_name"'
      assert_includes tags, 'property="og:locale" content="en_GB"'
      assert_includes tags, 'property="og:url"'
    end
  end

  test "og_tags for property includes image with dimensions" do
    I18n.with_locale(:en) do
      tags = og_tags(page_type: :property, property: @property)
      assert_includes tags, 'property="og:image"'
      assert_includes tags, @image.large_url
      assert_includes tags, 'property="og:image:width" content="1200"'
      assert_includes tags, 'property="og:image:height" content="630"'
    end
  end

  test "og_tags for homepage includes image dimensions" do
    I18n.with_locale(:en) do
      tags = og_tags(page_type: :homepage)
      assert_includes tags, 'property="og:image:width" content="1200"'
      assert_includes tags, 'property="og:image:height" content="630"'
    end
  end

  test "og_tags for article uses article type" do
    I18n.with_locale(:en) do
      tags = og_tags(page_type: :article, article: @article)
      assert_includes tags, 'property="og:type" content="article"'
      assert_includes tags, 'property="article:published_time"'
    end
  end

  test "og_tags for article includes cover image" do
    @article.update!(cover_image_url: "https://example.com/cover.jpg")
    I18n.with_locale(:en) do
      tags = og_tags(page_type: :article, article: @article)
      assert_includes tags, 'property="og:image" content="https://example.com/cover.jpg"'
    end
  end

  test "og_tags for article falls back to first_image_url" do
    @article.update!(
      cover_image_url: nil,
      body: { "fr" => "![Photo](https://example.com/body.jpg)", "en" => "![Photo](https://example.com/body.jpg)" }
    )
    I18n.with_locale(:en) do
      tags = og_tags(page_type: :article, article: @article)
      assert_includes tags, 'property="og:image" content="https://example.com/body.jpg"'
    end
  end

  test "og_tags for article without images has no og:image" do
    @article.update!(cover_image_url: nil, body: { "fr" => "Text only", "en" => "Text only" })
    I18n.with_locale(:en) do
      tags = og_tags(page_type: :article, article: @article)
      refute_includes tags, "og:image"
    end
  end

  test "og_tags includes alternate locales" do
    I18n.with_locale(:fr) do
      tags = og_tags(page_type: :homepage)
      assert_includes tags, 'property="og:locale" content="fr_FR"'
      assert_includes tags, 'property="og:locale:alternate" content="en_GB"'
    end
  end

  # --- Twitter Card tags ---

  test "twitter_tags includes summary_large_image card type" do
    I18n.with_locale(:en) do
      tags = twitter_tags(page_type: :homepage)
      assert_includes tags, 'name="twitter:card" content="summary_large_image"'
    end
  end

  # --- JSON-LD ---

  test "json_ld_organization includes RealEstateAgent" do
    result = json_ld_organization
    parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
    assert_equal "RealEstateAgent", parsed["@type"]
    assert_equal "Agence Immobilière de la Gare", parsed["name"]
    assert_equal "+377 93 30 22 36", parsed["telephone"]
  end

  test "json_ld_organization includes openingHoursSpecification" do
    result = json_ld_organization
    parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
    hours = parsed["openingHoursSpecification"]
    assert hours.present?, "Expected openingHoursSpecification in Organization schema"
    assert_equal 1, hours.size
    spec = hours.first
    assert_equal "OpeningHoursSpecification", spec["@type"]
    assert_equal %w[Monday Tuesday Wednesday Thursday Friday], spec["dayOfWeek"]
    assert_equal "09:00", spec["opens"]
    assert_equal "18:00", spec["closes"]
  end

  test "json_ld_property includes RealEstateListing" do
    I18n.with_locale(:en) do
      result = json_ld_property(@property)
      parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
      assert_equal "RealEstateListing", parsed["@type"]
      assert_equal "Beautiful Studio", parsed["name"]
      assert_equal 1_290_000, parsed["offers"]["price"]
      assert_equal "EUR", parsed["offers"]["priceCurrency"]
      assert_equal 2, parsed["numberOfRooms"]
    end
  end

  test "json_ld_property does not use InStock availability" do
    I18n.with_locale(:en) do
      result = json_ld_property(@property)
      parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
      refute_equal "https://schema.org/InStock", parsed.dig("offers", "availability"),
        "RealEstateListing should not use InStock availability"
    end
  end

  test "json_ld_property omits offers when price is nil" do
    @property.update!(price: nil)
    I18n.with_locale(:en) do
      result = json_ld_property(@property)
      parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
      assert_nil parsed["offers"]
    end
  end

  test "json_ld_article includes Article schema" do
    I18n.with_locale(:en) do
      result = json_ld_article(@article)
      parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
      assert_equal "Article", parsed["@type"]
      assert_equal "Monaco Market Update", parsed["headline"]
      assert_equal "en", parsed["inLanguage"]
    end
  end

  test "json_ld_article description prefers the handwritten meta description" do
    @article.update!(meta_description: { "en" => "Handwritten summary for search engines." })
    I18n.with_locale(:en) do
      result = json_ld_article(@article)
      parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
      assert_equal "Handwritten summary for search engines.", parsed["description"]
    end
  end

  test "json_ld_article description strips markdown syntax" do
    @article.update!(body: { "en" => "### How does the tax system work?\n\nThe Monegasque tax system is **unique** and simple." })
    I18n.with_locale(:en) do
      result = json_ld_article(@article)
      parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
      assert_not_includes parsed["description"], "###"
      assert_not_includes parsed["description"], "**"
      assert parsed["description"].start_with?("The Monegasque tax system is unique and simple.")
    end
  end

  test "json_ld_faq generates FAQPage schema" do
    faqs = [
      { question: "How much does property management cost in Monaco?", answer: "Fees vary based on services required." },
      { question: "What documents are needed to sell a property?", answer: "Property title, assembly minutes, diagnostics." }
    ]
    result = json_ld_faq(faqs)
    parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
    assert_equal "FAQPage", parsed["@type"]
    assert_equal 2, parsed["mainEntity"].size
    assert_equal "Question", parsed["mainEntity"][0]["@type"]
    assert_equal "How much does property management cost in Monaco?", parsed["mainEntity"][0]["name"]
    assert_equal "Answer", parsed["mainEntity"][0]["acceptedAnswer"]["@type"]
    assert_equal "Fees vary based on services required.", parsed["mainEntity"][0]["acceptedAnswer"]["text"]
  end

  test "json_ld_website generates WebSite schema" do
    result = json_ld_website
    parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
    assert_equal "https://schema.org", parsed["@context"]
    assert_equal "WebSite", parsed["@type"]
    assert_equal "Agence Immobilière de la Gare", parsed["name"]
    assert_equal "https://agencegaremonaco.com", parsed["url"]
    assert_equal "RealEstateAgent", parsed["publisher"]["@type"]
    assert parsed["inLanguage"].is_a?(Array)
    assert_includes parsed["inLanguage"], "fr"
    assert_includes parsed["inLanguage"], "en"
  end

  test "json_ld_breadcrumbs generates BreadcrumbList" do
    I18n.with_locale(:en) do
      crumbs = [
        { name: "Home", url: "https://agencegaremonaco.com/en" },
        { name: "Sales in Monaco", url: "https://agencegaremonaco.com/en/sales/monaco" }
      ]
      result = json_ld_breadcrumbs(crumbs)
      parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
      assert_equal "BreadcrumbList", parsed["@type"]
      assert_equal 2, parsed["itemListElement"].size
      assert_equal "Home", parsed["itemListElement"][0]["name"]
      assert_equal 1, parsed["itemListElement"][0]["position"]
    end
  end

  # --- VideoObject JSON-LD ---

  test "json_ld_videos generates VideoObject array" do
    videos = [
      YoutubeVideo.new(video_id: "abc123", title: "Monaco Tour", description: "A tour of Monaco.", published_at: Time.zone.parse("2025-01-15")),
      YoutubeVideo.new(video_id: "def456", title: "Property Visit", published_at: Time.zone.parse("2025-02-20"))
    ]
    result = json_ld_videos(videos)
    parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
    assert_equal "ItemList", parsed["@type"]
    assert_equal 2, parsed["itemListElement"].size
    first_video = parsed["itemListElement"][0]["item"]
    assert_equal "VideoObject", first_video["@type"]
    assert_equal "Monaco Tour", first_video["name"]
    assert_equal "A tour of Monaco.", first_video["description"]
    assert_equal "https://www.youtube.com/watch?v=abc123", first_video["contentUrl"]
    assert_equal "https://img.youtube.com/vi/abc123/maxresdefault.jpg", first_video["thumbnailUrl"]
  end

  test "json_ld_videos falls back to the title when description is blank" do
    videos = [
      YoutubeVideo.new(video_id: "def456", title: "Property Visit", published_at: Time.zone.parse("2025-02-20"))
    ]
    result = json_ld_videos(videos)
    parsed = JSON.parse(result.match(/<script[^>]*>(.*)<\/script>/m)[1])
    video = parsed["itemListElement"][0]["item"]
    assert_equal "Property Visit", video["description"]
  end
end
