class Article < ApplicationRecord
  TARGET_LOCALES = ArticleTranslator::LOCALES

  belongs_to :category

  has_one_attached :cover_image

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

  def meta_description_for(locale = I18n.locale)
    return "" unless meta_description.is_a?(Hash)
    meta_description[locale.to_s].presence || meta_description[I18n.default_locale.to_s].presence || ""
  end

  # Per-locale localised slug (SEO audit 0.2). FR always resolves to the pinned
  # `slug` column (the canonical, indexed slug and stable lookup key); other
  # locales use their entry in the `slugs` JSON hash, falling back to the FR
  # slug when they have none yet.
  def slug_for(locale = I18n.locale)
    return slug if locale.to_s == I18n.default_locale.to_s
    (slugs.is_a?(Hash) && slugs[locale.to_s].presence) || slug
  end

  # Generate a collision-free localised slug from a title (SEO audit 0.2). The
  # base is the locale-transliterated parameterization; if that already belongs
  # to another article (its FR `slug` or its own `slugs[locale]`), a numeric
  # suffix is appended (-2, -3, ...) so two articles never share one locale's
  # URL. Returns "" for a title that parameterizes to nothing (caller skips it).
  # Pass except_id to exclude the article being re-minted from the clash check.
  def self.mint_localized_slug(title, locale, except_id: nil)
    base = title.to_s.parameterize(locale: locale.to_sym)
    return "" if base.blank?

    candidate = base
    suffix = 1
    while localized_slug_taken?(candidate, locale, except_id: except_id)
      suffix += 1
      candidate = "#{base}-#{suffix}"
    end
    candidate
  end

  # True if any OTHER article already uses this slug for the locale, either as
  # its canonical FR `slug` or its per-locale `slugs[locale]`.
  def self.localized_slug_taken?(candidate, locale, except_id: nil)
    scope = where(slug: candidate).or(
      where("json_extract(slugs, ?) = ?", "$.#{locale}", candidate)
    )
    scope = scope.where.not(id: except_id) if except_id
    scope.exists?
  end

  # Resolve a URL slug back to its article for the given locale. Matches the
  # locale's own slug first, then the canonical FR slug so previously-indexed
  # shared-slug URLs (one slug across all locales) still resolve.
  def self.find_by_localized_slug(slug_param, locale = I18n.locale)
    find_each do |article|
      return article if article.slug_for(locale) == slug_param
    end
    find_by(slug: slug_param)
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
    text_changed = saved_changes.keys.intersect?(%w[title body meta_description])
    if text_changed || translation_source_hash.nil?
      ArticleTranslationJob.perform_later(id)
    end
  end

  def translation_status
    return :error if translation_error
    return :pending if translation_source_hash.blank?
    return :stale if translation_stale? && translated_count.positive?
    translated_count == TARGET_LOCALES.size ? :complete : :pending
  end

  def translated_count
    return @translated_count if defined?(@translated_count)
    @translated_count = if translations_status.is_a?(Hash)
      TARGET_LOCALES.count { |loc| translations_status.dig(loc, "translated_at").present? }
    else
      0
    end
  end

  # FR source no longer matches the hash that produced the existing
  # translations — the translator hasn't caught up yet (or hasn't run).
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

  # Single source of truth for the FR-source hash. Index pages render N rows
  # and call translation_stale? once each — the inputs don't change within a
  # request, so memoize. The translator reads the same value to decide whether
  # to skip the LLM call.
  # The FR meta description joins the hash only when present, so pre-existing
  # articles without one keep their stored hash and are not mass-retranslated.
  def current_fr_hash
    @current_fr_hash ||= begin
      parts = [ title_for(:fr), body_for(:fr) ]
      parts << meta_description_for(:fr) if meta_description_for(:fr).present?
      Digest::SHA256.hexdigest(parts.join("\n"))
    end
  end

  private

  def generate_slug
    fr_title = title["fr"] || title[I18n.default_locale.to_s] || title.values.first
    self.slug = fr_title.parameterize if fr_title.present?
  end
end
