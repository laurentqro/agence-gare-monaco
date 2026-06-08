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

  desc "Drop brochure attachments/blobs stored on a removed service (e.g. the old Hetzner S3). Records only — the remote files are gone. Run brochures:backfill afterwards to regenerate."
  task purge_stale: :environment do
    local_service = Rails.application.config.active_storage.service.to_s

    stale_blobs = ActiveStorage::Blob
      .joins(:attachments)
      .where(active_storage_attachments: { name: "brochures" })
      .where.not(service_name: local_service)
      .distinct

    count = stale_blobs.count
    blob_ids = stale_blobs.pluck(:id)

    # Delete records directly: the remote service no longer exists, so .purge
    # (which deletes the remote file) would fail. The bytes are unrecoverable
    # anyway; brochures:backfill regenerates them onto the new service.
    ActiveStorage::Attachment.where(name: "brochures", blob_id: blob_ids).delete_all
    ActiveStorage::Blob.where(id: blob_ids).delete_all

    puts "Purged #{count} stale brochure blob(s) not on the '#{local_service}' service."
  end
end
