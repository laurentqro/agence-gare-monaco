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

  private

  def generate_slug
    fr_title = title["fr"] || title[I18n.default_locale.to_s] || title.values.first
    self.slug = fr_title.parameterize if fr_title.present?
  end
end
