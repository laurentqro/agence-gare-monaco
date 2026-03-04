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
    stats = { created: 0, updated: 0, unpublished: 0, skipped: 0 }

    api_properties = @client.fetch_all_properties
    synced_ids = []

    api_properties.each do |data|
      property = Property.find_or_initialize_by(immotoolbox_id: data["id"])

      # Skip manually edited properties
      if property.persisted? && property.manually_edited?
        stats[:skipped] += 1
        synced_ids << data["id"]
        next
      end

      is_new = property.new_record?

      # Build multilingual title and description from inline texts
      title = {}
      description = {}
      texts = data["texts"]
      if texts.is_a?(Hash)
        texts.each do |lang, text_data|
          title[lang] = sanitize_html(text_data["title"]) if text_data["title"].present?
          description[lang] = sanitize_html(text_data["description"]) if text_data["description"].present?
        end
      end

      # Resolve district and building
      district = District.find_by(immotoolbox_id: data.dig("district", "id")) if data["district"]
      building = Building.find_by(immotoolbox_id: data["building_id"]) if data["building_id"]

      property.assign_attributes(
        reference: data["reference"],
        title: title,
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

      # Sync images from inline images array
      images = data["images"] || []
      sync_property_images(property, images)

      synced_ids << data["id"]
      is_new ? stats[:created] += 1 : stats[:updated] += 1
    end

    # Unpublish synced properties that are no longer in the API response
    stale_properties = Property.where.not(immotoolbox_id: nil)
                               .where.not(immotoolbox_id: synced_ids)
                               .where(published: true)
    stale_properties.update_all(published: false)
    stats[:unpublished] = stale_properties.count

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

  def sanitize_html(text)
    Nokogiri::HTML.fragment(text).text.gsub("\u00A0", " ").squish
  end

  def parse_integer(value)
    return nil if value.blank?
    Integer(value, exception: false)
  end

  def sync_property_images(property, images_data)
    api_image_ids = images_data.map { |img| img["id"] }

    # Remove images that are no longer in API
    property.property_images.where.not(immotoolbox_id: nil)
            .where.not(immotoolbox_id: api_image_ids)
            .destroy_all

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
      image.save!
    end
  end
end
