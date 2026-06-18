# frozen_string_literal: true

RSpec.describe GemChangelogDiff::ConcurrentFetcher do
  after { GemChangelogDiff.reset_configuration! }

  describe "#fetch_all" do
    it "returns results in order" do
      fetcher = described_class.new(concurrency: 4)
      items = %w[a b c d]

      results = fetcher.fetch_all(items) { |item| item.upcase }

      expect(results).to eq(%w[A B C D])
    end

    it "processes items with multiple workers" do
      fetcher = described_class.new(concurrency: 2)
      items = [1, 2, 3, 4]

      results = fetcher.fetch_all(items) { |item| item * 2 }

      expect(results).to eq([2, 4, 6, 8])
    end

    it "falls back to sequential when concurrency is 1" do
      fetcher = described_class.new(concurrency: 1)
      items = [1, 2, 3]

      results = fetcher.fetch_all(items) { |item| item * 10 }

      expect(results).to eq([10, 20, 30])
    end

    it "handles errors within threads" do
      fetcher = described_class.new(concurrency: 2)
      items = [1, 2]

      expect {
        fetcher.fetch_all(items) do |item|
          raise "boom" if item == 2
          item
        end
      }.to raise_error(RuntimeError, "boom")
    end

    it "limits thread count to item count" do
      fetcher = described_class.new(concurrency: 10)
      items = [1, 2]

      results = fetcher.fetch_all(items) { |item| item }

      expect(results).to eq([1, 2])
    end

    it "raises NetworkError when total timeout is exceeded" do
      GemChangelogDiff.configuration.total_timeout = 1
      fetcher = described_class.new(concurrency: 2)
      items = [1, 2]

      expect {
        fetcher.fetch_all(items) do |_item|
          sleep 2
        end
      }.to raise_error(GemChangelogDiff::NetworkError, /Total timeout/)
    end
  end
end
