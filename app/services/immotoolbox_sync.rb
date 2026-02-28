class ImmotoolboxSync
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

    @client.fetch_districts.each do |data|
      district = District.find_or_initialize_by(immotoolbox_id: data["id"])
      is_new = district.new_record?

      district.assign_attributes(
        name: data["name"],
        city: data["city"] || "Monaco",
        latitude: data["latitude"],
        longitude: data["longitude"]
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
        name_alt: data["nameAlt"],
        address: data["address"],
        city: data["city"] || "Monaco",
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

      # Fetch texts and images for this property
      texts = @client.fetch_texts(property_id: data["id"])
      images = @client.fetch_images(property_id: data["id"])

      # Build multilingual title and description
      title = {}
      description = {}
      texts.each do |text|
        lang = text["language"]
        title[lang] = text["title"] if text["title"].present?
        description[lang] = text["description"] if text["description"].present?
      end

      # Resolve district and building
      district = District.find_by(immotoolbox_id: data.dig("district", "id")) if data["district"]
      building = Building.find_by(immotoolbox_id: data.dig("building", "id")) if data["building"]

      property.assign_attributes(
        reference: data["reference"],
        title: title,
        description: description,
        price: data["price"],
        currency: data["currency"] || "EUR",
        service_charges: data["serviceCharges"],
        service_charges_included: data["serviceChargesIncluded"] || false,
        transaction_type: map_transaction_type(data["typeTransaction"]),
        property_type: data["typeProperty"] || "apartment",
        subtype: data["subtype"],
        country: data.dig("country", "code") || "MC",
        city: data.dig("city", "name") || "Monaco",
        district: district,
        building: building,
        address: data["address"],
        latitude: data["latitude"],
        longitude: data["longitude"],
        floor: data["floor"],
        num_rooms: data["numRooms"],
        num_bedrooms: data["numBedrooms"],
        num_bathrooms: data["numBathrooms"],
        num_parkings: data["numParkings"],
        num_cellars: data["numCellars"],
        living_area: data["livingArea"],
        total_area: data["totalArea"],
        terrace_area: data["terraceArea"],
        land_area: data["landArea"],
        garden_area: data["gardenArea"],
        furnished: data["furnished"] || false,
        published: true,
        featured: data["featured"] || false,
        exclusivity: data["exclusivity"] || false,
        shared_exclusivity: data["sharedExclusivity"] || false,
        video_url: data["videoUrl"],
        virtual_tour_url: data["virtualTourUrl"],
        has_360_tour: data["has360Tour"] || false,
        synced_at: Time.current
      )
      property.save!

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

  def sync_property_images(property, images_data)
    api_image_ids = images_data.map { |img| img["id"] }

    # Remove images that are no longer in API
    property.property_images.where.not(immotoolbox_id: nil)
            .where.not(immotoolbox_id: api_image_ids)
            .destroy_all

    # Create or update images
    images_data.each do |img_data|
      urls = img_data["urls"] || {}

      image = property.property_images.find_or_initialize_by(immotoolbox_id: img_data["id"])
      image.assign_attributes(
        remote_url: urls["large"] || urls["medium"] || urls["small"] || urls["thumb"],
        thumb_url: urls["thumb"],
        small_url: urls["small"],
        medium_url: urls["medium"],
        large_url: urls["large"],
        position: img_data["position"] || 0,
        is_plan: img_data["isPlan"] || false
      )
      image.save!
    end
  end
end
