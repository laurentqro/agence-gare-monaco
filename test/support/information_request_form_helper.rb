# Helpers for exercising the public information-request forms through
# invisible_captcha. The gem sets a timestamp + spinner token in the session
# when the form is rendered, and rejects POSTs that arrive too fast or without
# those tokens. To submit as a real human would, tests must:
#
#   1. GET a page that renders the form (seeds session timestamp + spinner)
#   2. wait past the timestamp threshold
#   3. POST, echoing the spinner token the form embedded
#
# `submit_information_request` does all three so individual tests stay focused
# on the behavior they assert rather than the captcha plumbing.
module InformationRequestFormHelper
  # GET the given path to render a form, then POST the information_request after
  # waiting past invisible_captcha's timestamp threshold. Returns nothing; the
  # POST response is available via the usual integration-test accessors.
  #
  # from:   path whose page renders an information-request form
  def submit_information_request(params, from:)
    get from
    spinner = captcha_spinner_from(response.body)
    travel(InvisibleCaptcha.timestamp_threshold.seconds + 1.second) do
      post information_requests_url, params: params.merge(spinner: spinner).compact
    end
  end

  # Extract the spinner token the rendered form embedded, so the POST looks like
  # it came from that exact form render.
  def captcha_spinner_from(html)
    html[/name="spinner"[^>]*value="([^"]*)"/, 1] ||
      html[/value="([^"]*)"[^>]*name="spinner"/, 1]
  end
end

class ActionDispatch::IntegrationTest
  include InformationRequestFormHelper
end
