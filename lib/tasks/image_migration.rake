require "net/http"
require "uri"

# One-off migration run after the production cutover to the new VPS. Article cover
# images and a couple of manually-created off-market property images still point at
# the OLD host (https://www.agencegaremonaco.com/uploads/...), which now 404s. The
# files still live on the old shared host, reachable via archive.agencegaremonaco.com
# behind HTTP basic auth. This downloads each file, stores it in Active Storage (the
# :local Disk service, on the mounted storage/ volume), and rewrites the row's URL
# column to the blob's ABSOLUTE redirect URL (absolute is required so og:image /
# twitter:image meta tags keep working — see app/helpers/seo_helper.rb).
#
# Idempotent (skips rows already attached) and re-runnable. Fails loudly on any
# non-2xx download, leaving the row unchanged so a re-run is safe.
#
#   ARCHIVE_USER=archive ARCHIVE_PASSWORD=archive bin/rails image_migration:all
namespace :image_migration do
  OLD_HOST_LIKE = "%agencegaremonaco.com/uploads/%".freeze
  ARCHIVE_HOST = "https://archive.agencegaremonaco.com".freeze

  class DownloadError < StandardError; end

  desc "Migrate article cover_image_url images off the old host into Active Storage"
  task articles: :environment do
    migrated = 0
    skipped = 0
    Article.where("cover_image_url LIKE ?", OLD_HOST_LIKE).find_each do |article|
      if article.cover_image.attached?
        skipped += 1
        next
      end
      migrate_image(record: article, source_url: article.cover_image_url,
                    attachment: article.cover_image, url_column: :cover_image_url)
      migrated += 1
      puts "  migrated Article ##{article.id}"
    end
    puts "Article covers: #{migrated} migrated, #{skipped} skipped."
  end

  desc "Migrate property image remote_url images off the old host into Active Storage"
  task property_images: :environment do
    migrated = 0
    skipped = 0
    PropertyImage.where("remote_url LIKE ?", OLD_HOST_LIKE).find_each do |image|
      if image.image.attached?
        skipped += 1
        next
      end
      migrate_image(record: image, source_url: image.remote_url,
                    attachment: image.image, url_column: :remote_url)
      migrated += 1
      puts "  migrated PropertyImage ##{image.id}"
    end
    puts "Property images: #{migrated} migrated, #{skipped} skipped."
  end

  desc "Migrate both article covers and property images"
  task all: %i[articles property_images]

  # Download from the archive host (with basic auth), attach the blob, then rewrite
  # the URL column to the absolute blob URL. All-or-nothing: a download failure
  # raises before any DB write, so the row is never left half-migrated.
  def migrate_image(record:, source_url:, attachment:, url_column:)
    archive_url = source_url.sub(%r{\Ahttps?://(www\.)?agencegaremonaco\.com}, ARCHIVE_HOST)
    filename = File.basename(URI.parse(archive_url).path)
    body, content_type = download(archive_url)

    attachment.attach(io: StringIO.new(body), filename: filename, content_type: content_type)
    blob_url = Rails.application.routes.url_helpers.rails_blob_url(
      attachment, host: SeoHelper::SITE_HOST
    )
    record.update_column(url_column, blob_url)
  end

  def download(url)
    uri = URI.parse(url)
    req = Net::HTTP::Get.new(uri)
    user = ENV["ARCHIVE_USER"]
    password = ENV["ARCHIVE_PASSWORD"]
    req.basic_auth(user, password) if user.present?

    res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(req)
    end
    raise DownloadError, "GET #{url} -> #{res.code}" unless res.is_a?(Net::HTTPSuccess)

    [ res.body, res.content_type || content_type_for(url) ]
  end

  def content_type_for(url)
    case File.extname(URI.parse(url).path).downcase
    when ".png" then "image/png"
    when ".webp" then "image/webp"
    when ".gif" then "image/gif"
    else "image/jpeg"
    end
  end
end
