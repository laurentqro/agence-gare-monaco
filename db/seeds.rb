# Categories
[
  { name: "Marché immobilier", slug: "marche-immobilier" },
  { name: "Guides pratiques", slug: "guides-pratiques" },
  { name: "Quartiers de Monaco", slug: "quartiers-de-monaco" },
  { name: "Projets & Nouveautés", slug: "projets-et-nouveautes" },
  { name: "Art de vivre à Monaco", slug: "art-de-vivre-a-monaco" },
  { name: "Décoration & Architecture", slug: "decoration-et-architecture" },
  { name: "Actualités", slug: "actualites" }
].each do |attrs|
  Category.find_or_create_by!(slug: attrs[:slug]) do |category|
    category.name = attrs[:name]
  end
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
