namespace :articles do
  # SEO audit 0.2: localise article slugs. Each article had a single FR-derived
  # slug shared across all 9 locales, so /en/articles/comment-vendre... served
  # an English page under a French URL. This backfills a per-locale `slugs` hash
  # from each article's translated titles.
  #
  # FR stays as the pinned canonical `slug` column and is never written into
  # `slugs`. Slugs are FROZEN once set: this task never overwrites an existing
  # per-locale value, so a later title edit does not move an already-indexed URL
  # (re-run it only to fill in newly-translated locales). Writes via
  # update_columns so no callback fires and the translation_source_hash stays
  # pinned (no mass re-translation).
  desc "Backfill per-locale article slugs from translated titles (SEO audit 0.2)"
  task backfill_slugs: :environment do
    target_locales = I18n.available_locales.map(&:to_s) - [ I18n.default_locale.to_s ]
    changed = 0

    Article.find_each do |article|
      existing = article.slugs.is_a?(Hash) ? article.slugs.dup : {}
      merged = existing.dup

      target_locales.each do |locale|
        next if merged[locale].present? # frozen: never overwrite

        localized_title = article.title.is_a?(Hash) ? article.title[locale].to_s.strip : ""
        next if localized_title.empty? # no translation yet, leave to FR fallback

        # Collision-aware minting (suffixes on clash), shared with the translator.
        localized_slug = Article.mint_localized_slug(localized_title, locale, except_id: article.id)
        next if localized_slug.empty? # punctuation-only title: leave to FR fallback

        merged[locale] = localized_slug
      end

      if merged != existing
        article.update_columns(slugs: merged, updated_at: Time.current)
        changed += 1
        puts "✓ #{article.slug} → #{(merged.keys - existing.keys).sort.join(', ')}"
      else
        puts "= #{article.slug} (unchanged)"
      end
    end

    puts "Done. #{changed} article(s) updated."
  end
end
