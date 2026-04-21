namespace :translations do
  desc "Enqueue PropertyTranslationJob for every property (used after first deploy)"
  task backfill: :environment do
    count = 0
    Property.find_each do |property|
      PropertyTranslationJob.perform_later(property.id)
      count += 1
    end
    puts "Enqueued #{count} translation job(s)."
  end
end
