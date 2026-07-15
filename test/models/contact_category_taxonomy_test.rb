require "test_helper"

# The category taxonomy fans out across the model enum, the admin filter
# tabs, the recipient picker audiences, and several i18n key families. These
# tests make adding a category a loud, guided change instead of a silently
# partial one (a new category missing from a map would otherwise just vanish
# from the tabs or pickers with no error).
class ContactCategoryTaxonomyTest < ActiveSupport::TestCase
  test "admin filter tabs cover every category exactly once" do
    assert_equal Contact::CATEGORIES.sort, Admin::ContactsController::FILTERS.values.sort
  end

  test "recipient picker audiences cover every category exactly once" do
    assert_equal Contact::CATEGORIES.sort, RecipientLoading::AUDIENCES.values.flatten.sort
  end

  test "every category has a badge color variant" do
    assert_equal Contact::CATEGORIES.sort,
                 AdminHelper::CONTACT_CATEGORY_BADGE_VARIANTS.keys.sort
  end

  test "every category has its badge and form labels" do
    I18n.with_locale(:fr) do
      Contact::CATEGORIES.each do |category|
        assert I18n.exists?("admin.contacts.badges.#{category}"),
               "missing badge label for #{category}"
        assert I18n.exists?("admin.contacts.form.categories.#{category}"),
               "missing form label for #{category}"
      end
    end
  end

  test "every filter tab and picker section has its label" do
    I18n.with_locale(:fr) do
      Admin::ContactsController::FILTERS.each_key do |filter|
        assert I18n.exists?("admin.contacts.filters.#{filter}"),
               "missing filter tab label for #{filter}"
      end
      RecipientLoading::AUDIENCES.each_key do |audience|
        assert I18n.exists?("admin.recipient_picker.sections.#{audience}"),
               "missing picker section heading for #{audience}"
        assert I18n.exists?("admin.recipient_picker.selected.#{audience}"),
               "missing picker selected label for #{audience}"
      end
    end
  end

  test "every category and action combination has a flash message" do
    I18n.with_locale(:fr) do
      %w[created updated deleted].each do |action|
        Contact::CATEGORIES.each do |category|
          key = category == "contact" ? action : "#{category}_#{action}"
          assert I18n.exists?("admin.contacts.flash.#{key}"),
                 "missing flash message for #{category} / #{action}"
        end
      end
    end
  end
end
