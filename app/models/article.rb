class Article < ApplicationRecord
  belongs_to :category

  validates :slug, presence: true, uniqueness: true

  before_validation :generate_slug, if: -> { slug.blank? && title.is_a?(Hash) }

  scope :published, -> { where(published: true) }
  scope :featured, -> { where(featured: true) }

  def title_for(locale = I18n.locale)
    return "" unless title.is_a?(Hash)
    title[locale.to_s] || title[I18n.default_locale.to_s] || title.values.first || ""
  end

  def body_for(locale = I18n.locale)
    return "" unless body.is_a?(Hash)
    body[locale.to_s] || body[I18n.default_locale.to_s] || body.values.first || ""
  end

  private

  def generate_slug
    fr_title = title["fr"] || title[I18n.default_locale.to_s] || title.values.first
    self.slug = fr_title.parameterize if fr_title.present?
  end
end
