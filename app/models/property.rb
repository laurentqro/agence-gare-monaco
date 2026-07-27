class Property < ApplicationRecord
  BROCHURE_TRIGGER_COLUMNS = %w[
    title description price num_rooms living_area reference transaction_type
    property_type country city district_id building_id off_market published
    video_url virtual_tour_url
  ].freeze

  TARGET_LOCALES = PropertyTranslator::LOCALES

  belongs_to :district, optional: true
  belongs_to :building, optional: true
  has_many :property_images, dependent: :destroy
  has_many :property_documents, dependent: :destroy
  has_many :information_requests, dependent: :nullify
  has_many :property_shares, dependent: :destroy
  has_many_attached :brochures

  validates :reference, presence: true, uniqueness: true
  validates :transaction_type, presence: true, inclusion: { in: %w[sale rental] }
  validates :property_type, presence: true
  validates :country, presence: true
  validates :city, presence: true
  validates :immotoolbox_id, uniqueness: true, allow_nil: true

  scope :published, -> { where(published: true) }
  scope :publicly_visible, -> { published.where(off_market: false) }
  scope :for_sale, -> { where(transaction_type: "sale") }
  scope :for_rental, -> { where(transaction_type: "rental") }
  scope :in_country, ->(country) { where(country: country) }
  scope :in_district, ->(district) { where(district: district) }
  scope :of_type, ->(type) { where(property_type: type) }
  # A failed re-translation keeps its old non-nil hash (only success updates
  # it), so failure is detected by the recorded "_error" itself, in SQL:
  # loading every row's four multi-locale JSON columns to find the usual
  # handful of failures would not scale with casual operator use.
  scope :translation_failed, -> {
    where("json_extract(translations_status, '$._error.class') IS NOT NULL")
  }

  def title_for(locale)
    title&.dig(locale.to_s).presence || title&.dig(I18n.default_locale.to_s).presence || ""
  end

  def description_for(locale)
    description&.dig(locale.to_s).presence || description&.dig(I18n.default_locale.to_s).presence || ""
  end

  def intro_for(locale)
    intro&.dig(locale.to_s).presence || intro&.dig(I18n.default_locale.to_s).presence || ""
  end

  def cover_image
    property_images.order(:position).first
  end

  def photos
    property_images.where(is_plan: false).order(:position)
  end

  def plans
    property_images.where(is_plan: true).order(:position)
  end

  def slug_for(locale)
    # Pin transliteration to the target locale so the slug is identical no
    # matter which locale's page renders the link (canonical, hreflang, sitemap).
    title_for(locale).parameterize(locale: locale.to_sym)
  end

  def location_label
    parts = [ building&.name, district&.name ].compact
    parts.any? ? parts.join(", ") : city
  end

  def brochure_filename
    parts = []
    parts << "#{num_rooms}p" if num_rooms.present?
    if district.present?
      parts << district.name.parameterize
      parts << building.name.parameterize if building.present?
    elsif building.present?
      parts << building.name.parameterize
    else
      parts << reference
    end
    "#{parts.join('-')}.pdf"
  end

  def formatted_price
    return nil if price.blank?
    price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
  end

  def cached_brochure(locale:, include_logo:)
    brochures.find do |attachment|
      meta = attachment.blob.metadata
      meta["locale"].to_s == locale.to_s && meta["include_logo"] == include_logo
    end
  end

  def translated_at_for(locale)
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

  # Checks the content JSON itself rather than the translations_status stamps:
  # the translator fills all locales in one pass, but content can still go
  # partial (manually created properties, historical partial-update wipes),
  # and the admin badge must report what a visitor would actually see. A
  # locale only counts when every field the FR original has (title, intro,
  # description) also has content for that locale; otherwise the public page
  # falls back to French for the missing field.
  def translated_locale?(locale)
    loc = locale.to_s
    return false unless locale_content?(title, loc)
    [ intro, description ].all? do |column|
      !locale_content?(column, "fr") || locale_content?(column, loc)
    end
  end

  # Drops the recorded failure and nils the source hash together: the nil hash
  # is what makes the next PropertyTranslationJob actually translate instead of
  # no-opping on an unchanged digest, and dropping the marker stops the admin
  # reporting a failure that is being retried right now. update_columns skips
  # callbacks on purpose so this does not itself enqueue another job.
  def clear_translation_failure!
    status = (translations_status || {}).dup
    status.delete("_error")
    update_columns(translations_status: status, translation_source_hash: nil)
  end

  # The translation job enqueues brochure regen itself on success, so the
  # brochure branch only fires when translations aren't being re-run.
  # Returns a symbol naming what is needed (:translation, :brochure, or nil).
  #
  # Pass defer_brochure: true when the caller will sync images afterwards and
  # must enqueue the brochure job itself once images are current (otherwise an
  # async worker could regenerate brochures against a stale image set). In that
  # mode the :brochure branch returns its symbol WITHOUT enqueuing, leaving the
  # caller responsible for the brochure job.
  def enqueue_post_save_jobs!(defer_brochure: false)
    text_changed = saved_changes.keys.intersect?(%w[title intro description])
    # A property with no translation hash keeps retrying until it succeeds,
    # including one carrying a recorded failure: the causes are transient or
    # operator-fixable (expired key, quota, outage), and leaving a property
    # permanently untranslated is worse than the retry cost. Taking this branch
    # also suppresses the brochure branch below, so an untranslated property
    # never gets brochures rendered from missing translations.
    if text_changed || translation_source_hash.nil?
      PropertyTranslationJob.perform_later(id)
      :translation
    elsif saved_changes.keys.intersect?(BROCHURE_TRIGGER_COLUMNS)
      PropertyBrochureGenerationJob.perform_later(id) unless defer_brochure
      :brochure
    end
  end

  private

  def locale_content?(column, locale)
    column.is_a?(Hash) && column[locale].present?
  end
end
