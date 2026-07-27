class ImmotoolboxSync
  include ActionView::Helpers::SanitizeHelper

  def initialize(api_token:)
    @client = ImmotoolboxClient.new(api_token: api_token)
  end

  def sync_all
    {
      districts: sync_districts,
      buildings: sync_buildings,
      properties: sync_properties
    }
  end

  def sync_districts
    stats = { created: 0, updated: 0 }

    districts_data = @client.fetch_districts
    # API returns a Hash keyed by ID strings; normalize to array of values
    items = districts_data.is_a?(Hash) ? districts_data.values : districts_data

    items.each do |data|
      district = District.find_or_initialize_by(immotoolbox_id: data["id"])
      is_new = district.new_record?

      district.assign_attributes(
        name: data["name"],
        city: data.dig("city", "name") || data["city"] || "Monaco",
        latitude: data["lat"] || data["latitude"],
        longitude: data["lng"] || data["longitude"]
      )
      # Reset slug so it regenerates from new name
      district.slug = nil if district.name_changed?
      district.save!

      is_new ? stats[:created] += 1 : stats[:updated] += 1
    end

    stats
  end

  def sync_buildings
    stats = { created: 0, updated: 0 }

    @client.fetch_buildings.each do |data|
      building = Building.find_or_initialize_by(immotoolbox_id: data["id"])
      is_new = building.new_record?

      district = District.find_by(immotoolbox_id: data.dig("district", "id")) if data["district"]

      building.assign_attributes(
        name: data["name"],
        name_alt: data["name_alt"] || data["nameAlt"],
        address: data["address"],
        city: data.dig("city", "name") || data["city"] || "Monaco",
        district: district
      )
      building.save!

      is_new ? stats[:created] += 1 : stats[:updated] += 1
    end

    stats
  end

  def sync_properties
    stats = { created: 0, updated: 0, unpublished: 0 }

    api_properties = @client.fetch_all_properties
    synced_ids = []

    district_ids = api_properties.map { |d| d.dig("district", "id") }.compact.uniq
    building_ids = api_properties.map { |d| d["building_id"] }.compact.uniq
    districts_by_id = District.where(immotoolbox_id: district_ids).index_by(&:immotoolbox_id)
    buildings_by_id = Building.where(immotoolbox_id: building_ids).index_by(&:immotoolbox_id)

    api_properties.each do |data|
      property = Property.find_or_initialize_by(immotoolbox_id: data["id"])
      is_new = property.new_record?

      # Only ingest French text from Immotoolbox — English arrives inconsistent
      # in quality. All 8 non-FR locales are machine-translated from FR.
      title = (property.title || {}).dup
      intro = (property.intro || {}).dup
      description = (property.description || {}).dup
      fr_texts = data.dig("texts", "fr")
      if fr_texts.is_a?(Hash)
        title["fr"] = sanitize_html(fr_texts["title"]) if fr_texts["title"].present?
        intro["fr"] = sanitize_html(fr_texts["intro"]) if fr_texts["intro"].present?
        description["fr"] = sanitize_description_html(fr_texts["description"]) if fr_texts["description"].present?
      end

      district = districts_by_id[data.dig("district", "id")]
      building = buildings_by_id[data["building_id"]]

      property.assign_attributes(
        reference: data["reference"],
        title: title,
        intro: intro,
        description: description,
        price: data["price"],
        currency: data["currency"] || "EUR",
        service_charges: data["servicecharges"] || data["serviceCharges"],
        service_charges_included: data["serviceschargesIncluded"] || data["serviceChargesIncluded"] || false,
        transaction_type: map_transaction_type(data["type_transaction_code"] || data["typeTransaction"]),
        property_type: map_property_type(data["type_property"] || data["typeProperty"]),
        subtype: data["subtype_property"] || data["subtype"],
        country: data["country_code"] || data.dig("country", "code") || "MC",
        city: data["city_name"] || data.dig("city", "name") || "Monaco",
        district: district,
        building: building,
        address: data["address"],
        latitude: data["lat"] || data["latitude"],
        longitude: data["lng"] || data["longitude"],
        floor: parse_integer(data["floor"]),
        num_rooms: parse_integer(data["num_rooms"] || data["numRooms"]),
        num_bedrooms: parse_integer(data["num_bedrooms"] || data["numBedrooms"]),
        num_bathrooms: parse_integer(data["num_bathrooms"] || data["numBathrooms"]),
        num_parkings: parse_integer(data["num_parkings"] || data["numParkings"]),
        num_cellars: parse_integer(data["num_cellars"] || data["numCellars"]),
        living_area: data["living_area"] || data["livingArea"],
        total_area: data["total_area"] || data["totalArea"],
        terrace_area: data["terrace_area"] || data["terraceArea"],
        land_area: data["land_area"] || data["landArea"],
        garden_area: data["garden_area"] || data["gardenArea"],
        furnished: data["furnished"] || false,
        published: true,
        featured: data["featured"] || false,
        exclusivity: data["exclusivity"] || false,
        shared_exclusivity: data["sharedExclusivity"] || false,
        video_url: data["urlVideo"] || data["videoUrl"],
        virtual_tour_url: data["urlVirtual"] || data["virtualTourUrl"],
        has_360_tour: data["has360Tour"] || false,
        synced_at: Time.current
      )
      property.save!
      # Defer the brochure job: it must be enqueued AFTER images are synced so an
      # async worker can't regenerate brochures against the old image set.
      enqueued = property.enqueue_post_save_jobs!(defer_brochure: true)

      # Sync images from inline images array. Suppress the per-image brochure
      # enqueue so a property with many images produces one job, not one per
      # image, then enqueue a single brochure job below.
      images = data["images"] || []
      images_changed = PropertyImage.suppress_brochure_generation do
        sync_property_images(property, images)
      end

      # Now that images are current, enqueue at most one brochure job per
      # property. Skip when a translation job was enqueued — that job regenerates
      # brochures on success, and it runs after this sync. Also skip when neither
      # the property record nor its image set actually changed: this sync runs
      # every few minutes over the whole catalogue, and each brochure job renders
      # 18 PDFs (9 locales x 2 logo variants), so regenerating unchanged
      # properties would saturate the workers and churn Active Storage blobs.
      if enqueued != :translation && (enqueued == :brochure || images_changed)
        PropertyBrochureGenerationJob.perform_later(property.id)
      end

      synced_ids << data["id"]
      is_new ? stats[:created] += 1 : stats[:updated] += 1
    end

    # Unpublish synced properties that are no longer in the API response
    stats[:unpublished] = Property.where.not(immotoolbox_id: nil)
                                  .where.not(immotoolbox_id: synced_ids)
                                  .where(published: true)
                                  .update_all(published: false)

    stats
  end

  private

  def map_transaction_type(api_type)
    case api_type&.downcase
    when "sale", "vente" then "sale"
    when "rental", "location" then "rental"
    else api_type || "sale"
    end
  end

  def map_property_type(api_type)
    case api_type&.downcase
    when "apartment", "appartement" then "apartment"
    when "house", "maison", "villa" then "house"
    when "commercial", "commerce", "bureaux", "bureau", "office" then "commercial"
    when "parking", "parking / garage / box" then "parking"
    when "land", "terrain" then "land"
    else api_type&.downcase || "apartment"
    end
  end

  # For single-line fields (title, intro): strip all tags and collapse whitespace.
  def sanitize_html(text)
    Nokogiri::HTML.fragment(text).text.gsub("\u00A0", " ").squish
  end

  # For the description: preserve the API's line structure (paragraphs, <br>
  # line breaks, "- " bullet lists) as newlines while stripping tags/entities.
  def sanitize_description_html(html)
    text = html.to_s
    # Normalize source newlines: the API wraps tags with literal CRLFs that would
    # otherwise survive as extra blank lines once <br> also becomes a newline.
    text = text.gsub(/\r\n?/, "\n")
    # Decode &nbsp; up front (the sanitizer leaves it as a literal space entity).
    text = text.gsub("&nbsp;", " ")
    # Line-breaking tags become newlines (swallowing any source newline that
    # already trails the tag, so one <br> yields exactly one line break).
    text = text.gsub(/<br\s*\/?>\n?/i, "\n")
    text = text.gsub(%r{</(?:p|div|li|h[1-6])>\n?}i, "\n")
    # List items start a new bulleted line.
    text = text.gsub(/\n?<li[^>]*>/i, "\n- ")
    # Strip the remaining tags and decode HTML entities (&eacute;, &#39;, \u2026).
    text = Rails::HTML5::FullSanitizer.new.sanitize(text)
    # Collapse runs of horizontal whitespace but keep newlines.
    text = text.gsub(/[^\S\n]+/, " ")
    # Trim trailing spaces on each line, then collapse 3+ newlines to a blank line.
    text = text.gsub(/ *\n/, "\n").gsub(/\n{3,}/, "\n\n")
    text.strip
  end

  def parse_integer(value)
    return nil if value.blank?
    Integer(value, exception: false)
  end

  # Returns true when the property's image set actually changed (any image
  # removed, created, or modified), so the caller can decide whether a brochure
  # regeneration is warranted.
  def sync_property_images(property, images_data)
    api_image_ids = images_data.map { |img| img["id"] }

    # Remove images that are no longer in API
    removed = property.property_images.where.not(immotoolbox_id: nil)
                      .where.not(immotoolbox_id: api_image_ids)
                      .destroy_all
    changed = removed.any?

    # Create or update images (look up globally since images can be shared across properties)
    images_data.each do |img_data|
      remote_url = img_data["large"] || img_data["medium"] || img_data["small"] || img_data["thumb"] || img_data["original"]
      next if remote_url.blank?

      image = PropertyImage.find_or_initialize_by(immotoolbox_id: img_data["id"])
      image.assign_attributes(
        property: property,
        remote_url: remote_url,
        thumb_url: img_data["thumb"],
        small_url: img_data["small"],
        medium_url: img_data["medium"],
        large_url: img_data["large"],
        position: img_data["order"] || img_data["position"] || 0,
        is_plan: img_data["isPlan"] || false
      )
      # Ignore property_id when deciding whether the image changed. Images are
      # looked up globally because one can be shared across properties, and each
      # owner's turn in the sync reassigns it — so property_id alone flips back
      # and forth every run and would report a permanent change, regenerating
      # brochures for both properties on every tick.
      changed = true if image.new_record? || image.changed.any? { |attr| attr != "property_id" }
      image.save!
    end

    changed
  end
end
