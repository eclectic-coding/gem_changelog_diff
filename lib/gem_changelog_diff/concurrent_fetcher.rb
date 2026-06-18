# frozen_string_literal: true

module GemChangelogDiff
  class ConcurrentFetcher
    def initialize(concurrency: 4)
      @concurrency = concurrency
    end

    def fetch_all(items, &)
      return items.map(&) if @concurrency <= 1

      results = Array.new(items.size)
      queue = Queue.new
      items.each_with_index { |item, i| queue << [item, i] }

      threads = spawn_workers(queue, results, &)
      threads.each(&:join)
      results
    end

    private

    def spawn_workers(queue, results, &block)
      worker_count = [@concurrency, queue.size].min
      worker_count.times.map do
        Thread.new { process_queue(queue, results, &block) }
      end
    end

    def process_queue(queue, results, &block)
      while (item, index = queue.pop(true))
        results[index] = block.call(item)
      end
    rescue ThreadError
      # Queue is empty
    end
  end
end
