class Article < ApplicationRecord
  belongs_to :category

  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.is_a?(Hash) }

  scope :published, -> { where(published: true) }
  scope :featured, -> { where(featured: true) }

  def title_for(locale = I18n.locale)
    return "" unless title.is_a?(Hash)
    title[locale.to_s].presence || title[I18n.default_locale.to_s].presence || title.values.first || ""
  end

  def body_for(locale = I18n.locale)
    return "" unless body.is_a?(Hash)
    body[locale.to_s].presence || body[I18n.default_locale.to_s].presence || body.values.first || ""
  end

  def first_image_url
    text = body_for
    return nil if text.blank?

    match = text.match(/!\[.*?\]\((.+?)\)/)
    match&.[](1)
  end

  def cover_image_display_url
    cover_image_url.presence || first_image_url
  end

  def body_image_urls
    text = body_for
    return [] if text.blank?

    text.scan(/!\[.*?\]\((.+?)\)/).flatten
  end

  def translated_at(locale)
    entry = translations_status.is_a?(Hash) ? translations_status[locale.to_s] : nil
    return nil unless entry.is_a?(Hash) && entry["translated_at"].present?
    Time.iso8601(entry["translated_at"])
  rescue ArgumentError
    nil
  end

  def translation_error
    return nil unless translations_status.is_a?(Hash)
    err = translations_status["_error"]
    err.is_a?(Hash) && err["class"].present? ? err : nil
  end

  def enqueue_post_save_jobs!
    text_changed = saved_changes.keys.intersect?(%w[title body])
    if text_changed || translation_source_hash.nil?
      ArticleTranslationJob.perform_later(id)
    end
  end

  # :error if a permanent failure has been recorded.
  # :pending if no source hash yet, or any target locale lacks a translated_at.
  # :complete otherwise.
  def translation_status
    return :error if translation_error
    return :pending if translation_source_hash.blank?

    target_locales = (I18n.available_locales.map(&:to_s) - [ "fr" ])
    status = translations_status.is_a?(Hash) ? translations_status : {}
    return :pending unless target_locales.all? { |loc| status.dig(loc, "translated_at").present? }

    :complete
  end

  def translated_count
    return 0 unless translations_status.is_a?(Hash)
    target_locales = (I18n.available_locales.map(&:to_s) - [ "fr" ])
    target_locales.count { |loc| translations_status.dig(loc, "translated_at").present? }
  end

  # Stale = current FR text no longer matches the hash that produced the
  # existing translations. Either nothing has run yet (hash nil) or the FR
  # source changed and the translator hasn't caught up.
  def translation_stale?
    return true if translation_source_hash.blank?
    current_fr_hash != translation_source_hash
  end

  def last_translated_at
    return nil unless translations_status.is_a?(Hash)
    timestamps = translations_status.each_with_object([]) do |(key, value), acc|
      next if key == "_error"
      acc << value["translated_at"] if value.is_a?(Hash) && value["translated_at"].present?
    end
    return nil if timestamps.empty?
    Time.iso8601(timestamps.max)
  rescue ArgumentError
    nil
  end

  private

  # Memoized per-instance — index pages render N rows and call
  # translation_stale? once each, but the hash inputs (FR title+body) don't
  # change within a request. ActiveRecord re-instantiates the model on each
  # query, so this lives only as long as the instance.
  def current_fr_hash
    @current_fr_hash ||= Digest::SHA256.hexdigest("#{title_for(:fr)}\n#{body_for(:fr)}")
  end

  def generate_slug
    fr_title = title["fr"] || title[I18n.default_locale.to_s] || title.values.first
    self.slug = fr_title.parameterize if fr_title.present?
  end
end
