class Property < ApplicationRecord
  belongs_to :district, optional: true
  belongs_to :building, optional: true
  has_many :property_images, dependent: :destroy
  has_many :property_documents, dependent: :destroy
  has_many :contact_submissions, dependent: :nullify

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

  def title_for(locale)
    title&.dig(locale.to_s).presence || title&.dig(I18n.default_locale.to_s).presence || ""
  end

  def description_for(locale)
    description&.dig(locale.to_s).presence || description&.dig(I18n.default_locale.to_s).presence || ""
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
    title_for(locale).parameterize
  end

  def formatted_price
    return nil if price.blank?
    price.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
  end

  def recent?
    created_at >= 30.days.ago
  end
end
