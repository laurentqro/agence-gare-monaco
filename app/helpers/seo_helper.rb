module SeoHelper
  PRODUCTION_HOST = "https://agencegaremonaco.com".freeze
  SITE_HOST = (ENV["SITE_HOST"].presence || PRODUCTION_HOST).freeze

  HREFLANG_CODES = {
    fr: "fr", en: "en", it: "it", de: "de",
    sv: "sv", no: "nb", da: "da", fi: "fi", ru: "ru"
  }.freeze

  OG_LOCALE_CODES = {
    fr: "fr_FR", en: "en_GB", it: "it_IT", de: "de_DE",
    sv: "sv_SE", no: "nb_NO", da: "da_DK", fi: "fi_FI", ru: "ru_RU"
  }.freeze

  # --- Staging detection ---

  def staging?
    SITE_HOST != PRODUCTION_HOST
  end

  def noindex_meta_tag
    return nil unless staging?

    tag(:meta, name: "robots", content: "noindex, nofollow")
  end

  # --- Canonical URL ---

  def canonical_url(page_type:, **opts)
    locale = I18n.locale
    SITE_HOST + locale_path_for(page_type, locale, **opts)
  end

  # --- Hreflang tags ---

  def hreflang_tags(page_type:, **opts)
    tags = I18n.available_locales.map do |locale|
      code = HREFLANG_CODES[locale]
      href = SITE_HOST + locale_path_for(page_type, locale, **opts)
      tag(:link, rel: "alternate", hreflang: code, href: href)
    end

    # x-default points to French
    fr_href = SITE_HOST + locale_path_for(page_type, :fr, **opts)
    tags << tag(:link, rel: "alternate", hreflang: "x-default", href: fr_href)

    safe_join(tags, "\n")
  end

  # --- Meta description ---

  def seo_meta_description(page_type:, **opts)
    desc = case page_type
    when :homepage
      t("seo.homepage_description")
    when :property
      Nokogiri::HTML.fragment(opts[:property]&.description_for(I18n.locale).to_s).text
    when :article
      opts[:article]&.meta_description_for(I18n.locale).presence ||
        article_meta_excerpt(opts[:article], I18n.locale)
    when :listings
      seo_listings_description(opts)
    when :articles
      t("seo.articles_description")
    when :contact
      t("seo.contact_description")
    when :privacy
      t("seo.privacy_description")
    when :offmarket
      t("seo.offmarket_description")
    when :gestion
      t("seo.gestion_description")
    when :vendre
      t("seo.vendre_description")
    when :faq
      t("seo.faq_description")
    when :estimate
      t("seo.estimate_description")
    when :team_member
      member = opts[:member]
      t("homepage.team.#{member[:key]}_bio")
    end

    truncate(desc.to_s.gsub("\u00A0", " ").squish, length: 160, omission: "...")
  end

  # --- Page title ---

  def seo_title(page_type:, **opts)
    case page_type
    when :homepage
      t("seo.homepage_title")
    when :property
      property = opts[:property]
      title = property.title_for(I18n.locale)
      if property.formatted_price.present?
        "#{title} | #{property.formatted_price} \u20AC | Agence Immobilière de la Gare"
      else
        "#{title} | Agence Immobilière de la Gare"
      end
    when :article
      "#{opts[:article].title_for(I18n.locale)} | Agence Immobilière de la Gare"
    when :listings
      "#{seo_listings_title(opts)} | #{t('site_name')}"
    when :articles
      label = opts[:category] ? opts[:category].name_for(I18n.locale) : t("nav.articles")
      "#{label} | #{t('site_name')} Monaco"
    when :contact
      "#{t('nav.contact')} | #{t('site_name')}"
    when :privacy
      "#{t('nav.privacy')} | #{t('site_name')}"
    when :offmarket
      t("seo.offmarket_title")
    when :gestion
      t("seo.gestion_title")
    when :vendre
      "#{t('nav.sell')} | #{t('site_name')}"
    when :faq
      t("seo.faq_title")
    when :estimate
      t("seo.estimate_title")
    when :team_member
      member = opts[:member]
      "#{member[:name]} | #{t('site_name')}"
    end
  end

  # --- Open Graph tags ---

  def og_tags(page_type:, **opts)
    locale = I18n.locale
    og_locale = OG_LOCALE_CODES[locale]
    url = canonical_url(page_type: page_type, **opts)
    title = seo_title(page_type: page_type, **opts)
    description = seo_meta_description(page_type: page_type, **opts)

    og_type = page_type == :article ? "article" : "website"

    tags = []
    tags << tag(:meta, property: "og:type", content: og_type)
    tags << tag(:meta, property: "og:site_name", content: t("site_name"))
    tags << tag(:meta, property: "og:locale", content: og_locale)

    # Alternate locales
    I18n.available_locales.each do |alt_locale|
      next if alt_locale == locale
      tags << tag(:meta, property: "og:locale:alternate", content: OG_LOCALE_CODES[alt_locale])
    end

    tags << tag(:meta, property: "og:url", content: url)
    tags << tag(:meta, property: "og:title", content: title)
    tags << tag(:meta, property: "og:description", content: description)

    # Image
    image_url = og_image_for(page_type, opts)
    if image_url.present?
      tags << tag(:meta, property: "og:image", content: image_url)
      tags << tag(:meta, property: "og:image:width", content: "1200")
      tags << tag(:meta, property: "og:image:height", content: "630")
    end

    # Article-specific
    if page_type == :article && opts[:article]&.published_at
      tags << tag(:meta, property: "article:published_time", content: opts[:article].published_at.iso8601)
      tags << tag(:meta, property: "article:section", content: opts[:article].category.name_for) if opts[:article].category
    end

    safe_join(tags, "\n")
  end

  # --- Twitter Card tags ---

  def twitter_tags(page_type:, **opts)
    title = seo_title(page_type: page_type, **opts)
    description = seo_meta_description(page_type: page_type, **opts)
    image_url = og_image_for(page_type, opts)

    tags = []
    tags << tag(:meta, name: "twitter:card", content: "summary_large_image")
    tags << tag(:meta, name: "twitter:site", content: "@agencedelagare")
    tags << tag(:meta, name: "twitter:title", content: title)
    tags << tag(:meta, name: "twitter:description", content: description)
    tags << tag(:meta, name: "twitter:image", content: image_url) if image_url.present?

    safe_join(tags, "\n")
  end

  # --- JSON-LD Structured Data ---

  def json_ld_organization
    data = {
      "@context" => "https://schema.org",
      "@type" => "RealEstateAgent",
      "name" => "Agence Immobilière de la Gare",
      "url" => "https://agencegaremonaco.com",
      "logo" => "https://agencegaremonaco.com/images/logo.png",
      "image" => "https://agencegaremonaco.com/images/og-default.jpg",
      "telephone" => "+377 93 30 22 36",
      "fax" => "+377 93 25 05 34",
      "email" => "info@agencegaremonaco.com",
      "address" => {
        "@type" => "PostalAddress",
        "streetAddress" => "3, Rue Langlé",
        "addressLocality" => "Monaco",
        "postalCode" => "98000",
        "addressCountry" => "MC"
      },
      "sameAs" => [
        "https://www.linkedin.com/company/agence-de-la-gare-monaco",
        "https://www.facebook.com/agencedelagaremonaco",
        "https://www.instagram.com/agencedelagaremonaco",
        "https://www.youtube.com/channel/UC2w6AJOPj37wDZxXjWLRxtg"
      ],
      "foundingDate" => "1942",
      "openingHoursSpecification" => [
        {
          "@type" => "OpeningHoursSpecification",
          "dayOfWeek" => %w[Monday Tuesday Wednesday Thursday Friday],
          "opens" => "09:00",
          "closes" => "18:00"
        }
      ]
    }
    json_ld_script_tag(data)
  end

  def json_ld_property(property)
    locale = I18n.locale
    data = {
      "@context" => "https://schema.org",
      "@type" => "RealEstateListing",
      "name" => property.title_for(locale),
      "description" => property.description_for(locale),
      "url" => canonical_url(page_type: :property, property: property),
      "datePosted" => property.created_at&.iso8601,
      "image" => property.property_images.order(:position).map { |img| img.large_url || img.remote_url }
    }

    if property.price.present?
      data["offers"] = {
        "@type" => "Offer",
        "price" => property.price,
        "priceCurrency" => property.currency || "EUR"
      }
    end

    data["address"] = {
      "@type" => "PostalAddress",
      "addressLocality" => property.city,
      "addressCountry" => property.country
    }
    data["address"]["addressRegion"] = property.district.name if property.district.present?

    if property.latitude.present? && property.longitude.present?
      data["geo"] = {
        "@type" => "GeoCoordinates",
        "latitude" => property.latitude,
        "longitude" => property.longitude
      }
    end

    data["numberOfRooms"] = property.num_rooms if property.num_rooms.present? && property.num_rooms > 0
    data["numberOfBedrooms"] = property.num_bedrooms if property.num_bedrooms.present? && property.num_bedrooms > 0
    data["numberOfBathroomsTotal"] = property.num_bathrooms if property.num_bathrooms.present? && property.num_bathrooms > 0

    if property.living_area.present? && property.living_area > 0
      data["floorSize"] = {
        "@type" => "QuantitativeValue",
        "value" => property.living_area,
        "unitCode" => "MTK"
      }
    end

    json_ld_script_tag(data)
  end

  def json_ld_article(article)
    locale = I18n.locale
    data = {
      "@context" => "https://schema.org",
      "@type" => "Article",
      "headline" => article.title_for(locale),
      "description" => article.meta_description_for(locale).presence || article_meta_excerpt(article, locale, length: 200),
      "datePublished" => article.published_at&.iso8601,
      "dateModified" => article.updated_at&.iso8601,
      "author" => {
        "@type" => "Organization",
        "name" => "Agence Immobilière de la Gare"
      },
      "publisher" => {
        "@type" => "Organization",
        "name" => "Agence Immobilière de la Gare",
        "logo" => { "@type" => "ImageObject", "url" => "https://agencegaremonaco.com/images/logo.png" }
      },
      "inLanguage" => locale.to_s
    }
    data["articleSection"] = article.category.name_for if article.category
    json_ld_script_tag(data)
  end

  def json_ld_website
    data = {
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "Agence Immobilière de la Gare",
      "url" => "https://agencegaremonaco.com",
      "description" => "Independent real estate agency in Monaco since 1942. Property sales, rentals, and management.",
      "inLanguage" => %w[fr en it de sv nb da fi ru],
      "publisher" => {
        "@type" => "RealEstateAgent",
        "name" => "Agence Immobilière de la Gare"
      }
    }
    json_ld_script_tag(data)
  end

  def json_ld_faq(faqs)
    data = {
      "@context" => "https://schema.org",
      "@type" => "FAQPage",
      "mainEntity" => faqs.map do |faq|
        {
          "@type" => "Question",
          "name" => faq[:question],
          "acceptedAnswer" => {
            "@type" => "Answer",
            "text" => faq[:answer]
          }
        }
      end
    }
    json_ld_script_tag(data)
  end

  def json_ld_breadcrumbs(crumbs)
    data = {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => crumbs.each_with_index.map do |crumb, i|
        {
          "@type" => "ListItem",
          "position" => i + 1,
          "name" => crumb[:name],
          "item" => crumb[:url]
        }
      end
    }
    json_ld_script_tag(data)
  end

  def json_ld_videos(videos)
    data = {
      "@context" => "https://schema.org",
      "@type" => "ItemList",
      "itemListElement" => videos.each_with_index.map do |video, i|
        {
          "@type" => "ListItem",
          "position" => i + 1,
          "item" => {
            "@type" => "VideoObject",
            "name" => video.title,
            "description" => video.seo_description,
            "contentUrl" => "https://www.youtube.com/watch?v=#{video.video_id}",
            "embedUrl" => video.embed_url,
            "thumbnailUrl" => "https://img.youtube.com/vi/#{video.video_id}/maxresdefault.jpg",
            "uploadDate" => video.published_at&.iso8601,
            "publisher" => {
              "@type" => "Organization",
              "name" => "Agence Immobilière de la Gare"
            }
          }
        }
      end
    }
    json_ld_script_tag(data)
  end

  def listing_breadcrumbs(seo_opts)
    locale = I18n.locale
    home_path = locale.to_sym == :fr ? "/" : "/#{locale}"
    crumbs = [ { name: I18n.t("homepage.hero_title"), url: "#{SITE_HOST}#{home_path}" } ]

    transaction = seo_opts[:transaction_type]

    if transaction.present?
      label = seo_listings_title(transaction_type: transaction)
      url = SITE_HOST + listing_path_for(locale, transaction_type: transaction)
      crumbs << { name: label, url: url }
    end

    crumbs
  end

  private

  # Article bodies are markdown: render then extract text so syntax markers
  # never leak into meta tags. Headings are dropped — a description should
  # read as prose, not as a table of contents.
  def article_meta_excerpt(article, locale, length: 160)
    html = Commonmarker.to_html(article&.body_for(locale).to_s)
    fragment = Nokogiri::HTML.fragment(html)
    headingless = fragment.dup
    headingless.css("h1, h2, h3, h4, h5, h6").remove
    text = headingless.text.gsub("\u00A0", " ").squish
    text = fragment.text.gsub("\u00A0", " ").squish if text.blank?
    truncate_at_sentence(text, length)
  end

  def truncate_at_sentence(text, length)
    return text if text.length <= length

    head = text[0, length]
    boundary = head.rindex(/[.!?](?=\s|\z)/)
    return head[0..boundary] if boundary

    truncate(text, length: length, separator: " ", omission: "…")
  end

  def locale_path_for(page_type, locale, **opts)
    case page_type
    when :homepage
      locale.to_sym == :fr ? "/" : "/#{locale}"
    when :listings
      listing_path_for(locale, opts)
    when :property
      locale_property_path(opts[:property], locale)
    when :articles
      # With a category, this is a category filter page: its canonical and
      # alternates must carry each locale's own category slug.
      base = locale_articles_path(locale)
      opts[:category] ? "#{base}/#{opts[:category].slug_for(locale)}" : base
    when :article
      "#{locale_articles_path(locale)}/#{opts[:article].slug_for(locale)}"
    when :contact
      locale_contact_path(locale)
    when :privacy
      locale_privacy_path(locale)
    when :offmarket
      locale_offmarket_path(locale)
    when :gestion
      locale_gestion_path(locale)
    when :vendre
      locale_vendre_path(locale)
    when :faq
      locale_faq_path(locale)
    when :estimate
      locale_estimate_path(locale)
    when :team_member
      team_segment = I18n.t("routes.team", locale: locale)
      prefix = locale.to_sym == :fr ? "" : "/#{locale}"
      "#{prefix}/#{team_segment}/#{params[:member]}"
    end
  end

  def listing_path_for(locale, opts)
    transaction = opts[:transaction_type]
    transaction == "rental" ? locale_rentals_path(locale) : locale_sales_path(locale)
  end

  def seo_listings_title(opts)
    transaction = opts[:transaction_type]

    if transaction == "rental"
      I18n.t("listings.rentals")
    else
      I18n.t("listings.sales")
    end
  end

  def seo_listings_description(opts)
    transaction = opts[:transaction_type]

    if transaction == "rental"
      I18n.t("seo.listings_rentals_description", default: I18n.t("seo.listings_all_description"))
    else
      I18n.t("seo.listings_sales_description", default: I18n.t("seo.listings_all_description"))
    end
  end

  def og_image_for(page_type, opts)
    case page_type
    when :property
      img = opts[:property]&.cover_image
      img&.large_url || img&.remote_url
    when :homepage, :listings, :articles, :contact, :privacy, :offmarket, :gestion, :vendre, :faq, :estimate, :team_member
      "#{SITE_HOST}/images/og-default.jpg"
    when :article
      opts[:article]&.cover_image_display_url
    end
  end

  def json_ld_script_tag(data)
    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end
end
