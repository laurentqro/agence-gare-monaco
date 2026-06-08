require "test_helper"

class InformationRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @property = Property.create!(
      reference: "MC-FORM-001",
      title: { "fr" => "Studio Test", "en" => "Test Studio" },
      transaction_type: "sale",
      property_type: "apartment",
      country: "MC",
      city: "Monaco",
      price: 950_000,
      published: true
    )
  end

  # === Homepage contact form submission ===

  test "successful contact form submission creates record and sends email" do
    assert_difference "InformationRequest.count", 1 do
      assert_emails 1 do
        post information_requests_url, params: {
          information_request: {
            name: "Jean Dupont",
            email: "jean@example.com",
            subject: "General enquiry",
            message: "I would like more information."
          },
          locale: "en"
        }
      end
    end

    submission = InformationRequest.last
    assert_equal "contact", submission.form_type
    assert_equal "Jean Dupont", submission.name
    assert_equal "jean@example.com", submission.email
    assert_equal "General enquiry", submission.subject
    assert_equal "I would like more information.", submission.message
    assert_nil submission.property_id
    assert_equal false, submission.read

    assert_redirected_to "/en/contact"
    follow_redirect!
    assert_select "[data-testid='flash-notice']"
  end

  test "contact form submission with validation errors re-renders contact page" do
    assert_no_difference "InformationRequest.count" do
      post information_requests_url, params: {
        information_request: {
          name: "",
          email: "",
          message: ""
        },
        locale: "en"
      }
    end

    assert_response :unprocessable_entity
    assert_select "form[action^='/information_requests']"
  end

  test "contact form submission with honeypot filled is rejected silently" do
    assert_no_difference "InformationRequest.count" do
      assert_no_emails do
        post information_requests_url, params: {
          information_request: {
            name: "Bot User",
            email: "bot@spam.com",
            subject: "Buy now",
            message: "Click here to win"
          },
          website: "http://spam.example.com",
          locale: "en"
        }
      end
    end

    # Redirects as if successful (don't reveal to bot)
    assert_redirected_to "/en/contact"
  end

  # === Property enquiry form submission ===

  test "successful enquiry form submission creates record and sends email" do
    assert_difference "InformationRequest.count", 1 do
      assert_emails 1 do
        post information_requests_url, params: {
          information_request: {
            name: "Pierre Martin",
            email: "pierre@example.com",
            phone: "+33 6 12 34 56 78",
            country: "France",
            message: "I am interested in this property.",
            property_id: @property.id
          },
          locale: "en"
        }
      end
    end

    submission = InformationRequest.last
    assert_equal "enquiry", submission.form_type
    assert_equal "Pierre Martin", submission.name
    assert_equal "pierre@example.com", submission.email
    assert_equal "+33 6 12 34 56 78", submission.phone
    assert_equal "France", submission.country
    assert_equal @property.id, submission.property_id
  end

  test "enquiry form redirects back to property page on success" do
    post information_requests_url, params: {
      information_request: {
        name: "Pierre Martin",
        email: "pierre@example.com",
        message: "I am interested.",
        property_id: @property.id
      },
      locale: "en"
    }

    assert_redirected_to "/en/properties/#{@property.id}-test-studio"
    follow_redirect!
    assert_select "[data-testid='flash-notice']"
  end

  test "enquiry form with validation errors re-renders property page" do
    assert_no_difference "InformationRequest.count" do
      post information_requests_url, params: {
        information_request: {
          name: "",
          email: "",
          message: "",
          property_id: @property.id
        },
        locale: "en"
      }
    end

    assert_response :unprocessable_entity
  end

  test "enquiry form with honeypot filled is rejected silently" do
    assert_no_difference "InformationRequest.count" do
      assert_no_emails do
        post information_requests_url, params: {
          information_request: {
            name: "Bot User",
            email: "bot@spam.com",
            message: "Click here",
            property_id: @property.id
          },
          website: "http://spam.example.com",
          locale: "en"
        }
      end
    end

    assert_redirected_to "/en/properties/#{@property.id}-test-studio"
  end

  # === Contact page renders the form ===

  test "contact page renders contact form" do
    get "/en/contact"
    assert_response :success
    assert_select "[data-testid='contact-form'] form[action^='/information_requests']"
    assert_select "input[name='information_request[name]']"
    assert_select "input[name='information_request[email]']"
    assert_select "input[name='information_request[subject]']"
    assert_select "textarea[name='information_request[message]']"
  end

  test "contact page renders honeypot field" do
    get "/en/contact"
    assert_response :success
    assert_select "input[name='website']"
  end

  # === Contact page team section ===

  test "contact page displays team section with three members" do
    get "/en/contact"
    assert_response :success
    assert_select "[data-testid='contact-team-section']" do
      assert_select "[data-testid='contact-team-pierre']"
      assert_select "[data-testid='contact-team-adrien']"
      assert_select "[data-testid='contact-team-josiane']"
    end
  end

  test "contact page team section shows names and translated roles" do
    get "/en/contact"
    assert_response :success
    assert_select "[data-testid='contact-team-section']" do
      assert_match "Pierre Maré", response.body
      assert_match "Adrien Maré", response.body
      assert_match "Josiane Alesi", response.body
      assert_match I18n.t("homepage.team.pierre_role", locale: :en), response.body
      assert_match I18n.t("homepage.team.adrien_role", locale: :en), response.body
      assert_match I18n.t("homepage.team.josiane_role", locale: :en), response.body
    end
  end

  test "contact page team member email buttons link to mailto" do
    get "/en/contact"
    assert_response :success
    assert_select "[data-testid='contact-team-pierre'] a[href^='mailto:']"
    assert_select "[data-testid='contact-team-adrien'] a[href^='mailto:']"
    assert_select "[data-testid='contact-team-josiane'] a[href^='mailto:']"
  end

  # === Contact page info section ===

  test "contact page displays agency info" do
    get "/en/contact"
    assert_response :success
    assert_select "[data-testid='contact-info']" do
      assert_match "3, Rue Langlé", response.body
      assert_match "MC 98000", response.body
      assert_match "(+377) 93 30 22 36", response.body
      assert_match "(+377) 93 25 05 34", response.body
    end
  end

  test "contact page displays social media links" do
    get "/en/contact"
    assert_response :success
    assert_select "[data-testid='contact-social-links']" do
      assert_select "a[href*='linkedin.com']"
      assert_select "a[href*='facebook.com']"
      assert_select "a[href*='instagram.com']"
      assert_select "a[href*='youtube.com']"
    end
  end

  test "contact page displays email link" do
    get "/en/contact"
    assert_response :success
    assert_select "[data-testid='contact-info'] a[href='mailto:info@agencegaremonaco.com']"
  end

  # === Property page renders the enquiry form ===

  test "property page renders enquiry form" do
    get "/en/properties/#{@property.id}-test-studio"
    assert_response :success
    assert_select "[data-testid='enquiry-form'] form[action^='/information_requests']"
    assert_select "input[name='information_request[name]']"
    assert_select "input[name='information_request[email]']"
    assert_select "input[name='information_request[phone]']"
    assert_select "input[name='information_request[country]']"
    assert_select "textarea[name='information_request[message]']"
    assert_select "input[name='information_request[property_id]'][type='hidden'][value='#{@property.id}']"
  end

  test "property page enquiry form shows property reference" do
    get "/en/properties/#{@property.id}-test-studio"
    assert_response :success
    assert_select "[data-testid='enquiry-form']" do
      assert_select "span", text: /MC-FORM-001/
    end
  end

  test "property page renders honeypot field in enquiry form" do
    get "/en/properties/#{@property.id}-test-studio"
    assert_response :success
    assert_select "[data-testid='enquiry-form'] input[name='website']"
  end
end
