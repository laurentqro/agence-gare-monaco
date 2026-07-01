class RenameContactSubmissionsToInformationRequests < ActiveRecord::Migration[8.1]
  def change
    rename_table :contact_submissions, :information_requests
  end
end
