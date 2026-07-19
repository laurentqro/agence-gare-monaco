class Category < ApplicationRecord
  has_many :articles, dependent: :destroy

  validate :name_has_at_least_one_value
  validates :slug, presence: true, uniqueness: true

  def name_for(locale = I18n.locale)
    return "" unless name.is_a?(Hash)
    name[locale.to_s].presence || name[I18n.default_locale.to_s].presence || name.values.first || ""
  end

  def slug_for(locale = I18n.locale)
    localized_name = name.is_a?(Hash) && name[locale.to_s].presence
    # Pass the locale down: parameterize transliterates with the runtime
    # I18n.locale's rules by default, which garbles Cyrillic names when
    # building a link to another locale's page.
    localized_name ? localized_name.parameterize(locale: locale) : slug
  end

  def self.find_by_localized_slug(slug_param, locale = I18n.locale)
    find_each do |category|
      return category if category.slug_for(locale) == slug_param
    end
    # Fall back to base slug lookup
    find_by(slug: slug_param)
  end

  private

  def name_has_at_least_one_value
    if !name.is_a?(Hash) || name.values.none?(&:present?)
      errors.add(:name, :blank)
    end
  end
end
