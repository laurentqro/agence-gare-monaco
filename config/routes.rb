Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]

  namespace :admin do
    get "/", to: "dashboard#show", as: :root
  end

  # Public site with locale prefix
  scope "/:locale", constraints: { locale: /#{I18n.available_locales.join("|")}/ } do
    get "/", to: "pages#home", as: :localized_root
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Bare root redirects to default locale
  root to: redirect("/fr", status: 302)
end
