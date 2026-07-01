class PropertyImage < ApplicationRecord
  belongs_to :property

  has_one_attached :image

  validates :remote_url, presence: true

  scope :ordered, -> { order(:position) }

  after_commit :enqueue_property_brochure_generation

  # Bulk callers (e.g. the Immotoolbox sync) save many images for one property in
  # a loop. Wrap the loop in this block to skip the per-image enqueue, then
  # enqueue a single brochure job for the property afterwards.
  def self.suppress_brochure_generation
    previous = Thread.current[:suppress_brochure_generation]
    Thread.current[:suppress_brochure_generation] = true
    yield
  ensure
    Thread.current[:suppress_brochure_generation] = previous
  end

  def self.brochure_generation_suppressed?
    Thread.current[:suppress_brochure_generation] == true
  end

  private

  def enqueue_property_brochure_generation
    return if self.class.brochure_generation_suppressed?
    PropertyBrochureGenerationJob.perform_later(property_id) if property_id.present?
  end
end
