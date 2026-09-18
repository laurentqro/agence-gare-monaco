class ReplyDraft
  def initialize(information_request)
    @information_request = information_request
  end

  def subject
    "Re: #{topic}"
  end

  def body
    "#{OutgoingEmail::SIGNATURE}\n\n#{quote}"
  end

  private

  attr_reader :information_request

  def topic
    property = information_request.property
    return "#{property.reference} — #{property.title_for(:fr)}" if property
    return information_request.subject if information_request.subject.present?

    I18n.t("admin.information_requests.reply.default_topic")
  end

  def quote
    intro = I18n.t("admin.information_requests.reply.quote_intro",
                   date: I18n.l(information_request.created_at, format: "%d/%m/%Y à %H:%M"),
                   name: information_request.name)
    quoted_lines = information_request.message.lines.map { |line| "> #{line.chomp}" }
    [ intro, *quoted_lines ].join("\n")
  end
end
