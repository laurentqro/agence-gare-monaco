namespace :immotoolbox do
  desc "Sync districts, buildings, and properties from Immotoolbox API"
  task sync: :environment do
    api_token = ENV.fetch("IMMOTOOLBOX_API_TOKEN") {
      Rails.application.credentials.dig(:immotoolbox, :api_token)
    }

    if api_token.blank?
      abort "IMMOTOOLBOX_API_TOKEN environment variable or credentials.immotoolbox.api_token is required"
    end

    sync = ImmotoolboxSync.new(api_token: api_token)
    result = sync.sync_all

    puts "Immotoolbox sync complete:"
    puts "  Districts — created: #{result[:districts][:created]}, updated: #{result[:districts][:updated]}"
    puts "  Buildings — created: #{result[:buildings][:created]}, updated: #{result[:buildings][:updated]}"
    puts "  Properties — created: #{result[:properties][:created]}, updated: #{result[:properties][:updated]}, unpublished: #{result[:properties][:unpublished]}, skipped: #{result[:properties][:skipped]}"
  end
end
