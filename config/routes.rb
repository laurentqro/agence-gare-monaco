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

  # === Legacy URL Redirects (301) ===
  # French legacy routes
  scope "/fr", defaults: { locale: "fr" } do
    get "location/monaco", to: redirect("/fr/locations/monaco", status: 301)
    get "bien/:legacy_id",            to: "legacy_redirects#property"
    get "bien-off-market/:legacy_id", to: "legacy_redirects#off_market_property"
    get "pdf-download/:legacy_id",    to: "legacy_redirects#pdf_download", constraints: { legacy_id: /\d+\.pdf/ }
    get "pdf-download-nologo/:legacy_id", to: "legacy_redirects#pdf_download", constraints: { legacy_id: /\d+\.pdf/ }
    get "posts/:category_slug",       to: "legacy_redirects#posts_category"
    get "article/:id/:slug",          to: "legacy_redirects#article"
    get "post/:id/:slug",             to: "legacy_redirects#article"
    get "recherche/:location",        to: "legacy_redirects#search"
  end

  # English legacy routes
  scope "/en", defaults: { locale: "en" } do
    get "rental/monaco", to: redirect("/en/rentals/monaco", status: 301)
    get "property/:legacy_id",                to: "legacy_redirects#property"
    get "properties-off-market/:transaction", to: "legacy_redirects#off_market_listing"
    get "news",                               to: "legacy_redirects#news"
    get "article/:id/:slug",                  to: "legacy_redirects#article"
  end

  # Italian legacy routes
  scope "/it", defaults: { locale: "it" } do
    get "affitto/monaco", to: redirect("/it/affitti/monaco", status: 301)
    get "immobile/:legacy_id", to: "legacy_redirects#property"
  end

  # SEO: XML Sitemaps
  get "sitemap.xml", to: "sitemaps#index", as: :sitemap, defaults: { format: :xml }
  get "sitemaps/:locale.xml", to: "sitemaps#show", as: :sitemap_locale, defaults: { format: :xml }

  # SEO: Dynamic robots.txt
  get "robots.txt", to: "robots#show", as: :robots, defaults: { format: :text }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Bare root redirects to default locale
  root to: redirect("/fr", status: 302)
end
