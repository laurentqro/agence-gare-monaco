class InformationRequest < ApplicationRecord
  belongs_to :property, optional: true

  validates :form_type, presence: true, inclusion: { in: %w[contact enquiry] }
  validates :name, presence: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, presence: true

  scope :unread, -> { where(read: false) }

  def deliverable_email?
    email.to_s.match?(URI::MailTo::EMAIL_REGEXP)
  end

  def mark_read!
    update_column(:read, true) unless read?
  end
end
