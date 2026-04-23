namespace :translations do
  desc "Enqueue PropertyTranslationJob for properties missing a translation hash (staggered)"
  task backfill: :environment do
    stagger_step_seconds = Integer(ENV.fetch("STAGGER_SECONDS", "2"))
    ids = Property.where(translation_source_hash: nil).pluck(:id)

    ids.each_with_index do |id, i|
      PropertyTranslationJob.set(wait: (i * stagger_step_seconds).seconds).perform_later(id)
    end

    puts "Enqueued #{ids.size} translation job(s) (staggered by #{stagger_step_seconds}s each)."
  end
end
