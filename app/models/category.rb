class Category < ApplicationRecord
  has_many :articles, dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true
end
