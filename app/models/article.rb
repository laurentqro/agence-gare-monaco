class Article < ApplicationRecord
  belongs_to :category

  validates :slug, presence: true, uniqueness: true

  scope :published, -> { where(published: true) }
  scope :featured, -> { where(featured: true) }
end
