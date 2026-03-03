require "test_helper"

class DirectUploadsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "admin@agencegaremonaco.com", password: "securepassword123")
  end

  test "authenticated admin can create direct upload" do
    post session_url, params: { email_address: "admin@agencegaremonaco.com", password: "securepassword123" }

    post rails_direct_uploads_url, params: {
      blob: {
        filename: "photo.jpg",
        byte_size: 1024,
        checksum: "abc123==",
        content_type: "image/jpeg"
      }
    }, as: :json

    assert_response :success
    json = JSON.parse(response.body)
    assert json["signed_id"].present?
    assert_equal "photo.jpg", json["filename"]
  end

  test "unauthenticated user cannot create direct upload" do
    post rails_direct_uploads_url, params: {
      blob: {
        filename: "photo.jpg",
        byte_size: 1024,
        checksum: "abc123==",
        content_type: "image/jpeg"
      }
    }, as: :json

    assert_redirected_to new_session_url
  end
end
