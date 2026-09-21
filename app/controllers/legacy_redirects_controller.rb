class LegacyRedirectsController < ApplicationController
  allow_unauthenticated_access

  # Old CMS category slugs → the new category slug that absorbed them.
  # The new site reorganised the blog into fewer categories; these legacy
  # /fr/posts/:category URLs must land on whichever new category took over.
  # An unmapped slug falls back to the articles index.
  LEGACY_CATEGORY_SLUGS = {
    "achat" => "guides-pratiques",
    "estimation" => "marche-immobilier",
    "fiscalite" => "guides-pratiques",
    "formalites" => "guides-pratiques",
    "gestion" => "guides-pratiques",
    "ventes" => "guides-pratiques",
    "quartiers" => "quartiers-de-monaco",
    "securite-sante" => "art-de-vivre-a-monaco",
    "my-monaco" => "art-de-vivre-a-monaco",
    "actualites" => "actualites"
  }.freeze

  # FR: /fr/bien/{immotoolbox_id} → /fr/biens/{id}-{slug}
  # EN: /en/property/{immotoolbox_id} → /en/properties/{id}-{slug}
  # IT: /it/immobile/{immotoolbox_id} → /it/immobili/{id}-{slug}
  def property
    locale = params[:locale]
    property = Property.published.find_by(immotoolbox_id: params[:legacy_id])
    if property
      props_segment = I18n.t("routes.properties", locale: locale)
      slug = property.slug_for(locale)
      redirect_to "/#{locale}/#{props_segment}/#{property.id}-#{slug}", status: :moved_permanently
    else
      head :gone
    end
  end

  # FR: /fr/bien-off-market/{immotoolbox_id} → /fr/biens/{id}-{slug} or 410
  def off_market_property
    locale = params[:locale]
    property = Property.published.find_by(immotoolbox_id: params[:legacy_id])
    if property
      props_segment = I18n.t("routes.properties", locale: locale)
      slug = property.slug_for(locale)
      redirect_to "/#{locale}/#{props_segment}/#{property.id}-#{slug}", status: :moved_permanently
    else
      head :gone
    end
  end

  # FR: /fr/pdf-download/{immotoolbox_id}.pdf → /fr/biens/{id}-{slug}
  # FR: /fr/pdf-download-nologo/{immotoolbox_id}.pdf → /fr/biens/{id}-{slug}
  def pdf_download
    locale = params[:locale]
    property = Property.published.find_by(immotoolbox_id: params[:legacy_id])
    if property
      props_segment = I18n.t("routes.properties", locale: locale)
      slug = property.slug_for(locale)
      redirect_to "/#{locale}/#{props_segment}/#{property.id}-#{slug}", status: :moved_permanently
    else
      head :gone
    end
  end

  # FR: /fr/article/{id}/{slug}/ or /fr/post/{id}/{slug} → /articles/{current-slug}
  # EN: /en/article/{id}/{slug} → /en/articles/{current-slug}
  #
  # The old numeric id is stable; the slug in the URL is the OLD slug and no
  # longer matches the article's current slug. Look the article up by its
  # legacy id and redirect to its current slug. 410 if no such article exists.
  #
  # FR is the prefix-less default locale, so its canonical URL carries no /fr.
  # Redirecting straight to /articles/{slug} avoids a 301->301 chain through the
  # /fr/*path wildcard in routes.rb.
  def article
    locale = params[:locale]
    article = Article.published.find_by(legacy_id: params[:id])
    if article
      prefix = locale == "fr" ? "" : "/#{locale}"
      articles_segment = I18n.t("routes.articles", locale: locale)
      redirect_to "#{prefix}/#{articles_segment}/#{article.slug_for(locale)}", status: :moved_permanently
    else
      head :gone
    end
  end

  # FR: /fr/posts/{old-category}/ → /fr/articles/{new-category-slug}
  # Unknown legacy categories fall back to the articles index.
  def posts_category
    locale = params[:locale]
    articles_segment = I18n.t("routes.articles", locale: locale)
    new_slug = LEGACY_CATEGORY_SLUGS[params[:category_slug]]
    target = new_slug ? "/#{locale}/#{articles_segment}/#{new_slug}" : "/#{locale}/#{articles_segment}"
    redirect_to target, status: :moved_permanently
  end

  # FR: /fr/recherche/{location} → /fr/ventes
  def search
    locale = params[:locale]
    sales_segment = I18n.t("routes.sales", locale: locale)
    redirect_to "/#{locale}/#{sales_segment}", status: :moved_permanently
  end

  # EN: /en/news → /en/articles
  def news
    locale = params[:locale]
    articles_segment = I18n.t("routes.articles", locale: locale)
    redirect_to "/#{locale}/#{articles_segment}", status: :moved_permanently
  end

  # FR: /fr/biens-off-market/(vente|location) → /off-market
  def off_market_listing_fr
    redirect_to "/off-market", status: :moved_permanently
  end

  # EN: /en/properties-off-market/sale → /en/sales
  # EN: /en/properties-off-market/rental → /en/rentals
  def off_market_listing
    locale = params[:locale]
    if params[:transaction] == "rental"
      rentals_segment = I18n.t("routes.rentals", locale: locale)
      redirect_to "/#{locale}/#{rentals_segment}", status: :moved_permanently
    else
      sales_segment = I18n.t("routes.sales", locale: locale)
      redirect_to "/#{locale}/#{sales_segment}", status: :moved_permanently
    end
  end
end
