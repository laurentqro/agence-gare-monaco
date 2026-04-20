require "test_helper"

class PropertyBrochureRegenerationTest < ActiveJob::TestCase
  def build_property(**overrides)
    Property.new({
      reference: "MC-REGEN-#{SecureRandom.hex(3)}",
      title: { "fr" => "Studio" },
      description: { "fr" => "Desc" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 1_000_000,
      published: true
    }.merge(overrides))
  end

  test "creating a property enqueues the brochure job" do
    property = build_property
    assert_enqueued_with(job: PropertyBrochureGenerationJob) do
      property.save!
    end
  end

  test "updating a content field enqueues the brochure job" do
    property = build_property
    property.save!

    assert_enqueued_with(job: PropertyBrochureGenerationJob, args: [ property.id ]) do
      property.update!(price: 2_000_000)
    end
  end

  test "touch-only updates do not enqueue" do
    property = build_property
    property.save!

    assert_no_enqueued_jobs(only: PropertyBrochureGenerationJob) do
      property.touch
    end
  end

  test "creating a property image enqueues the job for its property" do
    property = build_property
    property.save!

    assert_enqueued_with(job: PropertyBrochureGenerationJob, args: [ property.id ]) do
      property.property_images.create!(remote_url: "https://example.com/a.jpg", position: 1)
    end
  end

  test "updating a property image enqueues the job" do
    property = build_property
    property.save!
    image = property.property_images.create!(remote_url: "https://example.com/a.jpg", position: 1)

    assert_enqueued_with(job: PropertyBrochureGenerationJob, args: [ property.id ]) do
      image.update!(position: 2)
    end
  end

  test "destroying a property image enqueues the job" do
    property = build_property
    property.save!
    image = property.property_images.create!(remote_url: "https://example.com/a.jpg", position: 1)

    assert_enqueued_with(job: PropertyBrochureGenerationJob, args: [ property.id ]) do
      image.destroy!
    end
  end
end
