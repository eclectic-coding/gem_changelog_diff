# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
  config.default_cassette_options = {
    record: :once,
    match_requests_on: %i[method uri]
  }
  config.filter_sensitive_data("<GITHUB_TOKEN>") do
    ENV.fetch("GITHUB_TOKEN", "test_token")
  end
end
