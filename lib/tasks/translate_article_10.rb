# rails runner lib/tasks/translate_article_10.rb
article = Article.find_by!(slug: "nouveau-parking-sur-monaco")

article.title = article.title.merge(
  "en" => "New parking facility in Monaco",
  "it" => "Nuovo parcheggio a Monaco",
  "de" => "Neues Parkhaus in Monaco",
  "sv" => "Nytt parkeringsgarage i Monaco",
  "no" => "Nytt parkeringshus i Monaco",
  "da" => "Nyt parkeringshus i Monaco",
  "fi" => "Uusi pysäköintitalo Monacossa"
)

article.body = article.body.merge(
  "en" => <<~BODY,
    Here it is, a new parking facility at the port of Monaco
  BODY
  "it" => <<~BODY,
    Ci siamo, un nuovo parcheggio al porto di Monaco
  BODY
  "de" => <<~BODY,
    Es ist soweit, ein neues Parkhaus am Hafen von Monaco
  BODY
  "sv" => <<~BODY,
    Äntligen, ett nytt parkeringsgarage vid Monacos hamn
  BODY
  "no" => <<~BODY,
    Endelig, nytt parkeringshus ved havnen i Monaco
  BODY
  "da" => <<~BODY,
    Så er det her, nyt parkeringshus ved havnen i Monaco
  BODY
  "fi" => <<~BODY
    Vihdoinkin, uusi pysäköintitalo Monacon satamassa
  BODY
)

article.save!
puts "OK: #{article.slug} (#{article.title.keys.sort.join(', ')})"
