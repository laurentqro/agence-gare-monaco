import VideosCarouselController from "controllers/videos_carousel_controller"

export default class extends VideosCarouselController {
  static targets = ["track", "slide", "prevButton", "nextButton"]
}
