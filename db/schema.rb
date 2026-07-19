# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_19_215854) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "articles", force: :cascade do |t|
    t.json "body"
    t.integer "category_id", null: false
    t.string "cover_image_url"
    t.datetime "created_at", null: false
    t.boolean "featured", default: false
    t.integer "legacy_id"
    t.json "meta_description"
    t.boolean "published", default: false
    t.datetime "published_at"
    t.string "slug", null: false
    t.json "title"
    t.string "translation_source_hash"
    t.json "translations_status", default: {}
    t.datetime "updated_at", null: false
    t.index ["category_id"], name: "index_articles_on_category_id"
    t.index ["featured"], name: "index_articles_on_featured"
    t.index ["legacy_id"], name: "index_articles_on_legacy_id", unique: true
    t.index ["published"], name: "index_articles_on_published"
    t.index ["slug"], name: "index_articles_on_slug", unique: true
  end

  create_table "buildings", force: :cascade do |t|
    t.string "address"
    t.string "city"
    t.datetime "created_at", null: false
    t.integer "district_id"
    t.integer "immotoolbox_id"
    t.string "name", null: false
    t.string "name_alt"
    t.datetime "updated_at", null: false
    t.index ["district_id"], name: "index_buildings_on_district_id"
    t.index ["immotoolbox_id"], name: "index_buildings_on_immotoolbox_id", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.json "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_categories_on_slug", unique: true
  end

  create_table "contacts", force: :cascade do |t|
    t.string "address"
    t.string "category", default: "contact", null: false
    t.string "city"
    t.string "company"
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.integer "legacy_id"
    t.text "notes"
    t.string "phone"
    t.string "postcode"
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_contacts_on_category"
    t.index ["legacy_id"], name: "index_contacts_on_legacy_id_for_non_peers", unique: true, where: "category != 'peer'"
    t.index ["legacy_id"], name: "index_contacts_on_legacy_id_for_peers", unique: true, where: "category = 'peer'"
  end

  create_table "districts", force: :cascade do |t|
    t.string "city", null: false
    t.datetime "created_at", null: false
    t.integer "immotoolbox_id"
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "longitude", precision: 10, scale: 7
    t.string "name", null: false
    t.string "slug"
    t.datetime "updated_at", null: false
    t.index ["immotoolbox_id"], name: "index_districts_on_immotoolbox_id", unique: true
    t.index ["slug"], name: "index_districts_on_slug", unique: true
  end

  create_table "exchange_rates", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "currency", null: false
    t.datetime "fetched_at", null: false
    t.decimal "rate", precision: 12, scale: 6, null: false
    t.datetime "updated_at", null: false
    t.index ["currency"], name: "index_exchange_rates_on_currency", unique: true
  end

  create_table "information_requests", force: :cascade do |t|
    t.string "country"
    t.datetime "created_at", null: false
    t.string "email", null: false
    t.string "form_type", null: false
    t.text "message", null: false
    t.string "name", null: false
    t.string "phone"
    t.integer "property_id"
    t.boolean "read", default: false
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["form_type"], name: "index_information_requests_on_form_type"
    t.index ["property_id"], name: "index_information_requests_on_property_id"
    t.index ["read"], name: "index_information_requests_on_read"
  end

  create_table "outgoing_emails", force: :cascade do |t|
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.integer "pending_count", default: 0, null: false
    t.json "sent_emails", default: [], null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
  end

  create_table "properties", force: :cascade do |t|
    t.string "address"
    t.integer "building_id"
    t.string "city", null: false
    t.string "country", null: false
    t.datetime "created_at", null: false
    t.string "currency", default: "EUR"
    t.json "description"
    t.integer "district_id"
    t.boolean "exclusivity", default: false
    t.boolean "featured", default: false
    t.integer "floor"
    t.boolean "furnished", default: false
    t.decimal "garden_area", precision: 10, scale: 2
    t.boolean "has_360_tour", default: false
    t.integer "immotoolbox_id"
    t.json "intro"
    t.decimal "land_area", precision: 10, scale: 2
    t.decimal "latitude", precision: 10, scale: 7
    t.decimal "living_area", precision: 10, scale: 2
    t.decimal "longitude", precision: 10, scale: 7
    t.integer "num_bathrooms"
    t.integer "num_bedrooms"
    t.integer "num_cellars"
    t.integer "num_parkings"
    t.integer "num_rooms"
    t.boolean "off_market", default: false
    t.integer "price"
    t.string "property_type", null: false
    t.boolean "published", default: false
    t.string "reference", null: false
    t.integer "service_charges"
    t.boolean "service_charges_included", default: false
    t.boolean "shared_exclusivity", default: false
    t.string "subtype"
    t.datetime "synced_at"
    t.decimal "terrace_area", precision: 10, scale: 2
    t.json "title"
    t.decimal "total_area", precision: 10, scale: 2
    t.string "transaction_type", null: false
    t.string "translation_source_hash"
    t.json "translations_status", default: {}
    t.datetime "updated_at", null: false
    t.string "video_url"
    t.string "virtual_tour_url"
    t.index ["building_id"], name: "index_properties_on_building_id"
    t.index ["country"], name: "index_properties_on_country"
    t.index ["district_id"], name: "index_properties_on_district_id"
    t.index ["featured"], name: "index_properties_on_featured"
    t.index ["immotoolbox_id"], name: "index_properties_on_immotoolbox_id", unique: true
    t.index ["off_market"], name: "index_properties_on_off_market"
    t.index ["published"], name: "index_properties_on_published"
    t.index ["reference"], name: "index_properties_on_reference", unique: true
    t.index ["transaction_type"], name: "index_properties_on_transaction_type"
  end

  create_table "property_documents", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "label"
    t.integer "property_id", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_property_documents_on_property_id"
  end

  create_table "property_images", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "immotoolbox_id"
    t.boolean "is_plan", default: false
    t.string "large_url"
    t.string "medium_url"
    t.integer "position", default: 0
    t.integer "property_id", null: false
    t.string "remote_url", null: false
    t.string "small_url"
    t.string "thumb_url"
    t.datetime "updated_at", null: false
    t.index ["immotoolbox_id"], name: "index_property_images_on_immotoolbox_id", unique: true
    t.index ["property_id", "position"], name: "index_property_images_on_property_id_and_position"
    t.index ["property_id"], name: "index_property_images_on_property_id"
  end

  create_table "property_shares", force: :cascade do |t|
    t.boolean "attach_pdf", default: false, null: false
    t.text "body"
    t.datetime "created_at", null: false
    t.boolean "include_logo", default: true, null: false
    t.integer "pending_count", default: 0, null: false
    t.integer "property_id", null: false
    t.json "sent_contact_ids", default: [], null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["property_id"], name: "index_property_shares_on_property_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.integer "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "first_name"
    t.string "last_name"
    t.string "password_digest", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  create_table "youtube_videos", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.datetime "published_at", null: false
    t.string "thumbnail_url"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.string "video_id", null: false
    t.index ["video_id"], name: "index_youtube_videos_on_video_id", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "articles", "categories"
  add_foreign_key "buildings", "districts"
  add_foreign_key "information_requests", "properties"
  add_foreign_key "properties", "buildings"
  add_foreign_key "properties", "districts"
  add_foreign_key "property_documents", "properties"
  add_foreign_key "property_images", "properties"
  add_foreign_key "property_shares", "properties"
  add_foreign_key "sessions", "users"
end
