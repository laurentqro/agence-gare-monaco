namespace :articles do
  # 0.1 of the 2026-07 SEO audit. The valuation article ranked at position 3-5
  # on commercial queries ("estimation immobilière monaco" — 439 impressions,
  # "property valuation monaco" — 267) yet took zero clicks: a snippet problem,
  # not a ranking one. This rewrites the FR/EN title (the <title> / blue link)
  # to lead with those exact queries and the FR/EN meta_description to add a
  # free-valuation CTA pointing at the IMSEE estimator.
  #
  # It writes only the fr/en keys of title and meta_description via
  # update_columns, so callbacks do NOT fire: the translation_source_hash stays
  # pinned and the LLM translator is not re-run over the other seven locales
  # (which would otherwise overwrite this hand-authored EN copy). Retranslate
  # the remaining locales deliberately via `articles:translate_pending` later.
  VALUATION_SLUG = "comment-estimer-la-valeur-de-votre-bien-immobilier-a-monaco".freeze

  VALUATION_TITLE = {
    "fr" => "Estimation immobilière à Monaco : comment évaluer votre bien",
    "en" => "Property valuation in Monaco: how to estimate your home's worth"
  }.freeze

  VALUATION_META = {
    "fr" => "Estimation immobilière à Monaco : quartier, étage, vue et comparables font le prix de votre bien. Obtenez une estimation gratuite avec notre outil IMSEE.",
    "en" => "Property valuation in Monaco: district, floor, view and recent comparables set your home's price. Get a free instant valuation with our IMSEE-based tool."
  }.freeze

  desc "Rewrite the valuation article's FR/EN title and meta for commercial-query CTR (SEO audit 0.1)"
  task optimise_valuation_snippet: :environment do
    article = Article.find_by(slug: VALUATION_SLUG)
    abort "Valuation article not found (slug: #{VALUATION_SLUG})" if article.nil?

    VALUATION_META.each do |loc, text|
      abort "#{loc} meta is #{text.length} chars, over the 160 snippet budget" if text.length > 160
    end

    title = (article.title || {}).merge(VALUATION_TITLE)
    meta  = (article.meta_description || {}).merge(VALUATION_META)

    if article.title == title && article.meta_description == meta
      puts "= #{VALUATION_SLUG} (unchanged)"
    else
      article.update_columns(title: title, meta_description: meta, updated_at: Time.current)
      puts "✓ #{VALUATION_SLUG} — FR/EN title + meta rewritten"
      puts "  Other locales left as-is. Run articles:translate_pending to retranslate them when ready."
    end
  end
end
