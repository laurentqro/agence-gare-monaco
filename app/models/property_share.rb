# One share of a property to a batch of contacts: the admin's send options
# (subject, optional personal note, PDF brochure flags) plus per-recipient
# delivery tracking. Short-lived, like OutgoingEmail: created when the emails
# are queued, counted down by mark_sent!, destroyed when the last recipient
# completes. The tracking is what makes SharePropertyEmailJob replays (worker
# crash recovery, operator retry) safe: a claimed recipient is never re-sent.
class PropertyShare < ApplicationRecord
  belongs_to :property

  validates :subject, presence: true
  # on: :create only — mark_sent! legitimately drives pending_count to zero.
  validate :must_have_recipients, on: :create

  # Claims a recipient as delivered, exactly once. Returns true the first time
  # a given contact is recorded and false on any replay, so the caller can send
  # on true and skip on false. The first successful claim also counts that
  # recipient down and purges the record when the last one completes. A row
  # lock serializes the read-modify-write on the JSON column, so two jobs
  # finishing at the same instant cannot both claim the same contact,
  # double-decrement, or double-purge. (Same contract as OutgoingEmail#mark_sent!.)
  def mark_sent!(contact_id)
    claimed = false
    with_lock do
      already = sent_contact_ids.include?(contact_id)
      next if already

      update!(
        sent_contact_ids: sent_contact_ids + [ contact_id ],
        pending_count: [ pending_count - 1, 0 ].max
      )
      claimed = true
    end

    purge_if_complete!
    claimed
  rescue ActiveRecord::RecordNotFound
    # Another concurrent caller already completed and destroyed it; nothing to do.
    false
  end

  private

  def purge_if_complete!
    return if pending_count.positive?

    with_lock { destroy }
  rescue ActiveRecord::RecordNotFound
    # Already destroyed by a concurrent final claimer.
  end

  def must_have_recipients
    return if pending_count.positive?

    errors.add(:base, I18n.t("admin.property_shares.errors.no_recipients"))
  end
end
