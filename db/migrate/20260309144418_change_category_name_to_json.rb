class ChangeCategoryNameToJson < ActiveRecord::Migration[8.1]
  def up
    # Convert existing string values to JSON hashes
    Category.find_each do |category|
      old_name = category.read_attribute(:name)
      next if old_name.blank?
      # Skip if already a JSON hash (idempotent)
      next if old_name.start_with?("{")
      category.update_column(:name, { "fr" => old_name }.to_json)
    end

    change_column :categories, :name, :json, null: false
  end

  def down
    change_column :categories, :name, :string, null: false

    Category.find_each do |category|
      raw = category.read_attribute(:name)
      next unless raw.is_a?(Hash) || raw.is_a?(String)
      parsed = raw.is_a?(Hash) ? raw : JSON.parse(raw) rescue next
      category.update_column(:name, parsed["fr"] || parsed.values.first)
    end
  end
end
