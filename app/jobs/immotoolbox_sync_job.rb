class ImmotoolboxSyncJob < ApplicationJob
  retry_on ImmotoolboxClient::ApiError, wait: :polynomially_longer, attempts: 5
  retry_on Net::OpenTimeout, wait: :polynomially_longer, attempts: 5

  def perform
    api_token = ENV.fetch("IMMOTOOLBOX_API_TOKEN") {
      Rails.application.credentials.dig(:immotoolbox, :api_token)
    }

    if api_token.blank?
      Rails.logger.warn("[ImmotoolboxSyncJob] No API token found — skipping sync")
      return
    end

    sync = ImmotoolboxSync.new(api_token: api_token)
    result = sync.sync_all

    Rails.logger.info("[ImmotoolboxSyncJob] Immotoolbox sync complete:")
    Rails.logger.info("  Districts — created: #{result[:districts][:created]}, updated: #{result[:districts][:updated]}")
    Rails.logger.info("  Buildings — created: #{result[:buildings][:created]}, updated: #{result[:buildings][:updated]}")
    Rails.logger.info("  Properties — created: #{result[:properties][:created]}, updated: #{result[:properties][:updated]}, unpublished: #{result[:properties][:unpublished]}, skipped: #{result[:properties][:skipped]}")
  end
end
