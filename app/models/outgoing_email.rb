class OutgoingEmail < ApplicationRecord
  MAX_ATTACHMENT_BYTES = 10.megabytes

  has_one_attached :file

  validates :subject, presence: true
  validates :body, presence: true
  validate :attachment_within_size_limit

  # Claims a recipient as delivered, exactly once. Returns true the first time a
  # given recipient is recorded and false on any replay (worker crash recovery,
  # operator retry), so the caller can send on true and skip on false. The first
  # successful claim also counts that recipient down and purges the record when
  # the last one completes. A row lock serializes the read-modify-write on the
  # JSON column, so two jobs finishing at the same instant cannot both claim the
  # same recipient, double-decrement, or double-purge.
  def mark_sent!(recipient_email)
    claimed = false
    with_lock do
      already = sent_emails.include?(recipient_email)
      next if already

      update!(
        sent_emails: sent_emails + [ recipient_email ],
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

  # Purges the attachment and destroys the record once every recipient has been
  # claimed. Guarded so only the final claimer (pending_count reached 0) tears it
  # down, and tolerant of a concurrent teardown that already removed the row.
  def purge_if_complete!
    return if pending_count.positive?

    with_lock do
      file.purge if file.attached?
      destroy
    end
  rescue ActiveRecord::RecordNotFound
    # Already destroyed by a concurrent final claimer.
  end

  def attachment_within_size_limit
    return unless file.attached?
    return if file.blob.byte_size <= MAX_ATTACHMENT_BYTES

    # Explicit message (not a bare :too_big symbol) because rails-i18n ships no
    # `too_big` default in FR, so the rendered error box would otherwise show a
    # missing-translation string. The limit is interpolated from the one constant
    # so the number lives in a single place.
    errors.add(:file, I18n.t("admin.outgoing_emails.errors.attachment_too_big", limit: max_attachment_mb))
  end

  def max_attachment_mb
    MAX_ATTACHMENT_BYTES / 1.megabyte
  end
end
