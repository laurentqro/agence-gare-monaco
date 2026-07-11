# Non-persisted form object behind the admin property-share page: the
# admin-tunable send options (subject, optional personal note, PDF brochure
# flags). Nothing is stored; recipients fan out to SharePropertyEmailJob with
# these values as plain job args. Exists so the share form validates and
# renders errors like any model-backed form.
class PropertyShare
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :subject, :string
  attribute :body, :string
  attribute :attach_pdf, :boolean, default: false
  attribute :include_logo, :boolean, default: true

  validates :subject, presence: true
end
