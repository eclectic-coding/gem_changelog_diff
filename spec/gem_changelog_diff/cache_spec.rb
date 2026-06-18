# frozen_string_literal: true

require "tmpdir"

RSpec.describe GemChangelogDiff::Cache do
  subject(:cache) { described_class.new(cache_dir: cache_dir, ttl: 3600) }

  let(:cache_dir) { Dir.mktmpdir("gem_changelog_diff_cache") }
  let(:uri) { URI("https://api.github.com/repos/rails/rails/releases?page=1&per_page=100") }
  let(:headers) { { "Accept" => "application/json" } }
  let(:response_body) { '[{"tag_name":"v7.1.3"}]' }

  after { FileUtils.rm_rf(cache_dir) }

  describe "#get" do
    context "when cache miss" do
      it "fetches from network and stores the response" do
        stub_request(:get, uri.to_s).to_return(status: 200, body: response_body, headers: { "ETag" => '"abc123"' })

        response = cache.get(uri, headers: headers)

        expect(response.body).to eq(response_body)
        expect(Dir.glob("#{cache_dir}/*.json").size).to eq(1)
      end
    end

    context "when fresh cache hit" do
      it "returns cached response without network call" do
        stub_request(:get, uri.to_s).to_return(status: 200, body: response_body, headers: { "ETag" => '"abc123"' })

        cache.get(uri, headers: headers)
        WebMock.reset!

        response = cache.get(uri, headers: headers)

        expect(response.body).to eq(response_body)
        expect(WebMock).not_to have_requested(:get, uri.to_s)
      end
    end

    context "when stale cache hit with ETag" do
      it "revalidates with If-None-Match and returns cached on 304" do
        stale_cache = described_class.new(cache_dir: cache_dir, ttl: 0)
        stub_request(:get, uri.to_s).to_return(status: 200, body: response_body, headers: { "ETag" => '"abc123"' })
        stale_cache.get(uri, headers: headers)
        WebMock.reset!

        stub_request(:get, uri.to_s)
          .with(headers: { "If-None-Match" => '"abc123"' })
          .to_return(status: 304)

        response = stale_cache.get(uri, headers: headers)

        expect(response.body).to eq(response_body)
      end

      it "stores new response when server returns 200" do
        stale_cache = described_class.new(cache_dir: cache_dir, ttl: 0)
        stub_request(:get, uri.to_s).to_return(status: 200, body: response_body, headers: { "ETag" => '"abc123"' })
        stale_cache.get(uri, headers: headers)
        WebMock.reset!

        new_body = '[{"tag_name":"v7.2.0"}]'
        stub_request(:get, uri.to_s).to_return(status: 200, body: new_body, headers: { "ETag" => '"def456"' })

        response = stale_cache.get(uri, headers: headers)

        expect(response.body).to eq(new_body)
      end
    end

    context "when caching is disabled" do
      it "always fetches from network" do
        disabled_cache = described_class.new(cache_dir: cache_dir, enabled: false)
        stub_request(:get, uri.to_s).to_return(status: 200, body: response_body)

        disabled_cache.get(uri, headers: headers)

        expect(Dir.glob("#{cache_dir}/*.json")).to be_empty
      end
    end

    context "when cached file is corrupt" do
      it "treats as a cache miss" do
        key = Digest::SHA256.hexdigest(uri.to_s)
        FileUtils.mkdir_p(cache_dir)
        File.write(File.join(cache_dir, "#{key}.json"), "not json")

        stub_request(:get, uri.to_s).to_return(status: 200, body: response_body)

        response = cache.get(uri, headers: headers)

        expect(response.body).to eq(response_body)
      end
    end

    context "when response is not successful" do
      it "does not cache the response" do
        stub_request(:get, uri.to_s).to_return(status: 404, body: "Not Found")

        cache.get(uri, headers: headers)

        expect(Dir.glob("#{cache_dir}/*.json")).to be_empty
      end
    end
  end

  describe "#clear" do
    it "removes all cached files" do
      stub_request(:get, uri.to_s).to_return(status: 200, body: response_body)

      cache.get(uri, headers: headers)
      expect(Dir.glob("#{cache_dir}/*.json").size).to eq(1)

      cache.clear

      expect(Dir.exist?(cache_dir)).to be false
    end
  end

  describe GemChangelogDiff::CachedResponse do
    subject(:response) { described_class.new('{"key":"value"}', "200") }

    it "returns body" do
      expect(response.body).to eq('{"key":"value"}')
    end

    it "returns code" do
      expect(response.code).to eq("200")
    end

    it "reports as Net::HTTPSuccess for 2xx codes" do
      expect(response.is_a?(Net::HTTPSuccess)).to be true
    end

    it "does not report as Net::HTTPSuccess for non-2xx codes" do
      error_response = described_class.new("error", "404")

      expect(error_response.is_a?(Net::HTTPSuccess)).to be false
    end

    it "returns nil for header lookups" do
      expect(response["X-RateLimit-Remaining"]).to be_nil
    end
  end
end
