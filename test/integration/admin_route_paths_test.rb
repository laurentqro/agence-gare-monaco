require "test_helper"

class AdminRoutePathsTest < ActionDispatch::IntegrationTest
  test "compose email uses the French /admin/envoyer-email path" do
    assert_equal "/admin/envoyer-email", new_admin_outgoing_email_path
    assert_recognizes(
      { controller: "admin/outgoing_emails", action: "new" },
      { path: "/admin/envoyer-email", method: :get }
    )
  end

  test "sending an email posts to /admin/envoyer-email" do
    assert_equal "/admin/envoyer-email", admin_outgoing_emails_path
    assert_recognizes(
      { controller: "admin/outgoing_emails", action: "create" },
      { path: "/admin/envoyer-email", method: :post }
    )
  end

  test "information requests use the French /admin/demandes-information path" do
    assert_equal "/admin/demandes-information", admin_information_requests_path
    assert_recognizes(
      { controller: "admin/information_requests", action: "index" },
      { path: "/admin/demandes-information", method: :get }
    )
  end

  test "an information request member route keeps its French base path" do
    submission = InformationRequest.create!(form_type: "contact", name: "Test", email: "t@example.com", message: "hi")
    assert_equal "/admin/demandes-information/#{submission.id}", admin_information_request_path(submission)
  end

  test "the old English admin paths no longer resolve" do
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/admin/outgoing_emails/new", method: :get)
    end
    assert_raises(ActionController::RoutingError) do
      Rails.application.routes.recognize_path("/admin/information_requests", method: :get)
    end
  end
end
