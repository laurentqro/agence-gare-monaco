class PropertyDocument < ApplicationRecord
  belongs_to :property

  has_one_attached :file
end
