Rails.application.routes.draw do
  resource :session, only: %i[new create destroy], path: "admin", path_names: { new: "login" }

  namespace :admin do
    get "/", to: "dashboard#show", as: :root
    resources :articles
    resource :article_preview, only: [ :create ]
    resources :categories
    resources :contacts
    resources :outgoing_emails, only: %i[new create], path: "envoyer-email", path_names: { new: "" }
    resources :information_requests, only: %i[index show update destroy], path: "demandes-information"
    resources :properties, path: "biens" do
      resource :share, only: [ :new, :create ], controller: "property_shares" do
        # Live email preview: re-renders the share email with the typed note.
        post :preview
      end
      resource :brochure, only: [ :new, :create ], controller: "property_brochures"
    end
  end

  # Public site with translated route segments per locale
  # French (default locale) uses no locale prefix in the URL
  I18n.available_locales.each do |locale|
    # Fetch translated route segments for this locale
    sales    = I18n.t("routes.sales", locale: locale)
    rentals  = I18n.t("routes.rentals", locale: locale)
    props    = I18n.t("routes.properties", locale: locale)
    articles = I18n.t("routes.articles", locale: locale)
    contact  = I18n.t("routes.contact", locale: locale)
    privacy  = I18n.t("routes.privacy", locale: locale)
    france   = I18n.t("routes.france", locale: locale)
    offmarket = I18n.t("routes.offmarket", locale: locale)
    gestion  = I18n.t("routes.gestion", locale: locale)
    vendre   = I18n.t("routes.vendre", locale: locale)
    faq      = I18n.t("routes.faq", locale: locale)
    team     = I18n.t("routes.team", locale: locale)
    estimate = I18n.t("routes.estimate", locale: locale)

    prefix = locale == :fr ? "" : "/#{locale}"
    sales_target = "#{prefix}/#{sales}"
    rentals_target = "#{prefix}/#{rentals}"

    scope prefix, defaults: { locale: locale.to_s } do
      # Homepage
      get "/", to: "pages#home", as: :"#{locale}_root"

      # Property listings: single page per transaction type
      get "/#{sales}",   to: "properties#index", defaults: { transaction_type: "sale" },   as: :"#{locale}_sales"
      get "/#{rentals}", to: "properties#index", defaults: { transaction_type: "rental" }, as: :"#{locale}_rentals"

      # Legacy country/district routes → redirect to simplified listings
      get "/#{sales}/monaco",                to: redirect(sales_target, status: 301)
      get "/#{sales}/monaco/:district_slug", to: redirect(sales_target, status: 301)
      get "/#{sales}/#{france}",             to: redirect(sales_target, status: 301)
      get "/#{rentals}/monaco",              to: redirect(rentals_target, status: 301)
      get "/#{rentals}/monaco/:district_slug", to: redirect(rentals_target, status: 301)

      # Property detail: /{properties}/{id}-{slug}
      get "/#{props}/:id", to: "properties#show", as: :"#{locale}_property"
      get "/#{props}/:id/pdf", to: "properties#pdf", as: :"#{locale}_property_pdf"

      # Articles
      get "/#{articles}",      to: "articles#index", as: :"#{locale}_articles"
      get "/#{articles}/:slug", to: "articles#show", as: :"#{locale}_article"

      # Contact
      get "/#{contact}", to: "pages#contact", as: :"#{locale}_contact"

      # Privacy
      get "/#{privacy}", to: "pages#privacy", as: :"#{locale}_privacy"

      # Off-market
      get "/#{offmarket}", to: "properties#off_market", as: :"#{locale}_offmarket"

      # Gestion (property management)
      get "/#{gestion}", to: "pages#gestion", as: :"#{locale}_gestion"

      # Vendre (selling guide)
      get "/#{vendre}", to: "pages#vendre", as: :"#{locale}_vendre"

      # FAQ
      get "/#{faq}", to: "pages#faq", as: :"#{locale}_faq"

      # Team member pages
      get "/#{team}/:member", to: "pages#team_member", as: :"#{locale}_team_member"

      # Property valuation tool (IMSEE-based estimator) — single GET so result URLs are shareable
      get "/#{estimate}", to: "estimates#new", as: :"#{locale}_estimate"
    end
  end

  # === Legacy URL Redirects (301) ===
  # French legacy routes (must come before the /fr wildcard redirect below)
  scope "/fr", defaults: { locale: "fr" } do
    get "location/monaco", to: redirect("/locations", status: 301)
    get "location/monaco/*filters", to: redirect("/locations", status: 301)
    get "bien/:legacy_id",            to: "legacy_redirects#property"
    get "bien-off-market/:legacy_id", to: "legacy_redirects#off_market_property"
    get "biens-off-market/:transaction", to: "legacy_redirects#off_market_listing_fr"
    get "pdf-download/:legacy_id",    to: "legacy_redirects#pdf_download", constraints: { legacy_id: /\d+\.pdf/ }
    get "pdf-download-nologo/:legacy_id", to: "legacy_redirects#pdf_download", constraints: { legacy_id: /\d+\.pdf/ }
    get "posts/:category_slug",       to: "legacy_redirects#posts_category"
    get "article/:id/:slug",          to: "legacy_redirects#article"
    get "post/:id/:slug",             to: "legacy_redirects#article"
    get "recherche/:location",        to: "legacy_redirects#search"
  end

  # Redirect /fr and any remaining /fr/* to unprefixed equivalents (301)
  get "/fr", to: redirect("/", status: 301)
  get "/fr/*path", to: redirect("/%{path}", status: 301)

  # English legacy routes
  scope "/en", defaults: { locale: "en" } do
    get "rental/monaco", to: redirect("/en/rentals", status: 301)
    get "rental/monaco/*filters", to: redirect("/en/rentals", status: 301)
    get "property/:legacy_id",                to: "legacy_redirects#property"
    get "property-off-market/:legacy_id",     to: "legacy_redirects#off_market_property"
    get "properties-off-market/:transaction", to: "legacy_redirects#off_market_listing"
    get "news",                               to: "legacy_redirects#news"
    get "article/:id/:slug",                  to: "legacy_redirects#article"
    get "post/:id/:slug",                     to: "legacy_redirects#article"
  end

  # Italian legacy routes
  scope "/it", defaults: { locale: "it" } do
    get "affitto/monaco", to: redirect("/it/affitti", status: 301)
    get "immobile/:legacy_id", to: "legacy_redirects#property"
  end

  # Contact form submissions
  resources :information_requests, only: [ :create ]

  # SEO: XML Sitemaps
  get "sitemap.xml", to: "sitemaps#index", as: :sitemap, defaults: { format: :xml }
  get "sitemaps/:locale.xml", to: "sitemaps#show", as: :sitemap_locale, defaults: { format: :xml }

  # SEO: Dynamic robots.txt
  get "robots.txt", to: "robots#show", as: :robots, defaults: { format: :text }

  # GEO: LLM-readable site summary
  get "llms.txt", to: "llms#show", as: :llms, defaults: { format: :text }

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Error pages
  match "/404", to: "errors#not_found", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  # Bare root is the French homepage (defined above in the locale loop)
end
