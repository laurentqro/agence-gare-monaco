class AddRepliedAtToInformationRequests < ActiveRecord::Migration[8.1]
  def change
    add_column :information_requests, :replied_at, :datetime
  end
end
