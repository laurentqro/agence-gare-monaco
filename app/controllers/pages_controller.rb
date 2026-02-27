class PagesController < ApplicationController
  include Localizable
  allow_unauthenticated_access

  def home
  end
end
