module SeoConfigurable
  extend ActiveSupport::Concern

  included do
    helper_method :seo_config
    before_action :set_default_seo
  end

  private

  def seo_config
    @seo ||= {}
  end

  def set_default_seo
    @seo = { page_type: :homepage }
  end

  def set_seo(page_type:, **opts)
    @seo = opts.merge(page_type: page_type)
  end
end
