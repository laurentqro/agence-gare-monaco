Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]

  namespace :admin do
    get "/", to: "dashboard#show", as: :root
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Temporary root until public site is built (Phase 2)
  root "sessions#new"
end
