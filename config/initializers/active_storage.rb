Rails.application.config.after_initialize do
  ActiveStorage::DirectUploadsController.include Rails.application.routes.url_helpers
  ActiveStorage::DirectUploadsController.before_action do
    session_record = Session.find_by(id: cookies.signed[:session_id])
    unless session_record
      redirect_to new_session_url
    end
  end
end
