require "test_helper"

# Pre-go-live verification: every URL in the real legacy sitemap
# (legacy_sitemap.xml — the old www.agencegaremonaco.com URLs that have
# inbound links and search-index entries) must be handled by the new app.
#
# This test is driven directly by legacy_sitemap.xml so it stays in sync:
# add a URL to the sitemap and this test checks it automatically.
#
# It separates two distinct questions:
#   1. ROUTING — does the legacy URL hit a legacy handler (301/410) rather
#      than falling through to a raw 404? This is data-independent.
#   2. DESTINATION — does the URL the redirect points at actually resolve to
#      a live page? This depends on the data migration (do the new article
#      slugs / categories / properties match what the old URLs reference).
class LegacySitemapCoverageTest < ActionDispatch::IntegrationTest
  # Property immotoolbox_ids referenced in the legacy sitemap.
  PROPERTY_IDS = %w[
    108835 112310 117694 117912 120051 120467 120469 121587
    16244 45729 4966 62068 65381 82844 85939 93721 95909
    2 15 16
  ].freeze

  SITEMAP_PATHS = File
    .read(Rails.root.join("legacy_sitemap.xml"))
    .scan(%r{<loc>https://www\.agencegaremonaco\.com([^<]*)</loc>})
    .flatten
    .map { |p| p.empty? ? "/" : p }
    .uniq
    .freeze

  # Legacy numeric ids the /{locale}/(article|post)/:id/:slug URLs carry. The
  # redirect looks an article up by this legacy id (not the old slug, which has
  # drifted from the article's current slug), so an article with each id must
  # exist for the destination to resolve.
  ARTICLE_LEGACY_IDS = SITEMAP_PATHS
    .grep(%r{^/(?:en|fr)/(?:article|post)/(\d+)/}) { $1.to_i }
    .uniq
    .freeze

  setup do
    @district = District.create!(name: "Carré d'Or", city: "Monaco", slug: "carre-dor")
    @category = Category.create!(name: { "fr" => "Actualités" }, slug: "actualites")

    # Seed every property the sitemap references so id-based redirects resolve.
    PROPERTY_IDS.each do |itid|
      Property.create!(
        reference: "REF-#{itid}",
        title: { "fr" => "Bien #{itid}", "en" => "Property #{itid}", "it" => "Immobile #{itid}" },
        description: { "fr" => "Desc", "en" => "Desc", "it" => "Desc" },
        transaction_type: "sale",
        property_type: "apartment",
        country: "MC",
        city: "Monaco",
        district: @district,
        published: true,
        immotoolbox_id: itid
      )
    end
  end

  test "legacy_sitemap.xml parses to the full URL list" do
    assert SITEMAP_PATHS.size > 100,
      "expected to parse the full legacy sitemap, got #{SITEMAP_PATHS.size} paths"
  end

  # --- Question 1: routing coverage (data-independent) ---------------------
  test "every legacy URL is handled (301 / 410 / 200) on the first hop, never a raw 404" do
    bad = []

    SITEMAP_PATHS.each do |path|
      get path
      ok = response.redirect? || status == 410 || response.successful?
      bad << "#{path} → #{status}" unless ok
    rescue StandardError => e
      bad << "#{path} → raised #{e.class}: #{e.message}"
    end

    assert_empty bad, "Legacy URLs with no handler (fall through to 404/500):\n  #{bad.join("\n  ")}"
  end

  # --- Question 2: destinations resolve when the data exists ---------------
  test "legacy URLs land on a live page once their target records exist" do
    # Seed an article carrying each legacy id the sitemap references, so the
    # full id-based redirect chain resolves. In production the data migration
    # must guarantee an article with each of these legacy_ids.
    ARTICLE_LEGACY_IDS.each do |lid|
      next if Article.exists?(legacy_id: lid)
      Article.create!(
        title: { "fr" => "Article #{lid}" },
        body: { "fr" => "Contenu" },
        slug: "article-#{lid}",
        legacy_id: lid,
        category: @category,
        published: true,
        published_at: Time.current
      )
    end

    # Legacy /fr/posts/:category URLs redirect to the new category that absorbed
    # them (LegacyRedirectsController::LEGACY_CATEGORY_SLUGS), landing on
    # /fr/articles/:new-category-slug. Seed each target category so the
    # category-filtered articles index resolves.
    LegacyRedirectsController::LEGACY_CATEGORY_SLUGS.each_value do |new_slug|
      next if Category.exists?(slug: new_slug)
      Category.create!(name: { "fr" => new_slug.humanize }, slug: new_slug)
    end

    unresolved = []

    SITEMAP_PATHS.each do |path|
      get path
      hops = 0
      while response.redirect? && hops < 5
        follow_redirect!
        hops += 1
      end
      # 410 Gone is an acceptable terminal state (property withdrawn).
      unless response.successful? || status == 410
        unresolved << "#{path} → #{status}"
      end
    rescue StandardError => e
      unresolved << "#{path} → raised #{e.class}: #{e.message}"
    end

    assert_empty unresolved,
      "Legacy URLs whose redirect chain does NOT reach a live page:\n  #{unresolved.join("\n  ")}"
  end
end
