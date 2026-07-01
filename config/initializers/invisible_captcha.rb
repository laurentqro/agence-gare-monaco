# Spam protection for public forms (contact, property enquiry, estimate expert request).
#
# Three layers, all enabled:
#   - honeypot: a hidden field bots tend to fill (randomized field name per render)
#   - timestamp: rejects forms submitted faster than a human could plausibly type
#   - spinner: a session-bound token that ties the submission to a real form render,
#     so a bot that re-POSTs without fetching the form first is caught
#
# Detected spam is dropped silently (see InformationRequestsController) so bots
# receive a success-looking response and don't learn to adapt.
InvisibleCaptcha.setup do |config|
  # Minimum seconds between form render and submission. 4s is the gem default;
  # legitimate users filling name/email/message take far longer.
  config.timestamp_threshold = 4
end
