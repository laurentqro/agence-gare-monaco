module Admin
  class BaseController < ApplicationController
    layout "admin"
    around_action :force_french_locale

    private

    def force_french_locale(&action)
      I18n.with_locale(:fr, &action)
    end
  end
end
