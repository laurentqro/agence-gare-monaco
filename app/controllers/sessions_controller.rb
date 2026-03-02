class SessionsController < ApplicationController
  layout "admin"
  around_action :force_french_locale
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_session_url, alert: I18n.t("admin.sessions.rate_limited") }

  def new
  end

  def create
    if (user = User.authenticate_by(email_address: params[:email_address], password: params[:password]))
      start_new_session_for user
      redirect_to after_authentication_url
    else
      redirect_to new_session_url, alert: t("admin.sessions.invalid_credentials")
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_url
  end

  private

  def force_french_locale(&action)
    I18n.with_locale(:fr, &action)
  end
end
