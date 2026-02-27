ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # Ensure tests run with English locale by default for consistent error messages.
    # Tests that need a specific locale should set it explicitly.
    setup do
      I18n.locale = :en
    end

    teardown do
      I18n.locale = I18n.default_locale
    end
  end
end
