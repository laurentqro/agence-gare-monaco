require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  # === Application Layout ===

  test "layout includes Domine font from Google Fonts" do
    get "/"
    assert_response :success
    assert_match "fonts.googleapis.com", response.body
    assert_match "Domine", response.body
  end

  test "html tag has lang attribute matching current locale" do
    get "/"
    assert_match '<html lang="fr">', response.body

    get "/en"
    assert_match '<html lang="en">', response.body

    get "/de"
    assert_match '<html lang="de">', response.body
  end

  test "layout includes Turbo and Stimulus" do
    get "/"
    assert_response :success
    assert_select "head" do
      # importmap tags are present
      assert_match "importmap", response.body
    end
  end

  # === Navbar ===

  test "navbar includes agency logo linking to locale root" do
    get "/"
    assert_select "nav" do
      assert_select "a[href='/']" do
        assert_select "img[alt='Agence Immobilière de la Gare']"
      end
    end
  end

  test "navbar includes main navigation links for French" do
    get "/"
    assert_select "nav" do
      assert_select "a[href='/ventes']", text: /Acheter/
      assert_select "a[href='/locations']", text: /Louer/
      assert_select "a[href='/off-market']", text: /Off-market/
      assert_select "a[href='/vendre']", text: /Vendre/
      assert_select "a[href='/gestion']", text: /Gestion/
      assert_select "a[href='/articles']", text: /Articles/
      assert_select "a[href='/contact']", text: /contacter/i
    end
  end

  test "navbar includes main navigation links for English" do
    get "/en"
    assert_select "nav" do
      assert_select "a[href='/en/sales']", text: /Buy/
      assert_select "a[href='/en/rentals']", text: /Rent/
      assert_select "a[href='/en/off-market']", text: /Off-market/
      assert_select "a[href='/en/sell']", text: /Sell/
      assert_select "a[href='/en/management']", text: /Management/
      assert_select "a[href='/en/articles']", text: /Articles/
      assert_select "a[href='/en/contact']", text: /Contact/
    end
  end

  test "navbar includes main navigation links for German" do
    get "/de"
    assert_select "nav" do
      assert_select "a[href='/de/verkauf']", text: /Kaufen/
      assert_select "a[href='/de/vermietung']", text: /Mieten/
      assert_select "a[href='/de/off-market']", text: /Off-market/
      assert_select "a[href='/de/verkaufen']", text: /Verkaufen/
      assert_select "a[href='/de/verwaltung']", text: /Verwaltung/
      assert_select "a[href='/de/artikel']", text: /Artikel/
      assert_select "a[href='/de/kontakt']", text: /Kontakt/
    end
  end

  test "navbar includes language switcher with all 8 locales" do
    get "/"
    assert_select "[data-controller='language-switcher']" do
      assert_select "a[href='/']"
      %w[en it de sv no da fi].each do |locale|
        assert_select "a[href*='/#{locale}']"
      end
    end
  end

  test "language switcher highlights current locale" do
    get "/"
    assert_select "[data-controller='language-switcher']" do
      assert_select "[data-current-locale='fr']"
    end

    get "/en"
    assert_select "[data-controller='language-switcher']" do
      assert_select "[data-current-locale='en']"
    end
  end

  test "navbar includes WhatsApp link" do
    get "/"
    assert_select "nav a[href*='wa.me']" do |links|
      assert links.any? { |link| link["href"].include?("33662392065") }
    end
  end

  test "navbar includes WhatsApp link in mobile menu" do
    get "/"
    assert_select "[data-mobile-menu-target='menu'] a[href*='wa.me']" do |links|
      assert links.any? { |link| link["href"].include?("33662392065") }
    end
  end

  test "navbar includes mobile menu toggle button" do
    get "/"
    assert_select "[data-controller='mobile-menu']" do
      assert_select "button[data-action*='mobile-menu#toggle']"
    end
  end

  test "navbar renders on all locale homepages" do
    get "/"
    assert_response :success
    assert_select "nav", { minimum: 1 }, "Expected nav element for locale fr"

    %w[en it de sv no da fi].each do |locale|
      get "/#{locale}"
      assert_response :success, "Homepage failed for locale #{locale}"
      assert_select "nav", { minimum: 1 }, "Expected nav element for locale #{locale}"
    end
  end

  # === Footer ===

  # -- Brand column --

  test "footer includes agency logo linking to locale root" do
    get "/"
    assert_select "footer a[href='/']" do
      assert_select "img[alt='Agence Immobilière de la Gare']"
    end
  end

  test "footer includes tagline" do
    get "/"
    assert_select "footer", text: /partenaire immobilier/i
  end

  test "footer includes social media links" do
    get "/"
    assert_select "footer" do
      assert_select "a[href='https://www.linkedin.com/company/agence-de-la-gare-monaco']"
      assert_select "a[href='https://www.facebook.com/agencedelagaremonaco']"
      assert_select "a[href='https://www.instagram.com/agencedelagaremonaco']"
      assert_select "a[href='https://www.youtube.com/channel/UC2w6AJOPj37wDZxXjWLRxtg']"
    end
  end

  # -- Navigation column --

  test "footer includes navigation links for French" do
    get "/"
    assert_select "footer" do
      assert_select "a[href='/ventes']", text: /Acheter/
      assert_select "a[href='/locations']", text: /Louer/
      assert_select "a[href='/off-market']", text: /Off-market/
      assert_select "a[href='/vendre']", text: /Vendre/
      assert_select "a[href='/gestion']", text: /Gestion/
      assert_select "a[href='/articles']", text: /Articles/
      assert_select "a[href='/faq']", text: /FAQ/
    end
  end

  test "footer includes navigation links for English" do
    get "/en"
    assert_select "footer" do
      assert_select "a[href='/en/sales']", text: /Buy/
      assert_select "a[href='/en/rentals']", text: /Rent/
      assert_select "a[href='/en/off-market']", text: /Off-market/
      assert_select "a[href='/en/sell']", text: /Sell/
      assert_select "a[href='/en/management']", text: /Management/
      assert_select "a[href='/en/articles']", text: /Articles/
      assert_select "a[href='/en/faq']", text: /FAQ/
    end
  end

  test "footer includes gold contact button" do
    get "/"
    assert_select "footer a.bg-gold[href='/contact']", text: /Nous contacter/

    get "/en"
    assert_select "footer a.bg-gold[href='/en/contact']", text: /Contact/
  end

  # -- Contact column --

  test "footer contact column title is localised" do
    get "/"
    assert_select "footer h3", text: /Contact/

    get "/fi"
    assert_select "footer h3", text: /Yhteystiedot/
  end

  test "footer includes address" do
    get "/"
    assert_select "footer", text: /3, Rue Langl/
    assert_select "footer", text: /MC 98000 Monaco/
  end

  test "footer includes phone number" do
    get "/"
    assert_select "footer a[href='tel:+37793302236']", text: /93 30 22 36/
  end

  test "footer includes email" do
    get "/"
    assert_select "footer a[href='mailto:info@agencegaremonaco.com']", text: /info@agencegaremonaco\.com/
  end

  test "footer includes CIM badge" do
    get "/"
    assert_select "footer img[alt='Membre de la Chambre Immobilière Monégasque']"
  end

  # -- Bottom bar --

  test "footer includes copyright and agency name" do
    get "/"
    assert_select "footer", text: /Agence de la Gare/
  end

  test "footer includes privacy link for current locale" do
    get "/"
    assert_select "footer a[href='/confidentialite']"

    get "/en"
    assert_select "footer a[href='/en/privacy']"
  end

  test "footer renders on all locale homepages" do
    get "/"
    assert_response :success
    assert_select "footer", { minimum: 1 }, "Expected footer element for locale fr"

    %w[en it de sv no da fi].each do |locale|
      get "/#{locale}"
      assert_response :success, "Homepage failed for locale #{locale}"
      assert_select "footer", { minimum: 1 }, "Expected footer element for locale #{locale}"
    end
  end

  # === Helper Methods ===

  test "navigation links use translated route segments" do
    get "/it"
    assert_select "nav" do
      assert_select "a[href='/it/vendite']"
      assert_select "a[href='/it/affitti']"
      assert_select "a[href='/it/articoli']"
      assert_select "a[href='/it/contatto']"
    end
  end

  # === Active Nav Indicator ===

  test "buy nav link has active indicator on sales listing page" do
    get "/ventes"
    assert_select "nav a.nav-active[href='/ventes']"
  end

  test "rent nav link has active indicator on rentals listing page" do
    get "/locations"
    assert_select "nav a.nav-active[href='/locations']"
  end

  test "off-market nav link has active indicator on off-market page" do
    get "/off-market"
    assert_select "nav a.nav-active[href='/off-market']"
  end

  test "articles nav link has active indicator on articles page" do
    get "/articles"
    assert_select "nav a.nav-active[href='/articles']"
  end

  test "no nav link is active on homepage" do
    get "/"
    assert_select "nav a.nav-active", count: 0
  end

  test "active nav indicator works for English locale" do
    get "/en/sales"
    assert_select "nav a.nav-active[href='/en/sales']"
  end

  test "only one desktop nav link is active at a time" do
    get "/ventes"
    assert_select ".lg\\:flex a.nav-active", count: 1
  end

  test "layout does not include navbar on admin pages" do
    user = User.create!(email_address: "admin@test.com", password: "password123")
    post session_url, params: { email_address: "admin@test.com", password: "password123" }

    get admin_root_url
    assert_response :success
    # Admin should use its own layout, not the public navbar
    assert_select "nav[data-controller='mobile-menu']", count: 0
  end

  test "layout does not include navbar on login page" do
    get new_session_url
    assert_response :success
    assert_select "nav[data-controller='mobile-menu']", count: 0
  end
end
