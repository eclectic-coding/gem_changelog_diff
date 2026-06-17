# frozen_string_literal: true

RSpec.describe GemChangelogDiff::RubygemsClient do
  subject(:client) { described_class.new }

  describe "#repo_url" do
    context "when source_code_uri contains a GitHub URL" do
      it "returns owner/repo" do
        stub_request(:get, "https://rubygems.org/api/v1/gems/rails.json")
          .to_return(status: 200, body: {
            "source_code_uri" => "https://github.com/rails/rails",
            "homepage_uri" => "https://rubyonrails.org"
          }.to_json)

        expect(client.repo_url("rails")).to eq("rails/rails")
      end
    end

    context "when source_code_uri has a path suffix" do
      it "strips the path after owner/repo" do
        stub_request(:get, "https://rubygems.org/api/v1/gems/nokogiri.json")
          .to_return(status: 200, body: {
            "source_code_uri" => "https://github.com/sparklemotion/nokogiri/tree/v1.16.0"
          }.to_json)

        expect(client.repo_url("nokogiri")).to eq("sparklemotion/nokogiri")
      end
    end

    context "when source_code_uri has a .git suffix" do
      it "strips the .git suffix" do
        stub_request(:get, "https://rubygems.org/api/v1/gems/example.json")
          .to_return(status: 200, body: {
            "source_code_uri" => "https://github.com/owner/repo.git"
          }.to_json)

        expect(client.repo_url("example")).to eq("owner/repo")
      end
    end

    context "when only homepage_uri contains a GitHub URL" do
      it "falls back to homepage_uri" do
        stub_request(:get, "https://rubygems.org/api/v1/gems/sidekiq.json")
          .to_return(status: 200, body: {
            "source_code_uri" => nil,
            "homepage_uri" => "https://github.com/sidekiq/sidekiq"
          }.to_json)

        expect(client.repo_url("sidekiq")).to eq("sidekiq/sidekiq")
      end
    end

    context "when only bug_tracker_uri contains a GitHub URL" do
      it "falls back to bug_tracker_uri" do
        stub_request(:get, "https://rubygems.org/api/v1/gems/example.json")
          .to_return(status: 200, body: {
            "source_code_uri" => nil,
            "homepage_uri" => "https://example.com",
            "bug_tracker_uri" => "https://github.com/owner/repo/issues"
          }.to_json)

        expect(client.repo_url("example")).to eq("owner/repo")
      end
    end

    context "when no GitHub URL is found" do
      it "returns nil" do
        stub_request(:get, "https://rubygems.org/api/v1/gems/example.json")
          .to_return(status: 200, body: {
            "source_code_uri" => nil,
            "homepage_uri" => "https://example.com"
          }.to_json)

        expect(client.repo_url("example")).to be_nil
      end
    end

    context "when the API returns 404" do
      it "returns nil" do
        stub_request(:get, "https://rubygems.org/api/v1/gems/nonexistent.json")
          .to_return(status: 404, body: "Not Found")

        expect(client.repo_url("nonexistent")).to be_nil
      end
    end

    context "when a network error occurs" do
      it "raises NetworkError" do
        stub_request(:get, "https://rubygems.org/api/v1/gems/rails.json")
          .to_raise(SocketError.new("getaddrinfo: Name or service not known"))

        expect { client.repo_url("rails") }
          .to raise_error(GemChangelogDiff::NetworkError, /Name or service not known/)
      end
    end
  end
end