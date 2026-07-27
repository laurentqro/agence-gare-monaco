class ApplicationController < ActionController::Base
  include Authentication

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :set_submission_for_footer

  private

  def set_submission_for_footer
    @submission ||= InformationRequest.new
  end
end
