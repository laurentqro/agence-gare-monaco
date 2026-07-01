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
    assert_select "input[name='information_request[name]']"
    assert_select "input[name='information_request[email]']"
    assert_select "input[name='information_request[subject]']"
    assert_select "textarea[name='information_request[message]']"
    assert_select "input[type='submit']"
  end

  test "gestion page contact form posts to information_requests" do
    get "/gestion"
    assert_select "form[action^='/information_requests']"
  end

  test "gestion page contact form has legacy honeypot field" do
    get "/gestion"
    assert_select "input[name='website'][tabindex='-1']"
  end

  test "gestion page contact form has invisible_captcha honeypot and spinner" do
    get "/gestion"
    assert_select "input[name='information_request[subtitle]']"
    assert_select "input[name='spinner']"
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
    assert_select "input[name='information_request[name]']"
    assert_select "input[name='information_request[email]']"
    assert_select "input[name='information_request[subject]']"
    assert_select "textarea[name='information_request[message]']"
  end

  test "vendre page contact form has return_to hidden field" do
    get "/vendre"
    assert_select "input[type='hidden'][name='return_to'][value='vendre']"
  end

  # === Contact page still uses the form (extracted partial) ===

  test "contact page still renders contact form" do
    get "/contact"
    assert_response :success
    assert_select "input[name='information_request[name]']"
    assert_select "input[name='information_request[email]']"
    assert_select "textarea[name='information_request[message]']"
  end

  # === Form submission from gestion/vendre redirects back correctly ===

  test "successful submission from gestion redirects back to gestion" do
    assert_emails 1 do
      submit_information_request({
        information_request: { name: "Test", email: "test@example.com", message: "Hello" },
        return_to: "gestion",
        locale: "fr"
      }, from: "/gestion")
    end
    assert_redirected_to "/gestion"
    follow_redirect!
    assert_response :success
  end

  test "successful submission from vendre redirects back to vendre" do
    assert_emails 1 do
      submit_information_request({
        information_request: { name: "Test", email: "test@example.com", message: "Hello" },
        return_to: "vendre",
        locale: "fr"
      }, from: "/vendre")
    end
    assert_redirected_to "/vendre"
    follow_redirect!
    assert_response :success
  end

  test "successful submission without return_to redirects to contact page" do
    assert_emails 1 do
      submit_information_request({
        information_request: { name: "Test", email: "test@example.com", message: "Hello" },
        locale: "fr"
      }, from: "/contact")
    end
    assert_redirected_to "/contact"
  end

  test "failed submission from gestion re-renders gestion page with errors" do
    submit_information_request({
      information_request: { name: "", email: "", message: "" },
      return_to: "gestion",
      locale: "fr"
    }, from: "/gestion")
    assert_response :unprocessable_entity
    assert_select "[data-testid='gestion-content']"
    assert_select "[data-testid='inline-contact-form']"
  end

  test "failed submission from vendre re-renders vendre page with errors" do
    submit_information_request({
      information_request: { name: "", email: "", message: "" },
      return_to: "vendre",
      locale: "fr"
    }, from: "/vendre")
    assert_response :unprocessable_entity
    assert_select "[data-testid='vendre-content']"
    assert_select "[data-testid='inline-contact-form']"
  end

  # === Gestion page CTA section ===

  test "gestion page has CTA heading before contact form" do
    get "/gestion"
    assert_response :success
    assert_select "[data-testid='gestion-cta']"
    assert_select "[data-testid='gestion-cta'] h2"
    assert_select "[data-testid='gestion-cta'] p"
  end

  test "EN gestion page has translated CTA text" do
    get "/en/management"
    assert_response :success
    assert_select "[data-testid='gestion-cta'] h2", text: /management/i
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
