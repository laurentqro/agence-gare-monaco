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
end
