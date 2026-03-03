module Admin
  class ArticlePreviewsController < BaseController
    include MarkdownHelper

    def create
      @html = render_markdown(params[:body])
      respond_to do |format|
        format.turbo_stream
      end
    end
  end
end
