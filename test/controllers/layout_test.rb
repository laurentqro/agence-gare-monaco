require "test_helper"

class LayoutTest < ActionDispatch::IntegrationTest
  # === Application Layout ===

  test "layout includes Montserrat font from Google Fonts" do
    get "/"
    assert_response :success
    assert_match "fonts.googleapis.com", response.body
    assert_match "Montserrat", response.body
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
      assert_select "a[href='/ventes/monaco']", text: /Acheter/
      assert_select "a[href='/locations/monaco']", text: /Louer/
      assert_select "a[href='/contact']", text: /Off-market/
      assert_select "a[href='/contact']", text: /Vendre/
      assert_select "a[href='/contact']", text: /Gestion/
      assert_select "a[href='/articles']", text: /Articles/
      assert_select "a[href='/contact']", text: /Contact/
    end
  end

  test "navbar includes main navigation links for English" do
    get "/en"
    assert_select "nav" do
      assert_select "a[href='/en/sales/monaco']", text: /Buy/
      assert_select "a[href='/en/rentals/monaco']", text: /Rent/
      assert_select "a[href='/en/contact']", text: /Off-market/
      assert_select "a[href='/en/contact']", text: /Sell/
      assert_select "a[href='/en/contact']", text: /Management/
      assert_select "a[href='/en/articles']", text: /Articles/
      assert_select "a[href='/en/contact']", text: /Contact/
    end
  end

  test "navbar includes main navigation links for German" do
    get "/de"
    assert_select "nav" do
      assert_select "a[href='/de/verkauf/monaco']", text: /Kaufen/
      assert_select "a[href='/de/vermietung/monaco']", text: /Mieten/
      assert_select "a[href='/de/kontakt']", text: /Off-market/
      assert_select "a[href='/de/kontakt']", text: /Verkaufen/
      assert_select "a[href='/de/kontakt']", text: /Verwaltung/
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

  test "footer includes copyright and agency name" do
    get "/"
    assert_select "footer" do
      assert_match "Agence de la Gare", response.body
    end
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

  test "footer includes privacy link for current locale" do
    get "/"
    assert_select "footer a[href='/confidentialite']"

    get "/en"
    assert_select "footer a[href='/en/privacy']"
  end

  test "layout includes CIM badge" do
    get "/"
    assert_select "img[alt='Membre de la Chambre Immobilière Monégasque']"
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
      assert_select "a[href='/it/vendite/monaco']"
      assert_select "a[href='/it/affitti/monaco']"
      assert_select "a[href='/it/articoli']"
      assert_select "a[href='/it/contatto']"
    end
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
