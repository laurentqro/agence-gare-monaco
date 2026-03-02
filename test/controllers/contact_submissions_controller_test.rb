require "test_helper"

class ContactSubmissionsControllerTest < ActionDispatch::IntegrationTest
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
    assert_difference "ContactSubmission.count", 1 do
      assert_emails 1 do
        post contact_submissions_url, params: {
          contact_submission: {
            name: "Jean Dupont",
            email: "jean@example.com",
            subject: "General enquiry",
            message: "I would like more information."
          },
          locale: "en"
        }
      end
    end

    submission = ContactSubmission.last
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
    assert_no_difference "ContactSubmission.count" do
      post contact_submissions_url, params: {
        contact_submission: {
          name: "",
          email: "",
          message: ""
        },
        locale: "en"
      }
    end

    assert_response :unprocessable_entity
    assert_select "form[action^='/contact_submissions']"
  end

  test "contact form submission with honeypot filled is rejected silently" do
    assert_no_difference "ContactSubmission.count" do
      assert_no_emails do
        post contact_submissions_url, params: {
          contact_submission: {
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
    assert_difference "ContactSubmission.count", 1 do
      assert_emails 1 do
        post contact_submissions_url, params: {
          contact_submission: {
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

    submission = ContactSubmission.last
    assert_equal "enquiry", submission.form_type
    assert_equal "Pierre Martin", submission.name
    assert_equal "pierre@example.com", submission.email
    assert_equal "+33 6 12 34 56 78", submission.phone
    assert_equal "France", submission.country
    assert_equal @property.id, submission.property_id
  end

  test "enquiry form redirects back to property page on success" do
    post contact_submissions_url, params: {
      contact_submission: {
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
    assert_no_difference "ContactSubmission.count" do
      post contact_submissions_url, params: {
        contact_submission: {
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
    assert_no_difference "ContactSubmission.count" do
      assert_no_emails do
        post contact_submissions_url, params: {
          contact_submission: {
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
    assert_select "form[action^='/contact_submissions']"
    assert_select "input[name='contact_submission[name]']"
    assert_select "input[name='contact_submission[email]']"
    assert_select "input[name='contact_submission[subject]']"
    assert_select "textarea[name='contact_submission[message]']"
  end

  test "contact page renders honeypot field" do
    get "/en/contact"
    assert_response :success
    assert_select "input[name='website']"
  end

  # === Property page renders the enquiry form ===

  test "property page renders enquiry form" do
    get "/en/properties/#{@property.id}-test-studio"
    assert_response :success
    assert_select "[data-testid='enquiry-form'] form[action^='/contact_submissions']"
    assert_select "input[name='contact_submission[name]']"
    assert_select "input[name='contact_submission[email]']"
    assert_select "input[name='contact_submission[phone]']"
    assert_select "input[name='contact_submission[country]']"
    assert_select "textarea[name='contact_submission[message]']"
    assert_select "input[name='contact_submission[property_id]'][type='hidden'][value='#{@property.id}']"
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
