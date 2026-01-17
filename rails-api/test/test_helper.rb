ENV["RAILS_ENV"] ||= "test"
ENV["SKIP_TEST_DATABASE_AUTO_LOAD"] = "1"  # Skip auto schema load

require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    # fixtures :all  # Commented out - fixtures may require tables

    # Add more helper methods to be used by all tests here...
  end
end
