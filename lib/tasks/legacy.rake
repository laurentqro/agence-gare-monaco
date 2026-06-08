namespace :legacy do
  desc "Import contacts from the legacy site CSV export (legacy:import_contacts[path])"
  task :import_contacts, [:path] => :environment do |_t, args|
    path = args[:path] || ENV["CONTACTS_CSV"] || File.expand_path("~/Desktop/contacts.csv")

    abort "CSV not found: #{path}" unless File.exist?(path)

    puts "Importing contacts from #{path}..."
    result = LegacyContactImporter.new(path, logger: ->(msg) { puts msg }).call
    puts "Done. Imported #{result.imported}, updated #{result.updated}, skipped #{result.skipped}."
  end

  desc "Import peer agents/confrères from the legacy partner CSV export (legacy:import_peers[path])"
  task :import_peers, [:path] => :environment do |_t, args|
    path = args[:path] || ENV["PEERS_CSV"] || File.expand_path("~/Desktop/partners.csv")

    abort "CSV not found: #{path}" unless File.exist?(path)

    puts "Importing peers from #{path}..."
    result = LegacyPeerImporter.new(path, logger: ->(msg) { puts msg }).call
    puts "Done. Imported #{result.imported}, updated #{result.updated}, skipped #{result.skipped}."
  end
end
