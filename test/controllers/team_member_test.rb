require "test_helper"

class TeamMemberTest < ActionDispatch::IntegrationTest
  test "Pierre Maré page renders for French" do
    get "/equipe/pierre-mare"
    assert_response :success
    assert_select "h1", text: "Pierre Maré"
  end

  test "Adrien Maré page renders for French" do
    get "/equipe/adrien-mare"
    assert_response :success
    assert_select "h1", text: "Adrien Maré"
  end

  test "Josiane Alesi page renders for French" do
    get "/equipe/josiane-alesi"
    assert_response :success
    assert_select "h1", text: "Josiane Alesi"
  end

  test "team member pages render for English" do
    get "/en/team/pierre-mare"
    assert_response :success
    assert_select "h1", text: "Pierre Maré"
  end

  test "team member page displays role and bio" do
    get "/equipe/pierre-mare"
    assert_match I18n.t("homepage.team.pierre_role", locale: :fr), response.body
    assert_match "1942", response.body
  end

  test "team member page displays email contact" do
    get "/equipe/pierre-mare"
    assert_select "a[href='mailto:info@agencegaremonaco.com']"
  end

  test "unknown team member returns 404" do
    assert_raises(ActionController::RoutingError) do
      get "/equipe/unknown-person"
    end
  end

  test "team member pages render for all locales" do
    get "/equipe/pierre-mare"
    assert_response :success

    %w[en it de sv no da fi].each do |locale|
      get "/#{locale}/team/pierre-mare"
      assert_response :success, "Team member page failed for locale #{locale}"
    end
  end

  test "homepage links to team member pages" do
    get "/"
    assert_select "a[href='/equipe/pierre-mare']"
    assert_select "a[href='/equipe/adrien-mare']"
    assert_select "a[href='/equipe/josiane-alesi']"
  end
end
