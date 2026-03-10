require "test_helper"

class ContactFormPartialTest < ActionDispatch::IntegrationTest
  # === Partial renders on gestion page ===

  test "gestion page renders contact form partial" do
    get "/gestion"
    assert_response :success
    assert_select "[data-testid='inline-contact-form']"
  end

  test "gestion page contact form has all fields" do
    get "/gestion"
    assert_response :success
    assert_select "input[name='contact_submission[name]']"
    assert_select "input[name='contact_submission[email]']"
    assert_select "input[name='contact_submission[subject]']"
    assert_select "textarea[name='contact_submission[message]']"
    assert_select "input[type='submit']"
  end

  test "gestion page contact form posts to contact_submissions" do
    get "/gestion"
    assert_select "form[action^='/contact_submissions']"
  end

  test "gestion page contact form has honeypot field" do
    get "/gestion"
    assert_select "input[name='website'][tabindex='-1']"
  end

  test "gestion page contact form has return_to hidden field" do
    get "/gestion"
    assert_select "input[type='hidden'][name='return_to'][value='gestion']"
  end

  # === Partial renders on vendre page ===

  test "vendre page renders contact form partial" do
    get "/vendre"
    assert_response :success
    assert_select "[data-testid='inline-contact-form']"
  end

  test "vendre page contact form has all fields" do
    get "/vendre"
    assert_response :success
    assert_select "input[name='contact_submission[name]']"
    assert_select "input[name='contact_submission[email]']"
    assert_select "input[name='contact_submission[subject]']"
    assert_select "textarea[name='contact_submission[message]']"
  end

  test "vendre page contact form has return_to hidden field" do
    get "/vendre"
    assert_select "input[type='hidden'][name='return_to'][value='vendre']"
  end

  # === Contact page still uses the form (extracted partial) ===

  test "contact page still renders contact form" do
    get "/contact"
    assert_response :success
    assert_select "input[name='contact_submission[name]']"
    assert_select "input[name='contact_submission[email]']"
    assert_select "textarea[name='contact_submission[message]']"
  end

  # === Form submission from gestion/vendre redirects back correctly ===

  test "successful submission from gestion redirects back to gestion" do
    assert_emails 1 do
      post contact_submissions_path, params: {
        contact_submission: { name: "Test", email: "test@example.com", message: "Hello" },
        return_to: "gestion",
        locale: "fr"
      }
    end
    assert_redirected_to "/gestion"
    follow_redirect!
    assert_response :success
  end

  test "successful submission from vendre redirects back to vendre" do
    assert_emails 1 do
      post contact_submissions_path, params: {
        contact_submission: { name: "Test", email: "test@example.com", message: "Hello" },
        return_to: "vendre",
        locale: "fr"
      }
    end
    assert_redirected_to "/vendre"
    follow_redirect!
    assert_response :success
  end

  test "successful submission without return_to redirects to contact page" do
    assert_emails 1 do
      post contact_submissions_path, params: {
        contact_submission: { name: "Test", email: "test@example.com", message: "Hello" },
        locale: "fr"
      }
    end
    assert_redirected_to "/contact"
  end

  test "failed submission from gestion re-renders gestion page with errors" do
    post contact_submissions_path, params: {
      contact_submission: { name: "", email: "", message: "" },
      return_to: "gestion",
      locale: "fr"
    }
    assert_response :unprocessable_entity
    assert_select "[data-testid='gestion-content']"
    assert_select "[data-testid='inline-contact-form']"
  end

  test "failed submission from vendre re-renders vendre page with errors" do
    post contact_submissions_path, params: {
      contact_submission: { name: "", email: "", message: "" },
      return_to: "vendre",
      locale: "fr"
    }
    assert_response :unprocessable_entity
    assert_select "[data-testid='vendre-content']"
    assert_select "[data-testid='inline-contact-form']"
  end

  # === Vendre page CTA section ===

  test "vendre page has CTA heading before contact form" do
    get "/vendre"
    assert_response :success
    assert_select "[data-testid='vendre-cta']"
    assert_select "[data-testid='vendre-cta'] h2"
    assert_select "[data-testid='vendre-cta'] p"
  end

  test "EN vendre page has translated CTA text" do
    get "/en/sell"
    assert_response :success
    assert_select "[data-testid='vendre-cta'] h2", text: /selling/i
  end

  # === Localized pages ===

  test "EN gestion page renders contact form" do
    get "/en/management"
    assert_response :success
    assert_select "[data-testid='inline-contact-form']"
  end

  test "EN vendre page renders contact form" do
    get "/en/sell"
    assert_response :success
    assert_select "[data-testid='inline-contact-form']"
  end
end
