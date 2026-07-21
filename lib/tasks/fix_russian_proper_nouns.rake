namespace :articles do
  # Repairs Russian text that kept "Monaco" / "Monte-Carlo" in Latin script,
  # produced by the translator prompt before 75c52bf made it script-aware.
  #
  # Writes with update_columns so it does not fire enqueue_post_save_jobs! and
  # does not disturb translations_status or translation_source_hash: the text is
  # corrected in place, the article is not marked stale, and no API call is made.
  #
  # Defaults to a dry run. Pass APPLY=1 to write.
  desc "Transliterate Latin Monaco place names in Russian articles (APPLY=1 to write)"
  task fix_russian_proper_nouns: :environment do
    apply = ENV["APPLY"] == "1"
    fields = %w[title body meta_description]
    changed_articles = 0
    changed_fields = 0

    puts apply ? "APPLYING changes" : "DRY RUN — pass APPLY=1 to write"
    puts

    Article.order(:id).each do |article|
      updates = {}

      fields.each do |field|
        column = article.public_send(field)
        next unless column.is_a?(Hash)

        current = column["ru"].to_s
        next if current.empty?

        fixer = CyrillicProperNounFixer.new(current)
        next unless fixer.changed?

        updates[field] = column.dup.merge("ru" => fixer.call)
        changed_fields += 1

        report(article, field, current)
      end

      next if updates.empty?

      changed_articles += 1
      next unless apply

      article.update_columns(updates.merge(updated_at: Time.current))
    end

    puts
    puts "#{changed_fields} field(s) across #{changed_articles} article(s)"
    puts "Re-run with APPLY=1 to write." unless apply
  end

  # A single French reflexive that the pre-75c52bf prompt carried into English
  # and inflected: "S'installer en Principauté" became "S'installing in the
  # Principality". Keyed by slug and locale, with the exact expected string, so
  # it is a no-op once corrected or if the text is ever retranslated.
  FRAGMENT_FIXES = [
    {
      slug: "quelles-sont-les-conditions-a-remplir-pour-s-installer-a-monaco",
      locale: "en",
      field: "body",
      from: "S'installing in the Principality",
      to: "Settling in the Principality"
    }
  ].freeze

  desc "Repair untranslated French fragments carried into translations (APPLY=1 to write)"
  task fix_french_fragments: :environment do
    apply = ENV["APPLY"] == "1"
    puts apply ? "APPLYING changes" : "DRY RUN — pass APPLY=1 to write"
    puts

    applied = 0

    FRAGMENT_FIXES.each do |fix|
      article = Article.find_by(slug: fix[:slug])
      next puts("MISSING article #{fix[:slug]}") if article.nil?

      column = article.public_send(fix[:field])
      next puts("SKIP #{fix[:slug]} #{fix[:locale]}: column is not a hash") unless column.is_a?(Hash)

      current = column[fix[:locale]].to_s
      unless current.include?(fix[:from])
        puts "SKIP #{fix[:slug]} #{fix[:locale]}: #{fix[:from].inspect} not present"
        next
      end

      puts "id=#{article.id} #{fix[:field]}[#{fix[:locale]}]"
      puts "  - #{fix[:from]}"
      puts "  + #{fix[:to]}"
      applied += 1

      next unless apply

      updated = column.dup.merge(fix[:locale] => current.sub(fix[:from], fix[:to]))
      article.update_columns(fix[:field] => updated, updated_at: Time.current)
    end

    puts
    puts "#{applied} fragment(s)"
    puts "Re-run with APPLY=1 to write." unless apply
  end

  def report(article, field, before)
    before_windows = windows(before)
    before_windows.each do |was|
      now = CyrillicProperNounFixer.new(was).call
      next if was == now

      puts "id=#{article.id} #{field}"
      puts "  - #{was}"
      puts "  + #{now}"
    end
  end

  # Each window is run through the fixer independently, so the before/after
  # lines always describe the same span. Zipping the two texts' windows would
  # drift out of alignment, because a replacement changes how many windows the
  # scan finds.
  def windows(text)
    names = Regexp.union(CyrillicProperNounFixer::REPLACEMENTS.keys)
    text.scan(/.{0,35}#{names}.{0,35}/m)
      .map { |window| window.gsub(/\s+/, " ").strip }
  end
end
