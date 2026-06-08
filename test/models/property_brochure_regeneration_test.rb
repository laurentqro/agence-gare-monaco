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

  test "image saves inside suppress_brochure_generation do not enqueue the job" do
    property = build_property
    property.save!

    assert_no_enqueued_jobs(only: PropertyBrochureGenerationJob) do
      PropertyImage.suppress_brochure_generation do
        property.property_images.create!(remote_url: "https://example.com/a.jpg", position: 1)
        property.property_images.create!(remote_url: "https://example.com/b.jpg", position: 2)
      end
    end
  end

  test "suppression is reset after the block even when it raises" do
    property = build_property
    property.save!

    assert_raises(RuntimeError) do
      PropertyImage.suppress_brochure_generation { raise "boom" }
    end

    # Callback works normally again afterwards.
    assert_enqueued_with(job: PropertyBrochureGenerationJob, args: [ property.id ]) do
      property.property_images.create!(remote_url: "https://example.com/c.jpg", position: 1)
    end
  end
end
