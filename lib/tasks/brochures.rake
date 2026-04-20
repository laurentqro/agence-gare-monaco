namespace :brochures do
  desc "Enqueue brochure generation for every property. Use FORCE=1 to regenerate already-cached ones."
  task backfill: :environment do
    force = ENV["FORCE"] == "1"
    scope = Property.all

    total = scope.count
    enqueued = 0
    skipped = 0

    scope.find_each do |property|
      if !force && property.brochures.attached?
        skipped += 1
        next
      end

      PropertyBrochureGenerationJob.perform_later(property.id)
      enqueued += 1
    end

    puts "Brochure backfill: #{enqueued} enqueued, #{skipped} skipped (already cached), #{total} total."
    puts "FORCE=1 to regenerate already-cached brochures." if skipped.positive? && !force
  end
end
