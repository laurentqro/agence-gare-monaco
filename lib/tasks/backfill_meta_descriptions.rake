namespace :articles do
  # Hand-written French meta descriptions from the 2026-07 SEO audit, keyed by
  # slug so the task is safe to run against any environment. Writes only the FR
  # key of meta_description and leaves every other column untouched; the
  # translator fills the other locales when it next runs.
  DESCRIPTIONS = {
    "quelles-sont-les-conditions-a-remplir-pour-s-installer-a-monaco" =>
      "Séjour, carte de séjour, justificatifs de ressources et de logement : toutes les conditions à remplir pour s'installer à Monaco, expliquées étape par étape.",
    "les-avantages-uniques-du-systeme-fiscal-de-monaco" =>
      "Pas d'impôt sur le revenu, mais deux exceptions à connaître : notre guide de la fiscalité monégasque pour les particuliers, les Français et les entreprises.",
    "5-raisons-de-vivre-dans-la-principaute-de-monaco" =>
      "Climat, sécurité, fiscalité, cadre cosmopolite et position sur la Riviera : cinq raisons concrètes de venir vivre dans la Principauté de Monaco.",
    "la-securite-et-la-sante-a-monaco" =>
      "Vidéosurveillance 24h/24, un policier pour 100 habitants, hôpital et services de santé : ce qui rend Monaco l'un des endroits les plus sûrs au monde.",
    "quels-sont-les-quartiers-de-monaco-ou-vous-installer" =>
      "Monaco-Ville, Monte-Carlo, La Condamine, Fontvieille, La Rousse : le caractère, l'ambiance et le marché immobilier de chaque quartier de Monaco.",
    "comment-estimer-la-valeur-de-votre-bien-immobilier-a-monaco" =>
      "Quartier, étage, état, vue, comparables récents : les critères qui déterminent le prix de votre bien à Monaco, et comment obtenir une estimation fiable.",
    "comment-vendre-son-bien-immobilier-a-monaco" =>
      "Estimation, documents à réunir, mandat, compromis et acte notarié : les étapes pour vendre son bien immobilier à Monaco, accompagné par notre agence.",
    "notre-guide-d-achat-de-bien-immobilier-a-monaco" =>
      "Définir son projet, accéder aux biens off-market, visiter, négocier et signer : notre guide pour acheter un bien immobilier à Monaco en toute sérénité.",
    "comment-assurer-la-gestion-locative-de-son-bien-immobilier-a-monaco" =>
      "Mise en location, sélection des locataires, bail, état des lieux et suivi quotidien : comment déléguer la gestion locative de votre bien à Monaco.",
    "nouveau-parking-sur-monaco" =>
      "Un nouveau parking ouvre sur le port de Monaco. Les actualités du stationnement et du marché immobilier monégasque par l'Agence de la Gare."
  }.freeze

  desc "Set the French meta description on each article from the 2026-07 SEO audit"
  task backfill_meta_descriptions: :environment do
    missing = DESCRIPTIONS.keys - Article.pluck(:slug)
    abort "Unknown slugs: #{missing.join(', ')}" if missing.any?

    DESCRIPTIONS.each do |slug, description|
      article = Article.find_by!(slug: slug)
      merged = (article.meta_description || {}).merge("fr" => description)

      if article.meta_description == merged
        puts "= #{slug} (unchanged)"
        next
      end

      article.update_columns(meta_description: merged, updated_at: Time.current)
      puts "✓ #{slug} (#{description.length} chars)"
    end

    puts "\nDone. Translations are NOT enqueued — run articles:translate_pending once API access is restored."
  end

  desc "Enqueue translation for every article whose translations are stale or missing"
  task translate_pending: :environment do
    stale = Article.all.select { |a| a.translation_stale? || a.translated_count < Article::TARGET_LOCALES.size }
    stale.each do |article|
      ArticleTranslationJob.perform_later(article.id)
      puts "→ enqueued ##{article.id} #{article.slug}"
    end
    puts "\nEnqueued #{stale.size} article(s)."
  end
end
