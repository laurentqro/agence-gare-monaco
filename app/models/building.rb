class Building < ApplicationRecord
  belongs_to :district, optional: true
  has_many :properties, dependent: :nullify

  validates :name, presence: true
  validates :immotoolbox_id, uniqueness: true, allow_nil: true
end
