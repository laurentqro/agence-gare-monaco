class LlmsController < ApplicationController
  allow_unauthenticated_access

  def show
    respond_to do |format|
      format.text
    end
  end
end
