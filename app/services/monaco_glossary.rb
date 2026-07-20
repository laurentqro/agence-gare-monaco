module MonacoGlossary
  CORE = [ "Monaco", "Monte-Carlo" ].freeze

  DISTRICTS = [
    "La Condamine", "Fontvieille", "Larvotto", "Carré d'Or",
    "Jardin Exotique", "Moneghetti", "Saint-Roman", "Le Rocher",
    "La Rousse"
  ].freeze

  BUILDINGS = [
    "Le Métropole", "Le Columbia Palace", "L'Estoril", "Le Mirabeau",
    "Le Park Palace", "Le Roccabella", "Les Floralies", "Le Continental",
    "Villa Paloma"
  ].freeze

  ADDRESSES = [
    "Avenue de la Costa", "Avenue Princesse Grace", "Avenue de Monte-Carlo",
    "Boulevard du Larvotto", "Boulevard d'Italie", "Place du Casino",
    "Place Sainte-Dévote", "Port Hercule", "Port de Fontvieille"
  ].freeze

  ALL = (CORE + DISTRICTS + BUILDINGS + ADDRESSES).freeze

  # Non-Latin targets must transliterate place names rather than keep the French
  # spelling. These are the established Russian forms for the terms that appear
  # most often; anything not listed follows the general transliteration rule.
  CYRILLIC = {
    "Monaco" => "Монако",
    "Monte-Carlo" => "Монте-Карло",
    "La Condamine" => "Ла-Кондамин",
    "Fontvieille" => "Фонвьей",
    "Larvotto" => "Ларвотто",
    "Le Rocher" => "Ле-Роше"
  }.freeze
end
