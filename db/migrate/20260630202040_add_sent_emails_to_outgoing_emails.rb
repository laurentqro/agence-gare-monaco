class AddSentEmailsToOutgoingEmails < ActiveRecord::Migration[8.1]
  def change
    # Recipients already delivered to, so a replayed send job (worker crash,
    # operator retry) can claim-or-skip its recipient and never double-send or
    # double-decrement.
    add_column :outgoing_emails, :sent_emails, :json, null: false, default: []
  end
end
