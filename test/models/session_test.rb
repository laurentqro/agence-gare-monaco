require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "belongs to user" do
    assert Session.reflect_on_association(:user), "Expected Session to belong to :user"
  end
end
