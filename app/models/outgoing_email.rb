class OutgoingEmail < ApplicationRecord
  MAX_ATTACHMENT_BYTES = 10.megabytes

  has_one_attached :file

  validates :subject, presence: true
  validates :body, presence: true
  validate :attachment_within_size_limit

  # Atomically records that one more recipient's send finished. When the last
  # send completes (post-decrement count reaches 0) it purges the attachment
  # and destroys the record. The conditional UPDATE means exactly one caller
  # can drive the count to 0, so exactly one caller purges — two jobs finishing
  # at the same instant can't both purge or both skip.
  def decrement_and_maybe_purge!
    rows = self.class.where(id: id).where("pending_count > 0")
                 .update_all("pending_count = pending_count - 1")
    return if rows.zero?

    if reload.pending_count <= 0
      file.purge if file.attached?
      destroy
    end
  rescue ActiveRecord::RecordNotFound
    # Another concurrent caller already destroyed it; nothing to do.
  end

  private

  def attachment_within_size_limit
    return unless file.attached?
    return if file.blob.byte_size <= MAX_ATTACHMENT_BYTES

    # Explicit message (not a bare :too_big symbol) because rails-i18n ships no
    # `too_big` default in FR, so the rendered error box would otherwise show a
    # missing-translation string.
    errors.add(:file, I18n.t("admin.outgoing_emails.errors.attachment_too_big"))
  end
end
