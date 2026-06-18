# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "net/http"

module GemChangelogDiff
  # Disk-based HTTP response cache with ETag revalidation.
  class Cache
    DEFAULT_DIR = File.join(Dir.home, ".cache", "gem_changelog_diff")
    DEFAULT_TTL = 86_400

    def initialize(cache_dir: DEFAULT_DIR, ttl: DEFAULT_TTL, enabled: true)
      @cache_dir = cache_dir
      @ttl = ttl
      @enabled = enabled
    end

    # Fetches a response, returning cached data when available.
    # @param uri [URI::Generic] the request URI
    # @param headers [Hash<String, String>] additional HTTP headers
    # @return [Net::HTTPResponse, CachedResponse]
    def get(uri, headers: {})
      return fetch_from_network(uri, headers) unless @enabled

      key = cache_key(uri)
      entry = read_entry(key)

      if entry && fresh?(entry)
        build_response(entry)
      elsif entry && entry["etag"]
        revalidate(uri, headers, entry, key)
      else
        fetch_and_store(uri, headers, key)
      end
    end

    # Deletes all cached data.
    # @return [void]
    def clear
      FileUtils.rm_rf(@cache_dir)
    end

    private

    def cache_key(uri)
      Digest::SHA256.hexdigest(uri.to_s)
    end

    def entry_path(key)
      File.join(@cache_dir, "#{key}.json")
    end

    def read_entry(key)
      path = entry_path(key)
      return nil unless File.exist?(path)

      JSON.parse(File.read(path))
    rescue JSON::ParserError
      nil
    end

    def write_entry(key, body:, code:, etag:)
      FileUtils.mkdir_p(@cache_dir)
      data = { "body" => body, "code" => code, "etag" => etag, "timestamp" => Time.now.to_i }
      File.write(entry_path(key), JSON.generate(data))
    end

    def fresh?(entry)
      Time.now.to_i - entry["timestamp"] < @ttl
    end

    def revalidate(uri, headers, entry, key)
      headers = headers.merge("If-None-Match" => entry["etag"])
      response = fetch_from_network(uri, headers)

      if response.code == "304"
        write_entry(key, body: entry["body"], code: entry["code"], etag: entry["etag"])
        build_response(entry)
      else
        store_response(key, response)
        response
      end
    end

    def fetch_and_store(uri, headers, key)
      response = fetch_from_network(uri, headers)
      store_response(key, response) if response.is_a?(Net::HTTPSuccess)
      response
    end

    def fetch_from_network(uri, headers)
      timeout = GemChangelogDiff.configuration.request_timeout
      request = Net::HTTP::Get.new(uri)
      headers.each { |k, v| request[k] = v }

      Net::HTTP.start(uri.hostname, uri.port,
                      use_ssl: uri.scheme == "https",
                      open_timeout: timeout, read_timeout: timeout) do |http|
        http.request(request)
      end
    end

    def store_response(key, response)
      write_entry(key, body: response.body, code: response.code, etag: response["ETag"])
    end

    def build_response(entry)
      CachedResponse.new(entry["body"], entry["code"])
    end
  end

  # Lightweight stand-in for Net::HTTPResponse built from cached data.
  class CachedResponse
    # @return [String] the response body
    # @return [String] the HTTP status code
    attr_reader :body, :code

    def initialize(body, code)
      @body = body
      @code = code
    end

    def is_a?(klass)
      return true if klass == Net::HTTPSuccess && @code.start_with?("2")

      super
    end

    def [](_header)
      nil
    end
  end
end
