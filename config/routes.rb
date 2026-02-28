Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]

  namespace :admin do
    get "/", to: "dashboard#show", as: :root
    resources :articles
    resources :categories
  end

  # Public site with translated route segments per locale
  I18n.available_locales.each do |locale|
    # Fetch translated route segments for this locale
    sales    = I18n.t("routes.sales", locale: locale)
    rentals  = I18n.t("routes.rentals", locale: locale)
    props    = I18n.t("routes.properties", locale: locale)
    articles = I18n.t("routes.articles", locale: locale)
    contact  = I18n.t("routes.contact", locale: locale)
    privacy  = I18n.t("routes.privacy", locale: locale)
    france   = I18n.t("routes.france", locale: locale)

    scope "/#{locale}", defaults: { locale: locale.to_s } do
      # Homepage
      get "/", to: "pages#home", as: :"#{locale}_root"

      # Property listings: /{transaction}[/{country}[/{district}]]
      get "/#{sales}",                       to: "properties#index", defaults: { transaction_type: "sale" }, as: :"#{locale}_sales"
      get "/#{sales}/monaco",                to: "properties#index", defaults: { transaction_type: "sale", country: "MC" }, as: :"#{locale}_sales_monaco"
      get "/#{sales}/monaco/:district_slug", to: "properties#index", defaults: { transaction_type: "sale", country: "MC" }, as: :"#{locale}_sales_monaco_district"
      get "/#{sales}/#{france}",             to: "properties#index", defaults: { transaction_type: "sale", country: "FR" }, as: :"#{locale}_sales_france"

      get "/#{rentals}",                       to: "properties#index", defaults: { transaction_type: "rental" }, as: :"#{locale}_rentals"
      get "/#{rentals}/monaco",                to: "properties#index", defaults: { transaction_type: "rental", country: "MC" }, as: :"#{locale}_rentals_monaco"
      get "/#{rentals}/monaco/:district_slug", to: "properties#index", defaults: { transaction_type: "rental", country: "MC" }, as: :"#{locale}_rentals_monaco_district"

      # Property detail: /{properties}/{id}-{slug}
      get "/#{props}/:id", to: "properties#show", as: :"#{locale}_property"

      # Articles
      get "/#{articles}",      to: "articles#index", as: :"#{locale}_articles"
      get "/#{articles}/:slug", to: "articles#show", as: :"#{locale}_article"

      # Contact
      get "/#{contact}", to: "pages#contact", as: :"#{locale}_contact"

      # Privacy
      get "/#{privacy}", to: "pages#privacy", as: :"#{locale}_privacy"
    end
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Bare root redirects to default locale
  root to: redirect("/fr", status: 302)
end
