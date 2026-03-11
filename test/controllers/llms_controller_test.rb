require "test_helper"

class LlmsControllerTest < ActionDispatch::IntegrationTest
  test "llms.txt returns text/plain" do
    get "/llms.txt"
    assert_response :success
    assert_equal "text/plain; charset=utf-8", response.content_type
  end

  test "llms.txt includes agency name" do
    get "/llms.txt"
    assert_includes response.body, "Agence Immobilière de la Gare"
  end

  test "llms.txt includes founding year" do
    get "/llms.txt"
    assert_includes response.body, "1942"
  end

  test "llms.txt includes services" do
    get "/llms.txt"
    assert_includes response.body, "Monaco"
  end

  test "llms.txt includes leadership" do
    get "/llms.txt"
    assert_includes response.body, "Pierre Maré"
    assert_includes response.body, "Adrien Maré"
  end

  test "llms.txt includes contact information" do
    get "/llms.txt"
    assert_includes response.body, "+377 93 30 22 36"
    assert_includes response.body, "info@agencegaremonaco.com"
  end

  test "llms.txt includes website URL" do
    get "/llms.txt"
    assert_includes response.body, "agencegaremonaco.com"
  end
end
