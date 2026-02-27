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
  scope :for_sale, -> { where(transaction_type: "sale") }
  scope :for_rental, -> { where(transaction_type: "rental") }
end
