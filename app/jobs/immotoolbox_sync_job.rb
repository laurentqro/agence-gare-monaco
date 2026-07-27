class ImmotoolboxSyncJob < ApplicationJob
  retry_on ImmotoolboxClient::ApiError, wait: :polynomially_longer, attempts: 5
  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 5

  # The recurring schedule fires every 5 minutes but a run has no fixed duration:
  # it pulls every page of the catalogue and each HTTP call allows a 30s read
  # timeout. Serialize globally (the job takes no arguments, so one static key
  # covers every run) so a slow sync delays the next instead of racing it. Two
  # concurrent syncs write the same rows, and the loser re-triggers change
  # detection, re-enqueuing brochure jobs for properties that never changed.
  # duration must exceed the worst-case run so the lock can't expire mid-sync;
  # the Solid Queue default is only 3 minutes.
  #
  # on_conflict: :discard because every run is a full catalogue pull, so a tick
  # that collides with a run already in flight is redundant — the next tick
  # supersedes it. Blocking (the default) would stack those ticks and release
  # them back-to-back once the slow run finished, bursting redundant full syncs.
  limits_concurrency to: 1, key: "immotoolbox_sync", duration: 30.minutes, on_conflict: :discard

  def perform
    api_token = Rails.application.credentials.dig(:immotoolbox, :api_token)

    if api_token.blank?
      Rails.logger.warn("[ImmotoolboxSyncJob] No API token found in credentials — skipping sync")
      return
    end

    sync = ImmotoolboxSync.new(api_token: api_token)
    result = sync.sync_all

    Rails.logger.info("[ImmotoolboxSyncJob] Immotoolbox sync complete:")
    Rails.logger.info("  Districts — created: #{result[:districts][:created]}, updated: #{result[:districts][:updated]}")
    Rails.logger.info("  Buildings — created: #{result[:buildings][:created]}, updated: #{result[:buildings][:updated]}")
    Rails.logger.info("  Properties — created: #{result[:properties][:created]}, updated: #{result[:properties][:updated]}, unpublished: #{result[:properties][:unpublished]}")
  end
end
