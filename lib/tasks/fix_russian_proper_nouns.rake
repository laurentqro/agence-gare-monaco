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

        report(article, field, current, fixer.call)
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

  def report(article, field, before, after)
    before_windows = windows(before)
    after_windows = windows(after)

    before_windows.zip(after_windows).each do |was, now|
      next if was == now

      puts "id=#{article.id} #{field}"
      puts "  - #{was}"
      puts "  + #{now}"
    end
  end

  def windows(text)
    text.scan(/.{0,35}(?:Monaco|Monte-Carlo|Монако|Монте-Карло).{0,35}/m)
      .map { |window| window.gsub(/\s+/, " ").strip }
  end
end
