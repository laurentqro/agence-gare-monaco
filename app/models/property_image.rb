class PropertyImage < ApplicationRecord
  belongs_to :property

  validates :remote_url, presence: true

  scope :ordered, -> { order(:position) }

  after_commit :enqueue_property_brochure_generation

  private

  def enqueue_property_brochure_generation
    PropertyBrochureGenerationJob.perform_later(property_id) if property_id.present?
  end
end
