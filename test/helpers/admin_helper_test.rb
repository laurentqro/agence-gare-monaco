require "test_helper"

class AdminHelperTest < ActionView::TestCase
  test "admin_nav_active? matches the exact path" do
    assert admin_nav_active?("/admin/articles", "/admin/articles")
  end

  test "admin_nav_active? matches a sub-path by prefix" do
    assert admin_nav_active?("/admin/articles/5/edit", "/admin/articles")
  end

  test "admin_nav_active? does not match an unrelated path" do
    assert_not admin_nav_active?("/admin/contacts", "/admin/articles")
  end

  test "admin_nav_active? does not match a partial segment" do
    assert_not admin_nav_active?("/admin/articles-archive", "/admin/articles")
  end

  test "admin_nav_active? matches the dashboard root only exactly" do
    assert admin_nav_active?("/admin", "/admin", exact: true)
    assert_not admin_nav_active?("/admin/articles", "/admin", exact: true)
  end

  test "admin_locale_chip renders data attributes, tooltip and uppercased code" do
    chip = admin_locale_chip("en", :stale)
    assert_includes chip, 'data-locale-chip="en"'
    assert_includes chip, 'data-locale-status="stale"'
    assert_includes chip, ">EN<"
    assert_includes chip, I18n.t("admin.properties.translations.stale")
  end

  test "admin_locale_chip colors come from the shared badge palette" do
    assert_includes admin_locale_chip("de", :translated), AdminHelper::BADGE_VARIANTS[:green]
    assert_includes admin_locale_chip("de", :stale), AdminHelper::BADGE_VARIANTS[:amber]
    assert_includes admin_locale_chip("de", :missing), AdminHelper::BADGE_VARIANTS[:gray]
  end

  test "admin_translation_error_marker carries the exception class as tooltip" do
    marker = admin_translation_error_marker({ "class" => "RubyLLM::RateLimitError" })
    assert_includes marker, "data-translation-error"
    assert_includes marker, 'title="RubyLLM::RateLimitError"'
    assert_includes marker, AdminHelper::BADGE_VARIANTS[:red]
  end
end
