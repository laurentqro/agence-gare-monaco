# Categories
[
  {
    slug: "marche-immobilier",
    name: {
      "fr" => "Marché immobilier",
      "en" => "Real Estate Market",
      "it" => "Mercato immobiliare",
      "de" => "Immobilienmarkt",
      "sv" => "Fastighetsmarknad",
      "no" => "Eiendomsmarked",
      "da" => "Ejendomsmarked",
      "fi" => "Kiinteistömarkkina",
      "ru" => "Рынок недвижимости"
    }
  },
  {
    slug: "guides-pratiques",
    name: {
      "fr" => "Guides pratiques",
      "en" => "Practical Guides",
      "it" => "Guide pratiche",
      "de" => "Praktische Ratgeber",
      "sv" => "Praktiska guider",
      "no" => "Praktiske guider",
      "da" => "Praktiske guider",
      "fi" => "Käytännön oppaat",
      "ru" => "Практические руководства"
    }
  },
  {
    slug: "quartiers-de-monaco",
    name: {
      "fr" => "Quartiers de Monaco",
      "en" => "Monaco Districts",
      "it" => "Quartieri di Monaco",
      "de" => "Stadtviertel von Monaco",
      "sv" => "Monacos stadsdelar",
      "no" => "Monacos bydeler",
      "da" => "Monacos kvarterer",
      "fi" => "Monacon kaupunginosat",
      "ru" => "Районы Монако"
    }
  },
  {
    slug: "projets-et-nouveautes",
    name: {
      "fr" => "Projets & Nouveautés",
      "en" => "Projects & News",
      "it" => "Progetti & Novità",
      "de" => "Projekte & Neuigkeiten",
      "sv" => "Projekt & nyheter",
      "no" => "Prosjekter & nyheter",
      "da" => "Projekter & nyheder",
      "fi" => "Projektit & uutiset",
      "ru" => "Проекты и новости"
    }
  },
  {
    slug: "art-de-vivre-a-monaco",
    name: {
      "fr" => "Art de vivre à Monaco",
      "en" => "Living in Monaco",
      "it" => "Vivere a Monaco",
      "de" => "Leben in Monaco",
      "sv" => "Livet i Monaco",
      "no" => "Livet i Monaco",
      "da" => "Livet i Monaco",
      "fi" => "Elämä Monacossa",
      "ru" => "Жизнь в Монако"
    }
  },
  {
    slug: "decoration-et-architecture",
    name: {
      "fr" => "Décoration & Architecture",
      "en" => "Interior Design & Architecture",
      "it" => "Decorazione & Architettura",
      "de" => "Dekoration & Architektur",
      "sv" => "Inredning & arkitektur",
      "no" => "Interiør & arkitektur",
      "da" => "Indretning & arkitektur",
      "fi" => "Sisustus & arkkitehtuuri",
      "ru" => "Дизайн и архитектура"
    }
  },
  {
    slug: "actualites",
    name: {
      "fr" => "Actualités",
      "en" => "News",
      "it" => "Attualità",
      "de" => "Aktuelles",
      "sv" => "Nyheter",
      "no" => "Nyheter",
      "da" => "Nyheder",
      "fi" => "Ajankohtaista",
      "ru" => "Новости"
    }
  }
].each do |attrs|
  category = Category.find_or_initialize_by(slug: attrs[:slug])
  category.name = attrs[:name]
  category.save!
end

# Articles from markdown files
article_category_map = {
  "My Monaco" => "art-de-vivre-a-monaco",
  "Fiscalité" => "guides-pratiques",
  "Estimation" => "marche-immobilier",
  "Ventes" => "guides-pratiques",
  "Achat" => "guides-pratiques",
  "Gestion" => "guides-pratiques",
  "Sécurité & Santé" => "art-de-vivre-a-monaco",
  "Formalités" => "guides-pratiques",
  "Quartiers" => "quartiers-de-monaco",
  "Actualités" => "actualites"
}

Dir.glob(Rails.root.join("articles/*.md")).each do |file|
  content = File.read(file)

  # Parse header: title is the first # line, metadata between **Key:** value lines
  title = content.match(/^# (.+)$/)[1]
  date = content.match(/\*\*Date:\*\* (.+)$/)[1].strip
  category_label = content.match(/\*\*Catégorie:\*\* (.+)$/)[1].strip
  image_match = content.match(/\*\*Image:\*\* (.+)$/)
  image_url = image_match ? image_match[1].strip : nil

  # Body is everything after the --- separator
  body = content.split("---\n", 2).last.strip

  category_slug = article_category_map[category_label]
  category = Category.find_by!(slug: category_slug)

  slug = title.parameterize

  article = Article.find_or_create_by!(slug: slug) do |a|
    a.title = { "fr" => title }
    a.body = { "fr" => body }
    a.category = category
    a.published = true
    a.featured = false
    a.published_at = Date.parse(date)
    a.cover_image_url = image_url
  end

  # Update cover_image_url if not yet set (for idempotency on re-seed)
  if image_url.present? && article.cover_image_url.blank?
    article.update!(cover_image_url: image_url)
  end
end

# Apply article translations from runner scripts (idempotent)
Dir.glob(Rails.root.join("lib/tasks/translate_article_*.rb")).sort.each do |file|
  load file
end

# Off-market properties for sale
[
  {
    reference: "AG00016",
    title: { "fr" => "Magnifique duplex / penthouse rénové !" },
    description: { "fr" => "Idéalement situé à quelques minutes à pied de la place du Casino ainsi que du port Hercule, superbe appartement d'architecte luxueusement rénové et meublé !" },
    property_type: "Appartement",
    transaction_type: "sale",
    price: 9_950_000,
    num_rooms: 5,
    num_bedrooms: 4,
    num_bathrooms: 4,
    living_area: 223,
    terrace_area: 4,
    country: "monaco",
    city: "Monaco",
    off_market: true,
    published: true,
  },
  {
    reference: "AG00015",
    title: { "fr" => "Superbe appartement de maître avec vue exceptionnelle !" },
    description: { "fr" => " " },
    property_type: "Appartement",
    transaction_type: "sale",
    price: 22_000_000,
    num_rooms: 7,
    num_bedrooms: 4,
    num_bathrooms: 4,
    living_area: 278,
    terrace_area: 60,
    country: "monaco",
    city: "Monaco",
    off_market: true,
    published: true,
    image_urls: [ "https://www.agencegaremonaco.com/uploads/properties/15/VktDYfMir/VktDYfMir-1920-1200.jpg" ]
  },
  {
    reference: "AG00002",
    title: { "fr" => "Appartement Familial Quartier Condamine" },
    description: { "fr" => "En plein cœur du quartier de la contamine, magnifique appartement familiale aux prestations luxueuses et modernes !" },
    property_type: "Appartement",
    transaction_type: "sale",
    price: 15_000_000,
    num_rooms: 5,
    num_bedrooms: 3,
    num_bathrooms: 3,
    num_parkings: 2,
    num_cellars: 1,
    living_area: 200,
    terrace_area: 13,
    country: "monaco",
    city: "Monaco",
    off_market: true,
    published: true,
    image_urls: [ "https://www.agencegaremonaco.com/uploads/properties/2/7Q0DXBhuA/7Q0DXBhuA-1920-1200.jpg" ]
  }
].each do |attrs|
  image_urls = attrs.delete(:image_urls) || []
  property = Property.find_or_initialize_by(reference: attrs[:reference])
  property.assign_attributes(attrs)
  property.save!

  image_urls.each_with_index do |url, i|
    property.property_images.find_or_create_by!(remote_url: url) do |img|
      img.position = i + 1
      img.is_plan = false
    end
  end
end
