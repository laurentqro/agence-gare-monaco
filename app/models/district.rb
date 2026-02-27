class District < ApplicationRecord
  has_many :buildings, dependent: :nullify
  has_many :properties, dependent: :nullify

  validates :name, presence: true
  validates :city, presence: true
  validates :immotoolbox_id, uniqueness: true, allow_nil: true

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  private

  def generate_slug
    self.slug = name.parameterize
  end
end
