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
      assert_select "a[href='/ventes/monaco']", text: /Ventes Monaco/
      assert_select "a[href='/locations/monaco']", text: /Location Monaco/
      assert_select "a[href='/ventes/france']", text: /France/
      assert_select "a[href='/articles']", text: /Articles/
    end
  end

  test "navbar includes main navigation links for English" do
    get "/en"
    assert_select "nav" do
      assert_select "a[href='/en/sales/monaco']", text: /Sales Monaco/
      assert_select "a[href='/en/rentals/monaco']", text: /Rentals Monaco/
      assert_select "a[href='/en/sales/france']", text: /France/
      assert_select "a[href='/en/articles']", text: /Articles/
    end
  end

  test "navbar includes main navigation links for German" do
    get "/de"
    assert_select "nav" do
      assert_select "a[href='/de/verkauf/monaco']", text: /Verkauf Monaco/
      assert_select "a[href='/de/vermietung/monaco']", text: /Vermietung Monaco/
      assert_select "a[href='/de/verkauf/frankreich']", text: /Frankreich/
      assert_select "a[href='/de/artikel']", text: /Artikel/
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

  test "footer includes agency address" do
    get "/"
    assert_select "footer" do
      assert_match "3, Rue Langlé", response.body
      assert_match "MC 98000 Monaco", response.body
    end
  end

  test "footer includes phone and fax" do
    get "/"
    assert_select "footer" do
      assert_match "(+377) 93 30 22 36", response.body
      assert_match "(+377) 93 25 05 34", response.body
    end
  end

  test "footer includes email link" do
    get "/"
    assert_select "footer a[href='mailto:info@agencegaremonaco.com']"
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

  test "footer includes copyright" do
    get "/"
    assert_select "footer" do
      assert_match "Agence de la Gare", response.body
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
      assert_select "a[href='/it/vendite/francia']"
      assert_select "a[href='/it/articoli']"
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
