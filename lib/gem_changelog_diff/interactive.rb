# frozen_string_literal: true

require "tty-prompt"

module GemChangelogDiff
  class Interactive
    def initialize(gems:)
      @gems = gems
    end

    def select
      prompt = TTY::Prompt.new
      prompt.multi_select("Select gems to check:", per_page: 15) do |menu|
        @gems.each do |gem|
          menu.choice "#{gem.name} (#{gem.current_version} → #{gem.newest_version})", gem
        end
      end
    end
  end
end
