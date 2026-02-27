class PropertyImage < ApplicationRecord
  belongs_to :property

  validates :remote_url, presence: true

  scope :ordered, -> { order(:position) }
end
