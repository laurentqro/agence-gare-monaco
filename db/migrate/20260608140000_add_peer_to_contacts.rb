class AddPeerToContacts < ActiveRecord::Migration[8.1]
  # Adds a boolean `peer` flag to contacts (confrères vs ordinary contacts).
  #
  # An earlier, since-removed migration briefly introduced a `kind` string
  # column for the same purpose. This migration reconciles either starting
  # point: a schema that still has `kind` is converted in place, and a schema
  # that never saw it gets the column added fresh. legacy_id is unique only
  # within each peer / non-peer group, since the two carry separate ID spaces.
  def up
    add_column :contacts, :peer, :boolean, null: false, default: false unless column_exists?(:contacts, :peer)
    add_index :contacts, :peer unless index_exists?(:contacts, :peer)

    if column_exists?(:contacts, :kind)
      execute "UPDATE contacts SET peer = #{quoted_true} WHERE kind = 'peer'"
      remove_index :contacts, column: [ :kind, :legacy_id ] if index_exists?(:contacts, [ :kind, :legacy_id ])
      remove_index :contacts, :kind if index_exists?(:contacts, :kind)
      remove_column :contacts, :kind
    end

    remove_index :contacts, :legacy_id if index_exists?(:contacts, :legacy_id)
    add_index :contacts, [ :peer, :legacy_id ], unique: true unless index_exists?(:contacts, [ :peer, :legacy_id ])
  end

  def down
    remove_index :contacts, [ :peer, :legacy_id ] if index_exists?(:contacts, [ :peer, :legacy_id ])
    add_index :contacts, :legacy_id, unique: true unless index_exists?(:contacts, :legacy_id)
    remove_index :contacts, :peer if index_exists?(:contacts, :peer)
    remove_column :contacts, :peer
  end
end
