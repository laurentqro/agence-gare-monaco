namespace :translations do
  desc "Enqueue PropertyTranslationJob for properties missing a translation hash (staggered)"
  task backfill: :environment do
    stagger_step_seconds = Integer(ENV.fetch("STAGGER_SECONDS", "2"))
    scope = Property.where(translation_source_hash: nil)

    count = 0
    scope.find_each.with_index do |property, i|
      PropertyTranslationJob.set(wait: (i * stagger_step_seconds).seconds).perform_later(property.id)
      count += 1
    end

    puts "Enqueued #{count} translation job(s) (staggered by #{stagger_step_seconds}s each)."
  end
end
