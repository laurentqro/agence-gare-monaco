require "test_helper"

class StagingGuardTest < ActionView::TestCase
  include SeoHelper

  # By default in test, SITE_HOST equals PRODUCTION_HOST (no SITE_HOST env var set)
  test "staging? returns false when SITE_HOST matches production" do
    assert_equal SeoHelper::PRODUCTION_HOST, SeoHelper::SITE_HOST
    assert_not staging?
  end

  test "noindex_meta_tag returns nil for production" do
    assert_nil noindex_meta_tag
  end

  test "PRODUCTION_HOST is agencegaremonaco.com" do
    assert_equal "https://agencegaremonaco.com", SeoHelper::PRODUCTION_HOST
  end

  test "SITE_HOST defaults to production host" do
    assert_equal "https://agencegaremonaco.com", SeoHelper::SITE_HOST
  end
end
