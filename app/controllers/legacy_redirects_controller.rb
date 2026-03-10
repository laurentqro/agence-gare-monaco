class LegacyRedirectsController < ApplicationController
  allow_unauthenticated_access

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

  # FR: /fr/article/{id}/{slug}/ or /fr/post/{id}/{slug} → /fr/articles/{slug}
  # EN: /en/article/{id}/{slug} → /en/articles/{slug}
  def article
    locale = params[:locale]
    articles_segment = I18n.t("routes.articles", locale: locale)
    redirect_to "/#{locale}/#{articles_segment}/#{params[:slug]}", status: :moved_permanently
  end

  # FR: /fr/posts/{category}/ → /fr/articles/{category-slug}
  def posts_category
    locale = params[:locale]
    articles_segment = I18n.t("routes.articles", locale: locale)
    redirect_to "/#{locale}/#{articles_segment}/#{params[:category_slug]}", status: :moved_permanently
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
