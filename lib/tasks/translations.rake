namespace :translations do
  desc "Enqueue PropertyTranslationJob for properties missing a translation hash (staggered)"
  task backfill: :environment do
    stagger_step_seconds = Integer(ENV.fetch("STAGGER_SECONDS", "2"))
    # Includes properties carrying a recorded failure: they keep retrying until
    # they succeed, so a manual backfill should pick them up too.
    ids = Property.where(translation_source_hash: nil).pluck(:id)

    ids.each_with_index do |id, i|
      PropertyTranslationJob.set(wait: (i * stagger_step_seconds).seconds).perform_later(id)
    end

    puts "Enqueued #{ids.size} translation job(s) (staggered by #{stagger_step_seconds}s each)."
  end

  desc "Re-translate one property by id, clearing any recorded translation failure"
  task :retranslate, [ :id ] => :environment do |_, args|
    abort "Usage: rake translations:retranslate[ID]" if args[:id].blank?
    property = Property.find_by(id: args[:id])
    abort "Property #{args[:id]} not found" unless property

    property.clear_translation_failure!
    PropertyTranslationJob.perform_later(property.id)
    puts "Enqueued re-translation for property #{property.id} (#{property.reference})"
  end

  desc "Retry every property whose translation failed, now, without waiting for a sync (staggered)"
  task retry_failed: :environment do
    stagger_step_seconds = Integer(ENV.fetch("STAGGER_SECONDS", "2"))
    # Failed properties do retry themselves on the next sync tick that saves them,
    # but that can be a while if nothing about the property changes. This forces
    # the retry immediately after fixing the cause (an expired key, say), and
    # clears the recorded marker so the admin stops showing a stale failure.
    failed = Property.translation_failed.to_a

    failed.each_with_index do |property, i|
      property.clear_translation_failure!
      PropertyTranslationJob.set(wait: (i * stagger_step_seconds).seconds).perform_later(property.id)
    end

    puts "Retried #{failed.size} failed translation(s) (staggered by #{stagger_step_seconds}s each)."
  end
end
