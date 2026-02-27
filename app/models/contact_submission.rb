class ContactSubmission < ApplicationRecord
  belongs_to :property, optional: true

  validates :form_type, presence: true, inclusion: { in: %w[contact enquiry] }
  validates :name, presence: true
  validates :email, presence: true
  validates :message, presence: true

  scope :unread, -> { where(read: false) }
end
